/// Never log bearer tokens, biometric data, GPS, audio, decrypted media or user files.
class EbolaSafeLog {
  final void Function(String) sink;
  const EbolaSafeLog(this.sink);
  void event(String action, {String? code}) => sink('EBOLA SDK: $action${code == null ? '' : ' [$code]'}');
}
