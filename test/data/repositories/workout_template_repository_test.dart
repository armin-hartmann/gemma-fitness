import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/repositories/workout_template_repository.dart';
import 'package:gemma_fitness/domain/models/active_workout_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorkoutTemplateRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = WorkoutTemplateRepository();
  });

  group('WorkoutTemplateRepository', () {
    test('Seeds standard presets on first call', () async {
      final templates = await repo.getAllTemplates();
      expect(templates.length, 3);
      expect(templates[0].id, 'preset-home-bw');
      expect(templates[0].modality, 'bodyweight');
      expect(templates[1].id, 'preset-fw-upper');
      expect(templates[2].id, 'preset-fw-lower');
    });

    test('Can save a new custom workout template and retrieve it', () async {
      const custom = WorkoutPreset(
        id: 'custom-glutes-core',
        title: '🍑 Glutes & Core Focus',
        description: 'Targeted glute hypertrophy and core stability',
        modality: 'free_weights',
        exercisePhases: [
          PresetExerciseItem(
            exerciseName: 'Glute Bridge',
            phase: 'warmup',
            targetSets: 2,
            targetReps: 15,
          ),
          PresetExerciseItem(
            exerciseName: 'Barbell Hip Thrust',
            phase: 'working',
            targetSets: 4,
            targetReps: 10,
            targetWeight: 90.0,
            targetRpe: 8.5,
          ),
        ],
        isCustom: true,
      );

      await repo.saveTemplate(custom);

      final templates = await repo.getAllTemplates();
      expect(templates.length, 4);
      final saved = templates.firstWhere((t) => t.id == 'custom-glutes-core');
      expect(saved.title, '🍑 Glutes & Core Focus');
      expect(saved.exercisePhases.length, 2);
      expect(saved.exercisePhases[1].targetWeight, 90.0);
    });

    test('Can edit an existing template', () async {
      final templates = await repo.getAllTemplates();
      final first = templates[0];

      final edited = first.copyWith(
        title: '🏠 Modified Home Routine',
        exercisePhases: [
          ...first.exercisePhases,
          const PresetExerciseItem(
            exerciseName: 'Mountain Climbers',
            phase: 'working',
            targetSets: 3,
            targetReps: 20,
          ),
        ],
      );

      await repo.saveTemplate(edited);

      final updatedTemplates = await repo.getAllTemplates();
      expect(updatedTemplates.length, 3);
      final updated = updatedTemplates.firstWhere((t) => t.id == first.id);
      expect(updated.title, '🏠 Modified Home Routine');
      expect(updated.exercisePhases.length, first.exercisePhases.length + 1);
    });

    test('Can delete a template and reset to defaults', () async {
      await repo.deleteTemplate('preset-home-bw');
      var templates = await repo.getAllTemplates();
      expect(templates.length, 2);

      final reset = await repo.resetToDefaults();
      expect(reset.length, 3);
      expect(reset.any((t) => t.id == 'preset-home-bw'), isTrue);
    });
  });
}
