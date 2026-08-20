abstract class VoiceCoachService {
  Future<void> speak(String text, {double rate = 1.0, double pitch = 1.0});
  Future<void> stop();
  bool get isSpeaking;
}
