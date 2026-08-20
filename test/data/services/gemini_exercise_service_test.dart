import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/services/gemini_exercise_service.dart';

void main() {
  group('GeminiExerciseService JSON Parsing', () {
    final service = GeminiExerciseService(apiKey: 'dummy_key');

    test('Parses direct JSON array', () {
      const rawJson = '''
      [
        {
          "name": "Barbell Bench Press",
          "category": "Strength",
          "primary_muscle": "Chest",
          "equipment": "Barbell",
          "instructions": "Lower to chest and press up.",
          "default_phase": "working"
        },
        {
          "name": "Cat-Cow Stretch",
          "category": "Mobility",
          "primary_muscle": "Spine",
          "equipment": "Bodyweight",
          "instructions": "Arch and flex spine.",
          "default_phase": "warmup"
        }
      ]
      ''';

      final results = service.parseExercisesFromJson(rawJson);
      expect(results.length, 2);
      expect(results[0].name, 'Barbell Bench Press');
      expect(results[0].defaultPhase, 'working');
      expect(results[1].name, 'Cat-Cow Stretch');
      expect(results[1].defaultPhase, 'warmup');
    });

    test('Parses markdown fenced JSON block', () {
      const rawJson = '''
      ```json
      [
        {
          "name": "Pigeon Pose",
          "category": "Flexibility",
          "primary_muscle": "Glutes",
          "equipment": "Bodyweight",
          "default_phase": "cooldown"
        }
      ]
      ```
      ''';

      final results = service.parseExercisesFromJson(rawJson);
      expect(results.length, 1);
      expect(results[0].name, 'Pigeon Pose');
      expect(results[0].defaultPhase, 'cooldown');
    });

    test('Parses nested JSON object with exercises key', () {
      const rawJson = '''
      {
        "exercises": [
          {
            "name": "Deadlift",
            "category": "Strength",
            "primary_muscle": "Posterior Chain",
            "equipment": "Barbell",
            "default_phase": "working"
          }
        ]
      }
      ''';

      final results = service.parseExercisesFromJson(rawJson);
      expect(results.length, 1);
      expect(results[0].name, 'Deadlift');
    });
  });
}
