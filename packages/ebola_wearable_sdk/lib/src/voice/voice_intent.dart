enum EbolaVoiceIntent { describeScene, readText, capturePhoto, startVideo, stopVideo, askKrishna, help, unknown }
class EbolaVoiceIntentParser {
  EbolaVoiceIntent parse(String utterance) {
    final u = utterance.trim().toLowerCase();
    if (u.contains('describe') || u.contains('what is in front')) return EbolaVoiceIntent.describeScene;
    if (u.contains('read') || u.contains('ocr')) return EbolaVoiceIntent.readText;
    if (u.contains('photo') || u.contains('picture')) return EbolaVoiceIntent.capturePhoto;
    if (u.contains('stop video') || u.contains('stop recording')) return EbolaVoiceIntent.stopVideo;
    if (u.contains('video') || u.contains('record')) return EbolaVoiceIntent.startVideo;
    if (u.contains('help') || u.contains('emergency')) return EbolaVoiceIntent.help;
    if (u.isNotEmpty) return EbolaVoiceIntent.askKrishna;
    return EbolaVoiceIntent.unknown;
  }
}
