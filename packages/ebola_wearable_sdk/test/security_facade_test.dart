import 'package:test/test.dart';
import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';

class _AllowGateway implements EbolaLicenceGateway {
  @override Future<EbolaLicenceDecision> activate(EbolaDeviceBinding b) async => validate(b);
  @override Future<EbolaLicenceDecision> validate(EbolaDeviceBinding b) async =>
    const EbolaLicenceDecision(allowed:true, state:EbolaLicenceState.active);
  @override Future<void> deactivate(EbolaDeviceBinding b) async {}
  @override Future<EbolaLicenceDecision> replace({required String approvedCaseId,
    required EbolaDeviceBinding oldDevice, required EbolaDeviceBinding replacement}) async =>
    validate(replacement);
}

void main() {
  test('Disallow photo without consent, even with valid licence', () async {
    final mock = EbolaMockAdapter();
    final bus = EbolaEventBus();
    final facade = EbolaSdkFacade(
      registry:EbolaAdapterRegistry()..register(mock),
      licences:EbolaLicenseGate(_AllowGateway()), events:bus);
    final device = (await facade.discover(mock.adapterId)).first;
    await facade.sessionFor(mock).connect(device);
    await expectLater(facade.photo(device:device,
      binding:const EbolaDeviceBinding(deviceId:'DEMO-G2-0001', modelCode:'G2'),
      userApproved:false), throwsStateError);
    await facade.dispose();
  });
  test('Disallow mismatched model before photo capture', () async {
    final mock = EbolaMockAdapter();
    final bus = EbolaEventBus();
    final facade = EbolaSdkFacade(
      registry:EbolaAdapterRegistry()..register(mock),
      licences:EbolaLicenseGate(_AllowGateway()), events:bus);
    final device = (await facade.discover(mock.adapterId)).first;
    await facade.sessionFor(mock).connect(device);
    await expectLater(facade.photo(device:device,
      binding:const EbolaDeviceBinding(deviceId:'DEMO-G2-0001', modelCode:'G1'),
      userApproved:true), throwsStateError);
    await facade.dispose();
  });
  test('Mock device does not claim implemented photo/video features', () async {
    final mock = EbolaMockAdapter();
    final caps = await mock.getCapabilities();
    expect(caps.contains(EbolaCapability.photo), isFalse);
    expect(caps.contains(EbolaCapability.video), isFalse);
  });
}
