/// Metadata only; actual bytes must be uploaded to the existing encrypted Vault.
class EbolaMediaManifest {
  final String deviceId;
  final String localPath;
  final String mimeType;
  final int sizeBytes;
  final String sha256Hex;
  final DateTime capturedAtUtc;
  const EbolaMediaManifest({required this.deviceId,required this.localPath, required this.mimeType,
    required this.sizeBytes,required this.sha256Hex,required this.capturedAtUtc});
  Map<String, Object?> toJson() => {'device_id':deviceId,'mime_type':mimeType,
    'size_bytes':sizeBytes,'sha256':sha256Hex,'captured_at':capturedAtUtc.toIso8601String()};
}
