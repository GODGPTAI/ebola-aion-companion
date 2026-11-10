import 'package:test/test.dart';
import 'package:ebola_wearable_sdk/ebola_wearable_sdk.dart';
void main() {
  test('Four models are registered and hardware is not falsely verified', () {
    expect(EbolaModelCatalog.profiles.length, 4);
    expect(EbolaModelCatalog.byModel(EbolaGlassModel.g1).candidateAdapterId, EbolaModelCatalog.eyevue);
    expect(EbolaModelCatalog.byModel(EbolaGlassModel.g4SportPro).candidateAdapterId, EbolaModelCatalog.daEcho);
    expect(EbolaModelCatalog.profiles.values.every((m) => !m.hardwareVerified), isTrue);
  });
  test('Candidate adapters fail closed', () async {
    final a=EbolaEyevueCandidateAdapter();
    expect(await a.scan(), isEmpty);
    await expectLater(a.takePhoto(), throwsA(isA<EbolaUnsupportedFeature>()));
  });
}
