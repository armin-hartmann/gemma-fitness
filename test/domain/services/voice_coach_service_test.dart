import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/services/cross_platform_voice_coach_service.dart';
import 'package:gemma_fitness/domain/services/voice_coach_service.dart';

class MockVoiceCoachService implements VoiceCoachService {
  final List<String> spokenHistory = [];
  bool _speaking = false;

  @override
  bool get isSpeaking => _speaking;

  @override
  Future<void> speak(String text, {double rate = 1.0, double pitch = 1.0}) async {
    _speaking = true;
    spokenHistory.add(text);
    _speaking = false;
  }

  @override
  Future<void> stop() async {
    _speaking = false;
  }
}

void main() {
  group('VoiceCoachService', () {
    test('CrossPlatformVoiceCoachService instantiates and calls speak safely', () async {
      final service = CrossPlatformVoiceCoachService();
      expect(service.isSpeaking, isFalse);
      await service.speak('Testing voice coach fallback');
      await service.stop();
      expect(service.isSpeaking, isFalse);
    });

    test('MockVoiceCoachService logs spoken utterances', () async {
      final mock = MockVoiceCoachService();
      await mock.speak('Workout started');
      await mock.speak('Rest complete. Up next: Squats.');

      expect(mock.spokenHistory.length, 2);
      expect(mock.spokenHistory.first, 'Workout started');
      expect(mock.spokenHistory.last, 'Rest complete. Up next: Squats.');
    });
  });
}
