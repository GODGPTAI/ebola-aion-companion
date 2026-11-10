import 'device_contract.dart';
import 'models.dart';

/// Unsupported until the exact hardware model and commercial SDK rights are verified.
/// Deliberately no reverse-engineered writes, OTA commands or speculative camera calls.
abstract class _CandidateAdapter implements EbolaWearableAdapter {
  @override Future<List<EbolaDevice>> scan() async => <EbolaDevice>[];
  Never _notReady() => throw EbolaUnsupportedFeature(
      'Hardware adapter is not enabled. Verify exact firmware, SDK rights and a physical test unit.');
  @override Future<void> connect(String deviceId) async => _notReady();
  @override Future<void> disconnect() async {}
  @override Future<Set<EbolaCapability>> getCapabilities() async => _notReady();
  @override Future<int?> batteryPercent() async => _notReady();
  @override Future<EbolaCapturedAsset> takePhoto() async => _notReady();
  @override Future<void> startVideo() async => _notReady();
  @override Future<EbolaCapturedAsset> stopVideoAndImport() async => _notReady();
  @override Stream<List<int>> microphonePcm({required bool userInitiated}) async* {
    if (!userInitiated) throw StateError('Recording requires explicit user initiation');
    _notReady();
  }
  @override Future<void> stopMicrophone() async {}
  @override Future<void> playAudio(Uint8ListOrPath audio) async => _notReady();
  @override Future<List<EbolaCapturedAsset>> importMedia() async => _notReady();
}
class EbolaEyevueCandidateAdapter extends _CandidateAdapter {
  @override String get adapterId => EbolaModelCatalog.eyevue;
}
class EbolaDaEchoCandidateAdapter extends _CandidateAdapter {
  @override String get adapterId => EbolaModelCatalog.daEcho;
}
