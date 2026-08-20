import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/services/gemini_workout_service.dart';

void main() {
  late GeminiWorkoutService service;

  setUp(() {
    service = GeminiWorkoutService(apiKey: 'test-api-key');
  });

  group('GeminiWorkoutService JSON Parsing', () {
    test('Parses valid workout JSON response correctly', () {
      const jsonStr = '''
      {
        "title": "⚡ 30-Min Home Chest & Core Blast",
        "description": "High-density push and core routine requiring zero equipment.",
        "modality": "bodyweight",
        "reasoning": "Designed for maximum stimulus in 30 minutes without gym equipment.",
        "exercises": [
          {
            "exercise_name": "Dynamic Chest Opener",
            "phase": "warmup",
            "target_sets": 2,
            "target_reps": 12,
            "target_weight": null,
            "target_rpe": null,
            "coaching_cue": "Keep shoulders down and open arms wide",
            "category": "Mobility",
            "primary_muscle": "Chest",
            "equipment": "Bodyweight",
            "requires_equipment": false
          },
          {
            "exercise_name": "Standard Push-Up",
            "phase": "working",
            "target_sets": 4,
            "target_reps": 15,
            "target_weight": null,
            "target_rpe": 8.5,
            "coaching_cue": "Tuck elbows at 45 degrees, full depth",
            "category": "Strength",
            "primary_muscle": "Chest",
            "equipment": "Bodyweight",
            "requires_equipment": false
          },
          {
            "exercise_name": "Plank Shoulder Taps",
            "phase": "working",
            "target_sets": 3,
            "target_reps": 20,
            "target_weight": null,
            "target_rpe": 8.0,
            "coaching_cue": "Avoid swaying hips side to side",
            "category": "Core",
            "primary_muscle": "Abs",
            "equipment": "Bodyweight",
            "requires_equipment": false
          },
          {
            "exercise_name": "Pectoral Doorway Stretch",
            "phase": "cooldown",
            "target_sets": 2,
            "target_reps": 30,
            "target_weight": null,
            "target_rpe": null,
            "coaching_cue": "Gentle stretch on anterior deltoid and chest",
            "category": "Mobility",
            "primary_muscle": "Chest",
            "equipment": "Bodyweight",
            "requires_equipment": false
          }
        ]
      }
      ''';

      final result = service.parseWorkoutResultFromJson(jsonStr, 'bodyweight');

      expect(result.title, '⚡ 30-Min Home Chest & Core Blast');
      expect(result.modality, 'bodyweight');
      expect(result.exercises.length, 4);

      final warmup = result.exercises[0];
      expect(warmup.presetItem.exerciseName, 'Dynamic Chest Opener');
      expect(warmup.presetItem.phase, 'warmup');
      expect(warmup.presetItem.targetSets, 2);
      expect(warmup.presetItem.targetReps, 12);
      expect(warmup.coachingCue, 'Keep shoulders down and open arms wide');

      final working = result.exercises[1];
      expect(working.presetItem.exerciseName, 'Standard Push-Up');
      expect(working.presetItem.phase, 'working');
      expect(working.presetItem.targetRpe, 8.5);

      final newDef = working.newExerciseDefinition;
      expect(newDef, isNotNull);
      expect(newDef!.name, 'Standard Push-Up');
      expect(newDef.primaryMuscle, 'Chest');
      expect(newDef.requiresEquipment, isFalse);
    });

    test('Parses markdown fenced JSON block', () {
      const fencedJson = '''
      ```json
      {
        "title": "🏋️ Dumbbell Back & Biceps",
        "description": "Pull-focused hypertrophy session.",
        "modality": "free_weights",
        "reasoning": "Targets vertical and horizontal pulling patterns.",
        "exercises": [
          {
            "exercise_name": "Dumbbell Bent-Over Row",
            "phase": "working",
            "target_sets": 4,
            "target_reps": 10,
            "target_weight": 22.0,
            "target_rpe": 8.0,
            "category": "Strength",
            "primary_muscle": "Lats",
            "equipment": "Dumbbell",
            "requires_equipment": true
          }
        ]
      }
      ```
      ''';

      final result = service.parseWorkoutResultFromJson(fencedJson, 'free_weights');
      expect(result.title, '🏋️ Dumbbell Back & Biceps');
      expect(result.exercises.length, 1);
      expect(result.exercises.first.presetItem.targetWeight, 22.0);
      expect(result.exercises.first.newExerciseDefinition!.requiresEquipment, isTrue);
    });
  });
}
