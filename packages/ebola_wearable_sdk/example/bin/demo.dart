import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';
// Run `dart run example/bin/demo.dart` after `dart pub get`.
Future<void> main() async {
  final registry=EbolaAdapterRegistry()..register(EbolaMockAdapter());
  final events=EbolaEventBus();
  final sdk=EbolaSdkFacade(registry:registry,
    licences:EbolaLicenseGate(_DenyAll()),events:events);
  final devices=await sdk.discover('ebola.mock.v1');
  for(final d in devices) { print('DEMO ONLY: ${d.model} / ${d.id}'); }
  await sdk.dispose();
}
class _DenyAll implements EbolaLicenceGateway {
  @override Future<EbolaLicenceDecision> activate(EbolaDeviceBinding b) async => validate(b);
  @override Future<EbolaLicenceDecision> validate(EbolaDeviceBinding b) async => const EbolaLicenceDecision(allowed:false,state:EbolaLicenceState.unassigned);
  @override Future<void> deactivate(EbolaDeviceBinding b) async {}
  @override Future<EbolaLicenceDecision> replace({required String approvedCaseId, required EbolaDeviceBinding oldDevice, required EbolaDeviceBinding replacement}) async => validate(replacement);
}
