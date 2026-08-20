import 'audio_feedback_stub.dart'
    if (dart.library.js_interop) 'audio_feedback_web.dart';

abstract class AudioFeedbackService {
  factory AudioFeedbackService() => createAudioFeedbackService();

  void playCountdownTick(int secondsRemaining);
  void playRestComplete();
  void playPrFanfare();
  void playButtonClick();
}
