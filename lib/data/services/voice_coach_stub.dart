import '../../domain/services/voice_coach_service.dart';

VoiceCoachService createVoiceCoachService() => StubVoiceCoachService();

class StubVoiceCoachService implements VoiceCoachService {
  @override
  bool get isSpeaking => false;

  @override
  Future<void> speak(String text, {double rate = 1.0, double pitch = 1.0}) async {}

  @override
  Future<void> stop() async {}
}
