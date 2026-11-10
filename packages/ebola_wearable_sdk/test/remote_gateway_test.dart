import 'package:test/test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';

void main() {
  test('Licence gateway refuses HTTP or embedded credentials', () {
    final client=MockClient((request) async => http.Response('{}',200));
    expect(() => EbolaRemoteLicenceGateway(endpointBase:Uri.parse('http://example.com/'),
      authenticatedToken:() async=>'token',httpClient:client),throwsArgumentError);
    expect(() => EbolaRemoteLicenceGateway(endpointBase:Uri.parse('https://user:pass@example.com/'),
      authenticatedToken:() async=>'token',httpClient:client),throwsArgumentError);
    client.close();
  });
  test('Licence API respects base path and sends authenticated JSON', () async {
    final client=MockClient((request) async {
      expect(request.url.path, '/relay/api/wearables/licence/validate');
      expect(request.headers['authorization'], 'Bearer TEST_TOKEN');
      expect(request.method, 'POST');
      return http.Response('{"allowed":true,"state":"active","licence_id":"L-1"}',200);
    });
    final gate=EbolaRemoteLicenceGateway(
      endpointBase:Uri.parse('https://example.com/relay/api'),
      authenticatedToken:() async=>'TEST_TOKEN',httpClient:client);
    final result=await gate.validate(const EbolaDeviceBinding(deviceId:'D1',modelCode:'G1'));
    expect(result.allowed,isTrue);
    expect(result.licenceId,'L-1');
    client.close();
  });
}
