import 'audio_feedback_service.dart';

AudioFeedbackService createAudioFeedbackService() => StubAudioFeedbackService();

class StubAudioFeedbackService implements AudioFeedbackService {
  @override
  void playCountdownTick(int secondsRemaining) {}

  @override
  void playRestComplete() {}

  @override
  void playPrFanfare() {}

  @override
  void playButtonClick() {}
}
