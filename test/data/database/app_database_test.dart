import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/database/app_database.dart';
import 'package:gemma_fitness/data/repositories/exercise_repository.dart';
import 'package:gemma_fitness/data/repositories/workout_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  late ExerciseRepository exerciseRepo;
  late WorkoutRepository workoutRepo;
  const uuid = Uuid();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exerciseRepo = ExerciseRepository(db);
    workoutRepo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Exercises Table & ExerciseRepository', () {
    test('Can insert and retrieve exercises', () async {
      final id = uuid.v4();
      final exercise = ExercisesCompanion.insert(
        id: id,
        name: 'Barbell Bench Press',
        category: 'Strength',
        primaryMuscle: 'Chest',
        equipment: 'Barbell',
        instructions: const Value('Lie on the bench and press the barbell up.'),
        defaultPhase: const Value('working'),
      );

      await exerciseRepo.insertExercise(exercise);

      final retrieved = await exerciseRepo.getExerciseById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Barbell Bench Press');
      expect(retrieved.category, 'Strength');
      expect(retrieved.primaryMuscle, 'Chest');
      expect(retrieved.equipment, 'Barbell');
      expect(retrieved.instructions, 'Lie on the bench and press the barbell up.');
      expect(retrieved.defaultPhase, 'working');
    });

    test('Can filter exercises by category, muscle, and phase', () async {
      final ex1 = ExercisesCompanion.insert(
        id: uuid.v4(),
        name: 'Arm Circles',
        category: 'Mobility',
        primaryMuscle: 'Shoulders',
        equipment: 'Bodyweight',
        defaultPhase: const Value('warmup'),
      );
      final ex2 = ExercisesCompanion.insert(
        id: uuid.v4(),
        name: 'Overhead Press',
        category: 'Strength',
        primaryMuscle: 'Shoulders',
        equipment: 'Barbell',
        defaultPhase: const Value('working'),
      );
      final ex3 = ExercisesCompanion.insert(
        id: uuid.v4(),
        name: 'Deadlift',
        category: 'Strength',
        primaryMuscle: 'Back',
        equipment: 'Barbell',
        defaultPhase: const Value('working'),
      );

      await exerciseRepo.bulkUpsertExercises([ex1, ex2, ex3]);

      final shoulderExercises = await exerciseRepo.getExercisesByMuscle('Shoulders');
      expect(shoulderExercises.length, 2);

      final strengthExercises = await exerciseRepo.getExercisesByCategory('Strength');
      expect(strengthExercises.length, 2);

      final warmupExercises = await exerciseRepo.getExercisesByPhase('warmup');
      expect(warmupExercises.length, 1);
      expect(warmupExercises.first.name, 'Arm Circles');

      final homeExercises =
          await exerciseRepo.getExercisesByEquipmentRequirement(false);
      expect(homeExercises.length, 0); // Default was true in manual insert without explicit value
    });

    test('Can query by requiresEquipment flag', () async {
      final bw = ExercisesCompanion.insert(
        id: uuid.v4(),
        name: 'Standard Push-Up',
        category: 'Strength',
        primaryMuscle: 'Chest',
        equipment: 'Bodyweight',
        requiresEquipment: const Value(false),
      );
      final fw = ExercisesCompanion.insert(
        id: uuid.v4(),
        name: 'Dumbbell Bench Press',
        category: 'Strength',
        primaryMuscle: 'Chest',
        equipment: 'Dumbbell',
        requiresEquipment: const Value(true),
      );

      await exerciseRepo.bulkUpsertExercises([bw, fw]);

      final noEquip =
          await exerciseRepo.getExercisesByEquipmentRequirement(false);
      expect(noEquip.length, 1);
      expect(noEquip.first.name, 'Standard Push-Up');

      final equipNeeded =
          await exerciseRepo.getExercisesByEquipmentRequirement(true);
      expect(equipNeeded.any((e) => e.name == 'Dumbbell Bench Press'), isTrue);
    });

    test('Can bulk upsert and update exercises', () async {
      final id = uuid.v4();
      final initial = ExercisesCompanion.insert(
        id: id,
        name: 'Squat',
        category: 'Strength',
        primaryMuscle: 'Quads',
        equipment: 'Barbell',
      );

      await exerciseRepo.bulkUpsertExercises([initial]);

      final updated = ExercisesCompanion.insert(
        id: id,
        name: 'Barbell Back Squat',
        category: 'Hypertrophy',
        primaryMuscle: 'Quads',
        equipment: 'Barbell',
        instructions: const Value('Deep squat below parallel.'),
      );

      await exerciseRepo.bulkUpsertExercises([updated]);

      final result = await exerciseRepo.getExerciseById(id);
      expect(result!.name, 'Barbell Back Squat');
      expect(result.category, 'Hypertrophy');
      expect(result.instructions, 'Deep squat below parallel.');
    });

    test('upsertExerciseByName prevents duplicate names and updates existing records', () async {
      final ex1 = ExercisesCompanion.insert(
        id: uuid.v4(),
        name: 'Dumbbell Hammer Curl',
        category: 'Strength',
        primaryMuscle: 'Biceps',
        equipment: 'Dumbbell',
        instructions: const Value('Neutral grip curl.'),
      );

      final id1 = await exerciseRepo.upsertExerciseByName(ex1);

      // Try inserting with case difference
      final ex2 = ExercisesCompanion.insert(
        id: uuid.v4(),
        name: 'dumbbell hammer curl',
        category: 'Hypertrophy',
        primaryMuscle: 'Biceps',
        equipment: 'Dumbbell',
        instructions: const Value('Keep elbows pinned at sides.'),
      );

      final id2 = await exerciseRepo.upsertExerciseByName(ex2);

      // Must have matched and reused original ID
      expect(id2, id1);

      final all = await exerciseRepo.getAllExercises();
      expect(all.length, 1);
      expect(all.first.instructions, 'Keep elbows pinned at sides.');
      expect(all.first.category, 'Hypertrophy');
    });

    test('deduplicateExercises identifies duplicates, updates references, and removes redundant rows', () async {
      final idA = uuid.v4();
      final idB = uuid.v4();
      final idC = uuid.v4();

      await exerciseRepo.insertExercise(ExercisesCompanion.insert(
        id: idA,
        name: 'Barbell Bench Press',
        category: 'Strength',
        primaryMuscle: 'Chest',
        equipment: 'Barbell',
        instructions: const Value('Detailed form cues for bench press.'),
      ));

      await exerciseRepo.insertExercise(ExercisesCompanion.insert(
        id: idB,
        name: 'barbell bench press',
        category: 'Strength',
        primaryMuscle: 'Chest',
        equipment: 'Barbell',
        instructions: const Value(''),
      ));

      await exerciseRepo.insertExercise(ExercisesCompanion.insert(
        id: idC,
        name: 'BARBELL BENCH PRESS',
        category: 'Strength',
        primaryMuscle: 'Chest',
        equipment: 'Barbell',
      ));

      // Link duplicate idB to a session exercise
      final sessionId = uuid.v4();
      await workoutRepo.createSession(WorkoutSessionsCompanion.insert(
        id: sessionId,
        dateStarted: DateTime.now(),
      ));

      final seId = uuid.v4();
      await workoutRepo.addExerciseToSession(SessionExercisesCompanion.insert(
        id: seId,
        sessionId: sessionId,
        exerciseId: idB,
      ));

      final removedCount = await exerciseRepo.deduplicateExercises();
      expect(removedCount, 2);

      final remaining = await exerciseRepo.getAllExercises();
      expect(remaining.length, 1);
      expect(remaining.first.id, idA);

      // Check session exercise reference was updated to idA
      final sessionExercises = await workoutRepo.getSessionExercises(sessionId);
      expect(sessionExercises.first.exerciseId, idA);
    });
  });

  group('Workout Sessions, Session Exercises, and Workout Sets', () {
    test('Complete relational flow: create session, map exercises with phases, and record sets', () async {
      // 1. Create Exercises
      final benchId = uuid.v4();
      final stretchId = uuid.v4();

      await exerciseRepo.bulkUpsertExercises([
        ExercisesCompanion.insert(
          id: stretchId,
          name: 'Chest Foam Roll',
          category: 'Mobility',
          primaryMuscle: 'Chest',
          equipment: 'Foam Roller',
          defaultPhase: const Value('warmup'),
        ),
        ExercisesCompanion.insert(
          id: benchId,
          name: 'Flat Barbell Bench Press',
          category: 'Strength',
          primaryMuscle: 'Chest',
          equipment: 'Barbell',
          defaultPhase: const Value('working'),
        ),
      ]);

      // 2. Create Workout Session
      final sessionId = uuid.v4();
      final now = DateTime.now();
      await workoutRepo.createSession(
        WorkoutSessionsCompanion.insert(
          id: sessionId,
          dateStarted: now,
          notes: const Value('Upper body push day'),
        ),
      );

      // 3. Add Session Exercises (warmup & working)
      final seWarmupId = uuid.v4();
      final seWorkingId = uuid.v4();

      await workoutRepo.addExerciseToSession(
        SessionExercisesCompanion.insert(
          id: seWarmupId,
          sessionId: sessionId,
          exerciseId: stretchId,
          phase: const Value('warmup'),
          orderInSession: const Value(1),
        ),
      );

      await workoutRepo.addExerciseToSession(
        SessionExercisesCompanion.insert(
          id: seWorkingId,
          sessionId: sessionId,
          exerciseId: benchId,
          phase: const Value('working'),
          orderInSession: const Value(2),
        ),
      );

      // 4. Add Granular Workout Sets with weights, reps, and RPE
      final set1Id = uuid.v4();
      final set2Id = uuid.v4();

      await workoutRepo.addSet(
        WorkoutSetsCompanion.insert(
          id: set1Id,
          sessionExerciseId: seWorkingId,
          setNumber: 1,
          setType: const Value('warmup'),
          weight: const Value(60.0),
          reps: const Value(10),
          rpe: const Value(6.0),
          isCompleted: const Value(true),
        ),
      );

      await workoutRepo.addSet(
        WorkoutSetsCompanion.insert(
          id: set2Id,
          sessionExerciseId: seWorkingId,
          setNumber: 2,
          setType: const Value('normal'),
          weight: const Value(100.0),
          reps: const Value(6),
          rpe: const Value(8.5),
          isCompleted: const Value(true),
        ),
      );

      // 5. Query Full Session Details Aggregate
      final details = await workoutRepo.getFullSessionDetails(sessionId);
      expect(details, isNotNull);
      expect(details!.session.notes, 'Upper body push day');
      expect(details.exercises.length, 2);

      // Warm-up item verification
      expect(details.exercises[0].exercise.name, 'Chest Foam Roll');
      expect(details.exercises[0].sessionExercise.phase, 'warmup');
      expect(details.exercises[0].sets.length, 0);

      // Working item verification
      expect(details.exercises[1].exercise.name, 'Flat Barbell Bench Press');
      expect(details.exercises[1].sessionExercise.phase, 'working');
      expect(details.exercises[1].sets.length, 2);
      expect(details.exercises[1].sets[0].weight, 60.0);
      expect(details.exercises[1].sets[0].rpe, 6.0);
      expect(details.exercises[1].sets[1].weight, 100.0);
      expect(details.exercises[1].sets[1].rpe, 8.5);

      // 6. Complete Session with AI Summary
      final endedAt = now.add(const Duration(minutes: 45));
      await workoutRepo.completeSession(
        sessionId,
        dateEnded: endedAt,
        aiSummary: 'Great session with solid progressive overload on bench press.',
      );

      final completedSession = await workoutRepo.getSessionById(sessionId);
      expect(completedSession!.dateEnded, isNotNull);
      expect(
        completedSession.aiSummary,
        'Great session with solid progressive overload on bench press.',
      );
    });

    test('Foreign key constraints prevent dangling session_exercises', () async {
      final invalidSessionId = uuid.v4();
      final invalidExerciseId = uuid.v4();

      expect(
        () => workoutRepo.addExerciseToSession(
          SessionExercisesCompanion.insert(
            id: uuid.v4(),
            sessionId: invalidSessionId,
            exerciseId: invalidExerciseId,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('Cascading deletion: Deleting a session deletes session_exercises and workout_sets', () async {
      final exerciseId = uuid.v4();
      await exerciseRepo.insertExercise(
        ExercisesCompanion.insert(
          id: exerciseId,
          name: 'Pull-up',
          category: 'Strength',
          primaryMuscle: 'Back',
          equipment: 'Bodyweight',
        ),
      );

      final sessionId = uuid.v4();
      await workoutRepo.createSession(
        WorkoutSessionsCompanion.insert(
          id: sessionId,
          dateStarted: DateTime.now(),
        ),
      );

      final seId = uuid.v4();
      await workoutRepo.addExerciseToSession(
        SessionExercisesCompanion.insert(
          id: seId,
          sessionId: sessionId,
          exerciseId: exerciseId,
        ),
      );

      final setId = uuid.v4();
      await workoutRepo.addSet(
        WorkoutSetsCompanion.insert(
          id: setId,
          sessionExerciseId: seId,
          setNumber: 1,
          weight: const Value(0.0),
          reps: const Value(12),
        ),
      );

      // Verify records exist before deletion
      final setsBefore = await workoutRepo.getSetsForSessionExercise(seId);
      expect(setsBefore.length, 1);

      // Delete the parent session
      await workoutRepo.deleteSession(sessionId);

      // Verify cascade deleted children
      final sessionAfter = await workoutRepo.getSessionById(sessionId);
      expect(sessionAfter, isNull);

      final sessionExercisesAfter = await workoutRepo.getSessionExercises(sessionId);
      expect(sessionExercisesAfter.isEmpty, isTrue);

      final setsAfter = await workoutRepo.getSetsForSessionExercise(seId);
      expect(setsAfter.isEmpty, isTrue);

      // Verify the master exercise itself was NOT deleted
      final exerciseStillExists = await exerciseRepo.getExerciseById(exerciseId);
      expect(exerciseStillExists, isNotNull);
    });

    test('Restricted deletion: Cannot delete an exercise if it is referenced in a session', () async {
      final exerciseId = uuid.v4();
      await exerciseRepo.insertExercise(
        ExercisesCompanion.insert(
          id: exerciseId,
          name: 'Squat',
          category: 'Strength',
          primaryMuscle: 'Quads',
          equipment: 'Barbell',
        ),
      );

      final sessionId = uuid.v4();
      await workoutRepo.createSession(
        WorkoutSessionsCompanion.insert(
          id: sessionId,
          dateStarted: DateTime.now(),
        ),
      );

      await workoutRepo.addExerciseToSession(
        SessionExercisesCompanion.insert(
          id: uuid.v4(),
          sessionId: sessionId,
          exerciseId: exerciseId,
        ),
      );

      // Attempting to delete the master exercise must fail due to ON DELETE RESTRICT
      expect(
        () => exerciseRepo.deleteExercise(exerciseId),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
