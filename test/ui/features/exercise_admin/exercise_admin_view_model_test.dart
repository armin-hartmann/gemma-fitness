import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/database/app_database.dart';
import 'package:gemma_fitness/data/repositories/exercise_repository.dart';
import 'package:gemma_fitness/data/services/exercise_sync_service.dart';
import 'package:gemma_fitness/data/services/gemini_exercise_service.dart';
import 'package:gemma_fitness/domain/models/exercise_dto.dart';
import 'package:gemma_fitness/ui/features/exercise_admin/view_models/exercise_admin_view_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ExerciseRepository repo;
  late ExerciseSyncService syncService;
  late GeminiExerciseService geminiService;
  late ExerciseAdminViewModel viewModel;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExerciseRepository(db);
    syncService = ExerciseSyncService(exerciseRepository: repo);
    geminiService = GeminiExerciseService(apiKey: 'dummy');
    viewModel = ExerciseAdminViewModel(
      exerciseRepository: repo,
      syncService: syncService,
      geminiService: geminiService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ExerciseAdminViewModel', () {
    test('Initializes and loads seed exercises', () async {
      await viewModel.initialize();

      expect(viewModel.totalCount, greaterThanOrEqualTo(20));
      expect(viewModel.warmupCount, greaterThan(0));
      expect(viewModel.workingCount, greaterThan(0));
      expect(viewModel.cooldownCount, greaterThan(0));
      expect(viewModel.filteredExercises.length, viewModel.totalCount);
    });

    test('Filters exercises by search query', () async {
      await viewModel.initialize();

      viewModel.setSearchQuery('bench');
      expect(
        viewModel.filteredExercises.every(
          (e) =>
              e.name.toLowerCase().contains('bench') ||
              e.category.toLowerCase().contains('bench') ||
              e.primaryMuscle.toLowerCase().contains('bench') ||
              e.equipment.toLowerCase().contains('bench'),
        ),
        isTrue,
      );
    });

    test('Filters exercises by phase and muscle', () async {
      await viewModel.initialize();

      viewModel.setPhase('warmup');
      expect(viewModel.filteredExercises.length, viewModel.warmupCount);
      expect(
        viewModel.filteredExercises.every((e) =>
            e.defaultPhase.toLowerCase() == 'warmup' ||
            e.defaultPhase.toLowerCase() == 'versatile'),
        isTrue,
      );

      viewModel.resetFilters();
      expect(viewModel.filteredExercises.length, viewModel.totalCount);
    });

    test('Filters exercises by equipment modality (no equipment, free weights, machines)', () async {
      await viewModel.initialize();

      // Filter by No Equipment (Home)
      viewModel.setEquipmentFilter('no_equipment');
      expect(viewModel.filteredExercises.length, viewModel.noEquipmentCount);
      expect(viewModel.noEquipmentCount, greaterThan(0));
      expect(
        viewModel.filteredExercises.every((e) =>
            !e.requiresEquipment || e.equipment.toLowerCase() == 'bodyweight'),
        isTrue,
      );

      // Filter by Free Weights
      viewModel.setEquipmentFilter('free_weights');
      expect(viewModel.filteredExercises.length, viewModel.freeWeightsCount);
      expect(viewModel.freeWeightsCount, greaterThan(0));
      expect(
        viewModel.filteredExercises.every((e) {
          final eq = e.equipment.toLowerCase();
          return eq.contains('barbell') ||
              eq.contains('dumbbell') ||
              eq.contains('kettlebell');
        }),
        isTrue,
      );

      // Filter by Machines
      viewModel.setEquipmentFilter('machines');
      expect(viewModel.filteredExercises.length, viewModel.machinesCount);
      expect(
        viewModel.filteredExercises.every((e) {
          final eq = e.equipment.toLowerCase();
          return eq.contains('machine') || eq.contains('cable');
        }),
        isTrue,
      );

      viewModel.resetFilters();
      expect(viewModel.filteredExercises.length, viewModel.totalCount);
    });

    test('Can save new exercise, update, and delete', () async {
      await viewModel.initialize();
      final initialTotal = viewModel.totalCount;

      final newExercise = ExerciseDto(
        name: 'Hammer Curls',
        category: 'Hypertrophy',
        primaryMuscle: 'Biceps',
        equipment: 'Dumbbell',
        defaultPhase: 'working',
      );

      final success = await viewModel.saveExercise(newExercise);
      expect(success, isTrue);
      expect(viewModel.totalCount, initialTotal + 1);

      final saved = viewModel.filteredExercises
          .firstWhere((e) => e.name == 'Hammer Curls');

      final updatedDto = ExerciseDto(
        id: saved.id,
        name: 'Incline Hammer Curls',
        category: 'Hypertrophy',
        primaryMuscle: 'Biceps',
        equipment: 'Dumbbell',
        defaultPhase: 'working',
      );

      final updateSuccess = await viewModel.updateExercise(updatedDto);
      expect(updateSuccess, isTrue);
      expect(
        viewModel.filteredExercises
            .any((e) => e.name == 'Incline Hammer Curls'),
        isTrue,
      );

      final deleteSuccess = await viewModel.deleteExercise(saved.id);
      expect(deleteSuccess, isTrue);
      expect(viewModel.totalCount, initialTotal);
    });

    test('Can bulk save parsed ingestion results', () async {
      await viewModel.initialize();
      final initialTotal = viewModel.totalCount;

      final parsed = [
        ExerciseDto(
          name: 'Arnold Press',
          category: 'Hypertrophy',
          primaryMuscle: 'Shoulders',
          equipment: 'Dumbbell',
        ),
        ExerciseDto(
          name: 'Face Pull',
          category: 'Hypertrophy',
          primaryMuscle: 'Rear Delts',
          equipment: 'Cable',
        ),
      ];

      // Simulate parsed items in state
      for (final p in parsed) {
        viewModel.parsedIngestionResults.add(p);
      }

      final savedCount = await viewModel.saveParsedIngestionResults();
      expect(savedCount, 2);
      expect(viewModel.totalCount, initialTotal + 2);
      expect(viewModel.parsedIngestionResults.isEmpty, isTrue);
    });
  });
}
