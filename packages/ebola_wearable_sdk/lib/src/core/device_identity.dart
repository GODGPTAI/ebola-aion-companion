class EbolaDeviceIdentity {
  final String deviceId;
  final String modelCode;
  final String? firmwareVersion;
  final String? attestation;
  const EbolaDeviceIdentity({required this.deviceId, required this.modelCode, this.firmwareVersion, this.attestation});
  bool get hasHardwareAttestation => attestation != null && attestation!.trim().isNotEmpty;
  Map<String, Object?> toJson() => {'device_id': deviceId, 'model_code': modelCode,
    if (firmwareVersion != null) 'firmware_version': firmwareVersion,
    if (attestation != null) 'attestation': attestation};
}
