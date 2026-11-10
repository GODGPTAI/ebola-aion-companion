import 'dart:convert';
import 'package:http/http.dart' as http;
import '../licensing.dart';

/// HTTPS transport using user's existing authenticated bearer session.
/// This SDK never stores or embeds service keys. Endpoint is a *proposed* API
/// contract; use only after server implementation is live and audited.
class EbolaRemoteLicenceGateway implements EbolaLicenceGateway {
  final Uri endpointBase;
  final Future<String> Function() authenticatedToken;
  final http.Client httpClient;
  EbolaRemoteLicenceGateway({required this.endpointBase, required this.authenticatedToken, required this.httpClient}) {
    if (endpointBase.scheme != 'https' || endpointBase.userInfo.isNotEmpty ||
        endpointBase.hasQuery || endpointBase.hasFragment) {
      throw ArgumentError('A clean HTTPS endpoint without embedded credentials is required');
    }
  }
  Future<Map<String,dynamic>> _call(String operation, Map<String,Object?> body) async {
    final token = await authenticatedToken();
    if (token.isEmpty) throw StateError('Login required');
    final basePath = endpointBase.path.endsWith('/')
        ? endpointBase.path : '${endpointBase.path}/';
    final uri=endpointBase.replace(path:basePath).resolve('wearables/licence/$operation');
    if (uri.scheme!='https' || uri.host!=endpointBase.host ||
        uri.port!=endpointBase.port) throw StateError('Unexpected licence origin');
    final response=await httpClient.post(uri, headers:{
      'content-type':'application/json','authorization':'Bearer $token'
    },body:jsonEncode(body)).timeout(const Duration(seconds:15));
    if (response.statusCode!=200) throw StateError('Licence API unavailable (${response.statusCode})');
    final decoded=jsonDecode(response.body);
    if (decoded is! Map<String,dynamic>) throw const FormatException('Invalid licence JSON');
    return decoded;
  }
  EbolaLicenceDecision _decision(Map<String,dynamic> data) {
    final state=EbolaLicenceState.values.where((s)=>s.name==data['state']).firstOrNull
        ?? EbolaLicenceState.unassigned;
    return EbolaLicenceDecision(
      allowed:data['allowed']==true && state==EbolaLicenceState.active,
      state:state,
      licenceId:data['licence_id'] is String ? data['licence_id'] as String : null,
      reason:data['reason'] is String ? data['reason'] as String : null,
      validUntil:DateTime.tryParse(data['valid_until']?.toString() ?? ''),
    );
  }
  @override Future<EbolaLicenceDecision> activate(EbolaDeviceBinding binding) async =>
      _decision(await _call('activate',binding.toJson()));
  @override Future<EbolaLicenceDecision> validate(EbolaDeviceBinding binding) async =>
      _decision(await _call('validate',binding.toJson()));
  @override Future<void> deactivate(EbolaDeviceBinding binding) async {
    await _call('deactivate',binding.toJson());
  }
  @override Future<EbolaLicenceDecision> replace({required String approvedCaseId,required EbolaDeviceBinding oldDevice,required EbolaDeviceBinding replacement}) async =>
      _decision(await _call('replace',{'approved_case_id':approvedCaseId,'old_device':oldDevice.toJson(),'replacement':replacement.toJson()}));
}
