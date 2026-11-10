enum EbolaErrorCode { unsupported, permissionDenied, disconnected, timeout, protocolMismatch, licenceDenied, mediaTransferFailed, unauthorized, unsafeFirmware, internal }
class EbolaSdkError implements Exception {
  final EbolaErrorCode code;
  final String message;
  const EbolaSdkError(this.code, this.message);
  @override String toString() => 'EBOLA SDK ${code.name}: $message';
}
