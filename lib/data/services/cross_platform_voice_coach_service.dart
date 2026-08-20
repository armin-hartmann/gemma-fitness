import 'voice_coach_stub.dart'
    if (dart.library.js_interop) 'voice_coach_web.dart';
import '../../domain/services/voice_coach_service.dart';

class CrossPlatformVoiceCoachService implements VoiceCoachService {
  CrossPlatformVoiceCoachService() : _delegate = createVoiceCoachService();

  final VoiceCoachService _delegate;

  @override
  bool get isSpeaking => _delegate.isSpeaking;

  @override
  Future<void> speak(String text, {double rate = 1.0, double pitch = 1.0}) =>
      _delegate.speak(text, rate: rate, pitch: pitch);

  @override
  Future<void> stop() => _delegate.stop();
}
