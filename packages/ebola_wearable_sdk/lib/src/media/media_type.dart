enum EbolaMediaKind { photo, video, audio, document }
class EbolaMediaRequest {
  final EbolaMediaKind kind;
  final String deviceId;
  final bool hasUserConsent;
  const EbolaMediaRequest({required this.kind,required this.deviceId,required this.hasUserConsent});
  void checkConsent() { if (!hasUserConsent) throw StateError('Media action needs user consent'); }
}
