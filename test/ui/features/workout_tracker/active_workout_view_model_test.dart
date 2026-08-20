import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/database/app_database.dart';
import 'package:gemma_fitness/data/repositories/exercise_repository.dart';
import 'package:gemma_fitness/data/repositories/workout_repository.dart';
import 'package:gemma_fitness/data/services/exercise_sync_service.dart';
import 'package:gemma_fitness/domain/models/active_workout_models.dart';
import 'package:gemma_fitness/ui/features/workout_tracker/view_models/active_workout_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ExerciseRepository exerciseRepo;
  late WorkoutRepository workoutRepo;
  late ExerciseSyncService syncService;
  late ActiveWorkoutViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exerciseRepo = ExerciseRepository(db);
    workoutRepo = WorkoutRepository(db);
    syncService = ExerciseSyncService(exerciseRepository: exerciseRepo);

    await syncService.seedInitialExercisesIfEmpty();

    viewModel = ActiveWorkoutViewModel(
      workoutRepository: workoutRepo,
      exerciseRepository: exerciseRepo,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await db.close();
  });

  group('ActiveWorkoutViewModel', () {
    test('Can start a workout from a preset and populate exercises across phases', () async {
      final presets = WorkoutPreset.getStandardPresets();
      final homePreset = presets.first;

      final success = await viewModel.startWorkoutFromPreset(homePreset);
      expect(success, isTrue);
      expect(viewModel.hasActiveWorkout, isTrue);
      expect(viewModel.currentSession, isNotNull);

      final session = viewModel.currentSession!;
      expect(session.warmupExercises.isNotEmpty, isTrue);
      expect(session.workingExercises.isNotEmpty, isTrue);
      expect(session.cooldownExercises.isNotEmpty, isTrue);
      expect(session.allSets.isNotEmpty, isTrue);
    });

    test('Can start a blank workout, add exercises and sets, and complete sets', () async {
      await viewModel.startBlankWorkout(title: 'Upper Body Blast');
      expect(viewModel.hasActiveWorkout, isTrue);
      expect(viewModel.currentSession!.exercises.isEmpty, isTrue);

      final exercises = await exerciseRepo.getAllExercises();
      final bench = exercises.firstWhere((e) => e.name.contains('Bench'));

      // Add exercise to session
      await viewModel.addExerciseToSession(bench, phase: 'working');
      expect(viewModel.currentSession!.exercises.length, 1);

      final activeBench = viewModel.currentSession!.exercises.first;
      expect(activeBench.sets.length, 1);

      // Add second set
      await viewModel.addSetToExercise(activeBench);
      expect(viewModel.currentSession!.exercises.first.sets.length, 2);

      // Update set weight, reps, and toggle completion
      final set1 = viewModel.currentSession!.exercises.first.sets.first;
      await viewModel.updateSet(
        set1,
        weight: 80.0,
        reps: 8,
        isCompleted: true,
      );

      expect(viewModel.completedSetsCount, 1);
      expect(viewModel.currentVolume, 640.0); // 80kg * 8 reps
      expect(viewModel.isRestTimerActive, isTrue); // Rest timer automatically triggered
    });

    test('Rest timer functions correctly with pause, add time, and skip', () {
      viewModel.startRestTimer(60);
      expect(viewModel.isRestTimerActive, isTrue);
      expect(viewModel.restSecondsRemaining, 60);

      viewModel.addRestTime(30);
      expect(viewModel.restSecondsRemaining, 90);

      viewModel.skipRestTimer();
      expect(viewModel.isRestTimerActive, isFalse);
      expect(viewModel.restSecondsRemaining, 0);
    });

    test('Can finish a workout session and save records', () async {
      await viewModel.startBlankWorkout(title: 'Leg Day');
      final session = await viewModel.finishWorkout(notes: 'Crushed squats');

      expect(session, isNotNull);
      expect(viewModel.hasActiveWorkout, isFalse);

      final completed = await workoutRepo.getCompletedSessions();
      expect(completed.length, 1);
      expect(completed.first.notes, 'Crushed squats');
    });

    test('Can discard active workout', () async {
      await viewModel.startBlankWorkout(title: 'Discard Test');
      expect(viewModel.hasActiveWorkout, isTrue);

      await viewModel.discardWorkout();
      expect(viewModel.hasActiveWorkout, isFalse);

      final all = await workoutRepo.getAllSessions();
      expect(all.isEmpty, isTrue);
    });
  });
}
