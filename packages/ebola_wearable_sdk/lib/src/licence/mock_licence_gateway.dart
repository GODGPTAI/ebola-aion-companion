import '../licensing.dart';
/// TEST-ONLY backend simulation. NOT secure hardware attestation; never deploy.
class EbolaTestOnlyLicenceGateway implements EbolaLicenceGateway {
  final Map<String, String> _licences = {};
  final Set<String> _retired = {};
  bool allowActivations;
  EbolaTestOnlyLicenceGateway({this.allowActivations=true});
  EbolaLicenceDecision _ok(String deviceId) => EbolaLicenceDecision(allowed:true,state:EbolaLicenceState.active,licenceId:'DEMO-$deviceId');
  EbolaLicenceDecision _deny(String why) => EbolaLicenceDecision(allowed:false,state:EbolaLicenceState.revoked,reason:why);
  @override Future<EbolaLicenceDecision> activate(EbolaDeviceBinding binding) async {
    if (!allowActivations || _retired.contains(binding.deviceId)) return _deny('Not eligible');
    if (_licences.containsKey(binding.deviceId)) return _ok(binding.deviceId);
    _licences[binding.deviceId] = binding.modelCode;
    return _ok(binding.deviceId);
  }
  @override Future<EbolaLicenceDecision> validate(EbolaDeviceBinding binding) async =>
     _licences[binding.deviceId]==binding.modelCode && !_retired.contains(binding.deviceId)
       ? _ok(binding.deviceId) : _deny('No active binding');
  @override Future<void> deactivate(EbolaDeviceBinding binding) async { _licences.remove(binding.deviceId);_retired.add(binding.deviceId); }
  @override Future<EbolaLicenceDecision> replace({required String approvedCaseId,required EbolaDeviceBinding oldDevice,required EbolaDeviceBinding replacement}) async {
    if (!approvedCaseId.startsWith('DEMO-APPROVED-')) return _deny('Demo case not approved');
    if (replacement.deviceId==oldDevice.deviceId) return _deny('Same physical device');
    if (!_licences.containsKey(oldDevice.deviceId) || _licences.containsKey(replacement.deviceId)) return _deny('Invalid binding');
    _licences.remove(oldDevice.deviceId);_retired.add(oldDevice.deviceId);
    _licences[replacement.deviceId]=replacement.modelCode;
    return _ok(replacement.deviceId);
  }
}
