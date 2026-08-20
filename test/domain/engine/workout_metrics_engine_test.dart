import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/database/app_database.dart';
import 'package:gemma_fitness/domain/engine/workout_metrics_engine.dart';
import 'package:gemma_fitness/domain/models/active_workout_models.dart';

void main() {
  group('WorkoutMetricsEngine', () {
    test('Calculates Epley and Brzycki 1RM accurately', () {
      // 1 rep of 100kg should be exactly 100kg
      expect(WorkoutMetricsEngine.calculateEpley1RM(100.0, 1), 100.0);
      expect(WorkoutMetricsEngine.calculateBrzycki1RM(100.0, 1), 100.0);
      expect(WorkoutMetricsEngine.calculateEstimated1RM(100.0, 1), 100.0);

      // 10 reps of 100kg:
      // Epley: 100 * (1 + 10/30) = 133.33 kg
      // Brzycki: 100 / (1.0278 - (0.0278 * 10)) = 133.36 kg
      final epley = WorkoutMetricsEngine.calculateEpley1RM(100.0, 10);
      final brzycki = WorkoutMetricsEngine.calculateBrzycki1RM(100.0, 10);
      final avg = WorkoutMetricsEngine.calculateEstimated1RM(100.0, 10);

      expect(epley, closeTo(133.33, 0.1));
      expect(brzycki, closeTo(133.36, 0.1));
      expect(avg, closeTo(133.34, 0.1));
    });

    test('Calculates total volume for completed sets only', () {
      final sets = [
        const WorkoutSet(
          id: 's1',
          sessionExerciseId: 'se1',
          setNumber: 1,
          setType: 'normal',
          weight: 50.0,
          reps: 10,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's2',
          sessionExerciseId: 'se1',
          setNumber: 2,
          setType: 'normal',
          weight: 60.0,
          reps: 8,
          isCompleted: true,
        ),
        const WorkoutSet(
          id: 's3',
          sessionExerciseId: 'se1',
          setNumber: 3,
          setType: 'normal',
          weight: 70.0,
          reps: 6,
          isCompleted: false, // Uncompleted set should not count toward volume
        ),
      ];

      // Completed: (50*10) + (60*8) = 500 + 480 = 980 kg
      final vol = WorkoutMetricsEngine.calculateSessionVolume(sets);
      expect(vol, 980.0);

      final totalReps = WorkoutMetricsEngine.calculateTotalCompletedReps(sets);
      expect(totalReps, 18);
    });

    test('Detects personal records (max weight and 1RM)', () {
      const exercise = Exercise(
        id: 'ex-bench',
        name: 'Barbell Bench Press',
        category: 'Strength',
        primaryMuscle: 'Chest',
        equipment: 'Barbell',
        defaultPhase: 'working',
        requiresEquipment: true,
      );

      final historicalSets = [
        const WorkoutSet(
          id: 'h1',
          sessionExerciseId: 'hse1',
          setNumber: 1,
          setType: 'normal',
          weight: 80.0,
          reps: 8,
          isCompleted: true,
        ),
      ];

      // Current workout: lifted 90.0 kg for 8 reps (beats 80kg max weight & 1RM)
      final currentSets = [
        const WorkoutSet(
          id: 'c1',
          sessionExerciseId: 'cse1',
          setNumber: 1,
          setType: 'normal',
          weight: 90.0,
          reps: 8,
          isCompleted: true,
        ),
      ];

      final prs = WorkoutMetricsEngine.detectPersonalRecords(
        exercise: exercise,
        currentSets: currentSets,
        historicalSets: historicalSets,
      );

      expect(prs.isNotEmpty, isTrue);
      expect(prs.any((p) => p.type == PRType.maxWeight), isTrue);
      expect(prs.any((p) => p.type == PRType.estimated1RM), isTrue);
      expect(prs.first.value, 90.0);
    });

    test('Formats duration correctly', () {
      expect(
          WorkoutMetricsEngine.formatDuration(const Duration(minutes: 45, seconds: 12)),
          '45:12');
      expect(
          WorkoutMetricsEngine.formatDuration(
              const Duration(hours: 1, minutes: 15, seconds: 5)),
          '01:15:05');
    });
  });
}
