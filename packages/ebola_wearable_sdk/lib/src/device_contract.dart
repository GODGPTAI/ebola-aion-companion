/// EBOLA-owned vendor-neutral device abstraction. No OEM branding is exposed.
enum EbolaCapability {
  battery, photo, video, microphone, audioOutput, mediaTransfer,
  livePreview, wakeEvent, wifiTransfer, gestures, firmwareInfo,
}

enum EbolaConnectionStatus { disconnected, connecting, connected, error }

class EbolaDevice {
  final String id;
  final String model;
  final String adapterId;
  final Set<EbolaCapability> capabilities;
  const EbolaDevice({required this.id, required this.model, required this.adapterId,
    required this.capabilities});
}

/// Metadata references only. Do not expose OEM local-media URLs as cloud links.
class EbolaCapturedAsset {
  final String localPath;
  final String mimeType;
  final String deviceId;
  final DateTime capturedAt;
  const EbolaCapturedAsset(this.localPath, this.mimeType, this.deviceId, this.capturedAt);
}

abstract class EbolaWearableAdapter {
  String get adapterId;
  Future<List<EbolaDevice>> scan();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<Set<EbolaCapability>> getCapabilities();
  Future<int?> batteryPercent();
  Future<EbolaCapturedAsset> takePhoto();
  Future<void> startVideo();
  Future<EbolaCapturedAsset> stopVideoAndImport();
  Stream<List<int>> microphonePcm({required bool userInitiated});
  Future<void> stopMicrophone();
  Future<void> playAudio(Uint8ListOrPath audio);
  Future<List<EbolaCapturedAsset>> importMedia();
}

class Uint8ListOrPath {
  final String localPath;
  const Uint8ListOrPath(this.localPath);
}

class EbolaUnsupportedFeature implements Exception {
  final String message;
  EbolaUnsupportedFeature(this.message);
  @override String toString() => 'Unsupported: $message';
}
