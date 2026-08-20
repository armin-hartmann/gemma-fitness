import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/services/audio_feedback_service.dart';

class MockAudioFeedbackService implements AudioFeedbackService {
  final List<String> logs = [];

  @override
  void playCountdownTick(int secondsRemaining) {
    logs.add('tick:$secondsRemaining');
  }

  @override
  void playRestComplete() {
    logs.add('restComplete');
  }

  @override
  void playPrFanfare() {
    logs.add('prFanfare');
  }

  @override
  void playButtonClick() {
    logs.add('buttonClick');
  }
}

void main() {
  group('AudioFeedbackService', () {
    test('AudioFeedbackService factory instantiates without error', () {
      final service = AudioFeedbackService();
      expect(service, isNotNull);
      // Calling methods outside of web will safely no-op
      service.playCountdownTick(3);
      service.playRestComplete();
      service.playPrFanfare();
      service.playButtonClick();
    });

    test('Mock audio service records sound events', () {
      final mock = MockAudioFeedbackService();
      mock.playCountdownTick(3);
      mock.playCountdownTick(2);
      mock.playCountdownTick(1);
      mock.playRestComplete();
      mock.playPrFanfare();
      mock.playButtonClick();

      expect(mock.logs, [
        'tick:3',
        'tick:2',
        'tick:1',
        'restComplete',
        'prFanfare',
        'buttonClick',
      ]);
    });
  });
}
