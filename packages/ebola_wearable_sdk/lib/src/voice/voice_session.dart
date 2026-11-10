import 'dart:async';
/// Voice STT/TTS implementation belongs to approved phone/provider integrations.
abstract class EbolaVoicePort {
  Future<void> startListening({required String locale});
  Stream<String> get recognizedText;
  Future<void> stopListening();
  Future<void> speak(String text, {required String locale});
}
class EbolaVoiceSession {
  final EbolaVoicePort port;
  bool _listening=false;
  EbolaVoiceSession(this.port);
  Future<void> start({required bool userInitiated, String locale='auto'}) async {
    if (!userInitiated) throw StateError('Voice requires explicit user initiation');
    if (_listening) throw StateError('Already listening');
    await port.startListening(locale:locale);_listening=true;
  }
  Stream<String> get transcripts => port.recognizedText;
  Future<void> stop() async { if (_listening) {await port.stopListening();_listening=false;} }
}
