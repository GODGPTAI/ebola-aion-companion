import 'package:test/test.dart';
import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';
class InactiveGateway implements EbolaLicenceGateway {
  @override Future<EbolaLicenceDecision> activate(EbolaDeviceBinding b) async => validate(b);
  @override Future<EbolaLicenceDecision> validate(EbolaDeviceBinding b) async => const EbolaLicenceDecision(allowed:false,state:EbolaLicenceState.unassigned);
  @override Future<void> deactivate(EbolaDeviceBinding b) async {}
  @override Future<EbolaLicenceDecision> replace({required String approvedCaseId, required EbolaDeviceBinding oldDevice, required EbolaDeviceBinding replacement}) async => validate(replacement);
}
void main() {
  test('Unlicensed device cannot take premium actions', () async {
    final gate=EbolaLicenseGate(InactiveGateway());
    final sdk=EbolaWearableSdk(registry:EbolaAdapterRegistry(),licenceGate:gate);
    await expectLater(sdk.capturePhoto(adapterId:'ebola.mock.v1',binding:const EbolaDeviceBinding(deviceId:'D1',modelCode:'G1')),throwsStateError);
  });
}
