import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/database/app_database.dart';
import 'package:gemma_fitness/data/repositories/exercise_repository.dart';
import 'package:gemma_fitness/data/repositories/workout_template_repository.dart';
import 'package:gemma_fitness/domain/models/active_workout_models.dart';
import 'package:gemma_fitness/domain/models/exercise_dto.dart';
import 'package:gemma_fitness/domain/services/workout_ai_service.dart';
import 'package:gemma_fitness/ui/features/workout_tracker/view_models/ai_workout_generator_view_model.dart';
import 'package:gemma_fitness/ui/features/workout_tracker/view_models/workout_templates_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeWorkoutAiService implements WorkoutAiService {
  WorkoutGenerationRequest? lastRequest;

  @override
  Future<bool> get isReady async => true;

  @override
  Future<GeneratedWorkoutResult> generateWorkout(
    WorkoutGenerationRequest request, {
    String? overrideApiKey,
  }) async {
    lastRequest = request;
    return GeneratedWorkoutResult(
      title: 'Generated ${request.goal} Routine',
      description: 'Customized for ${request.modality}',
      modality: request.modality,
      reasoning: 'Tailored for ${request.durationMinutes} min',
      exercises: [
        GeneratedExerciseItem(
          presetItem: const PresetExerciseItem(
            exerciseName: 'AI Custom Exercise',
            phase: 'working',
            targetSets: 3,
            targetReps: 12,
            targetWeight: 15.0,
            targetRpe: 8.0,
          ),
          newExerciseDefinition: ExerciseDto(
            name: 'AI Custom Exercise',
            category: 'Strength',
            primaryMuscle: 'Chest',
            equipment: 'Dumbbell',
            defaultPhase: 'working',
            requiresEquipment: true,
          ),
          coachingCue: 'Control the descent',
        ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ExerciseRepository exerciseRepo;
  late WorkoutTemplateRepository templateRepo;
  late WorkoutTemplatesViewModel templatesViewModel;
  late FakeWorkoutAiService fakeAiService;
  late AiWorkoutGeneratorViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exerciseRepo = ExerciseRepository(db);
    templateRepo = WorkoutTemplateRepository();
    templatesViewModel = WorkoutTemplatesViewModel(templateRepository: templateRepo);
    await templatesViewModel.loadTemplates();

    fakeAiService = FakeWorkoutAiService();
    viewModel = AiWorkoutGeneratorViewModel(
      aiService: fakeAiService,
      exerciseRepository: exerciseRepo,
      templatesViewModel: templatesViewModel,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AiWorkoutGeneratorViewModel', () {
    test('Can update questionnaire settings', () {
      viewModel.setGoal('Strength');
      expect(viewModel.selectedGoal, 'Strength');

      viewModel.setModality('free_weights');
      expect(viewModel.selectedModality, 'free_weights');

      viewModel.setDuration(45);
      expect(viewModel.selectedDuration, 45);

      viewModel.toggleMuscle('Chest');
      expect(viewModel.selectedMuscles, contains('Chest'));
      expect(viewModel.selectedMuscles, isNot(contains('Full Body')));
    });

    test('Can execute generateWorkout and modify sets/reps inline', () async {
      viewModel.setGoal('Hypertrophy');
      viewModel.setModality('free_weights');
      viewModel.setDuration(30);

      await viewModel.generateWorkout();

      expect(viewModel.isGenerating, isFalse);
      expect(viewModel.generatedResult, isNotNull);
      expect(viewModel.generatedResult!.title, 'Generated Hypertrophy Routine');
      expect(viewModel.generatedResult!.exercises.length, 1);
      expect(viewModel.generatedResult!.exercises.first.presetItem.targetSets, 3);

      // Modify sets & reps inline
      viewModel.updateExerciseSets(0, 4);
      expect(viewModel.generatedResult!.exercises.first.presetItem.targetSets, 4);

      viewModel.updateExerciseReps(0, 15);
      expect(viewModel.generatedResult!.exercises.first.presetItem.targetReps, 15);
    });

    test('Saving generated preset syncs missing exercise to catalog and saves template', () async {
      await viewModel.generateWorkout();

      // Ensure exercise doesn't exist yet in catalog
      final before = await exerciseRepo.getExerciseByName('AI Custom Exercise');
      expect(before, isNull);

      final savedPreset = await viewModel.saveGeneratedPreset();
      expect(savedPreset, isNotNull);
      expect(savedPreset!.title, 'Generated Hypertrophy Routine');

      // Check exercise was inserted into SQLite catalog
      final after = await exerciseRepo.getExerciseByName('AI Custom Exercise');
      expect(after, isNotNull);
      expect(after!.primaryMuscle, 'Chest');
      expect(after.requiresEquipment, isTrue);

      // Check template was saved to templates view model
      final allTemplates = await templateRepo.getAllTemplates();
      expect(allTemplates.any((t) => t.id == savedPreset.id), isTrue);
    });
  });
}
