import '../../data/database/app_database.dart';
import '../models/active_workout_models.dart';

class WorkoutMetricsEngine {
  const WorkoutMetricsEngine();

  /// Calculates estimated 1 Rep Max using the Epley formula:
  /// 1RM = Weight * (1 + Reps / 30)
  /// For 1 rep, 1RM is exactly the weight lifted.
  static double calculateEpley1RM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weight;
    return weight * (1.0 + (reps / 30.0));
  }

  /// Calculates estimated 1 Rep Max using the Brzycki formula:
  /// 1RM = Weight / (1.0278 - (0.0278 * Reps))
  static double calculateBrzycki1RM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weight;
    final denominator = 1.0278 - (0.0278 * reps);
    if (denominator <= 0) return weight * 1.5;
    return weight / denominator;
  }

  /// Calculates estimated 1RM taking the average of Epley & Brzycki for balanced accuracy.
  static double calculateEstimated1RM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weight;
    final epley = calculateEpley1RM(weight, reps);
    final brzycki = calculateBrzycki1RM(weight, reps);
    return (epley + brzycki) / 2.0;
  }

  /// Calculates total volume (weight * reps) for all completed sets.
  static double calculateSessionVolume(List<WorkoutSet> sets) {
    double total = 0.0;
    for (final set in sets) {
      if (set.isCompleted && set.weight > 0 && set.reps > 0) {
        total += (set.weight * set.reps);
      }
    }
    return total;
  }

  /// Total completed reps across all completed sets in a session.
  static int calculateTotalCompletedReps(List<WorkoutSet> sets) {
    int reps = 0;
    for (final set in sets) {
      if (set.isCompleted) {
        reps += set.reps;
      }
    }
    return reps;
  }

  /// Calculates total volume and set counts broken down by primary muscle group.
  static Map<String, MuscleVolumeStats> calculateMuscleDistribution(
    List<ActiveSessionExercise> sessionExercises,
  ) {
    final Map<String, MuscleVolumeStats> distribution = {};

    for (final se in sessionExercises) {
      final muscle = se.exercise.primaryMuscle;
      double vol = 0.0;
      int completedSets = 0;

      for (final s in se.sets) {
        if (s.isCompleted) {
          completedSets++;
          if (s.weight > 0 && s.reps > 0) {
            vol += (s.weight * s.reps);
          }
        }
      }

      if (distribution.containsKey(muscle)) {
        final existing = distribution[muscle]!;
        distribution[muscle] = MuscleVolumeStats(
          muscleName: muscle,
          totalVolume: existing.totalVolume + vol,
          completedSets: existing.completedSets + completedSets,
        );
      } else {
        distribution[muscle] = MuscleVolumeStats(
          muscleName: muscle,
          totalVolume: vol,
          completedSets: completedSets,
        );
      }
    }

    return distribution;
  }

  /// Detects personal records (max weight, max reps, max 1RM) comparing current sets against historical sets.
  static List<PersonalRecord> detectPersonalRecords({
    required Exercise exercise,
    required List<WorkoutSet> currentSets,
    required List<WorkoutSet> historicalSets,
  }) {
    final List<PersonalRecord> prs = [];

    // Find historical bests
    double historicalMaxWeight = 0.0;
    double historicalMax1RM = 0.0;

    for (final s in historicalSets) {
      if (s.isCompleted) {
        final w = s.weight;
        final r = s.reps;
        if (w > historicalMaxWeight) {
          historicalMaxWeight = w;
        }
        final e1rm = calculateEstimated1RM(w, r);
        if (e1rm > historicalMax1RM) {
          historicalMax1RM = e1rm;
        }
      }
    }

    // Check current completed sets
    double currentMaxWeight = 0.0;
    double currentMax1RM = 0.0;
    int currentBestRepsForMaxWeight = 0;

    for (final s in currentSets) {
      if (s.isCompleted) {
        final w = s.weight;
        final r = s.reps;
        if (w > currentMaxWeight) {
          currentMaxWeight = w;
          currentBestRepsForMaxWeight = r;
        }
        final e1rm = calculateEstimated1RM(w, r);
        if (e1rm > currentMax1RM) {
          currentMax1RM = e1rm;
        }
      }
    }

    // If current max weight beat historical (and weight > 0)
    if (currentMaxWeight > historicalMaxWeight && currentMaxWeight > 0) {
      prs.add(PersonalRecord(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        type: PRType.maxWeight,
        value: currentMaxWeight,
        previousValue: historicalMaxWeight > 0 ? historicalMaxWeight : null,
        reps: currentBestRepsForMaxWeight,
      ));
    }

    // If current estimated 1RM beat historical
    if (currentMax1RM > historicalMax1RM && currentMax1RM > 0) {
      prs.add(PersonalRecord(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        type: PRType.estimated1RM,
        value: currentMax1RM,
        previousValue: historicalMax1RM > 0 ? historicalMax1RM : null,
      ));
    }

    return prs;
  }

  /// Formats duration into standard mm:ss or hh:mm:ss format.
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Formats weight with unit (e.g. "100 kg" or "100.5 kg").
  static String formatWeight(double? weight, {String unit = 'kg'}) {
    if (weight == null || weight <= 0) return 'BW';
    if (weight == weight.roundToDouble()) {
      return '${weight.toInt()} $unit';
    }
    return '${weight.toStringAsFixed(1)} $unit';
  }
}
