/// Device licensing is authoritative only on the EBOLA server.
/// This SDK exposes typed requests; it does not mint/validate licences locally.
/// Client must provide a secure authenticated HTTPS transport implementation.
enum EbolaLicenceState { unassigned, active, suspended, revoked, replaced, expired }

class EbolaDeviceBinding {
  final String deviceId;
  final String modelCode;
  final String? hardwareAttestation;
  const EbolaDeviceBinding({required this.deviceId, required this.modelCode,
      this.hardwareAttestation});
  Map<String, Object?> toJson() => {
    'device_id':deviceId,'model_code':modelCode,
    if (hardwareAttestation != null) 'hardware_attestation':hardwareAttestation,
  };
}

class EbolaLicenceDecision {
  final bool allowed;
  final EbolaLicenceState state;
  final String? licenceId;
  final String? reason;
  final DateTime? validUntil;
  const EbolaLicenceDecision({required this.allowed,required this.state,
    this.licenceId,this.reason,this.validUntil});
}

/// HTTP implementation belongs in a secured app/backend integration layer.
/// Do not embed API keys, signing secrets or manufacturer credentials in APKs.
abstract class EbolaLicenceGateway {
  /// Backend must atomically enforce one active device per licence.
  Future<EbolaLicenceDecision> activate(EbolaDeviceBinding binding);
  Future<EbolaLicenceDecision> validate(EbolaDeviceBinding binding);
  Future<void> deactivate(EbolaDeviceBinding binding);
  /// Requires an approved warranty case; old device is revoked atomically.
  Future<EbolaLicenceDecision> replace({required String approvedCaseId,
    required EbolaDeviceBinding oldDevice, required EbolaDeviceBinding replacement});
}

class EbolaLicenseGate {
  final EbolaLicenceGateway gateway;
  EbolaLicenseGate(this.gateway);
  /// Fail closed: no network / no positive response = cannot use premium SDK actions.
  Future<void> requireActive(EbolaDeviceBinding binding) async {
    final result = await gateway.validate(binding);
    if (!result.allowed || result.state != EbolaLicenceState.active) {
      throw StateError('Device licence inactive: ${result.reason ?? result.state.name}');
    }
  }
}
