import '../../data/database/app_database.dart';

enum PRType {
  maxWeight,
  maxReps,
  estimated1RM,
  volumeRecord,
}

class PersonalRecord {
  const PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.type,
    required this.value,
    this.previousValue,
    this.reps,
  });

  final String exerciseId;
  final String exerciseName;
  final PRType type;
  final double value;
  final double? previousValue;
  final int? reps;

  String get formattedMessage {
    switch (type) {
      case PRType.maxWeight:
        final valStr =
            value == value.roundToDouble() ? '${value.toInt()}' : value.toStringAsFixed(1);
        return '🏆 New Max Weight: $valStr kg ($reps reps)!';
      case PRType.estimated1RM:
        return '🔥 New Est. 1RM: ${value.toStringAsFixed(1)} kg!';
      case PRType.maxReps:
        return '⚡ New Max Reps: ${value.toInt()} reps!';
      case PRType.volumeRecord:
        return '💪 New Volume Record: ${value.toStringAsFixed(0)} kg!';
    }
  }
}

class MuscleVolumeStats {
  const MuscleVolumeStats({
    required this.muscleName,
    required this.totalVolume,
    required this.completedSets,
  });

  final String muscleName;
  final double totalVolume;
  final int completedSets;
}

class ActiveSessionExercise {
  ActiveSessionExercise({
    required this.sessionExercise,
    required this.exercise,
    required this.sets,
  });

  final SessionExercise sessionExercise;
  final Exercise exercise;
  final List<WorkoutSet> sets;

  ActiveSessionExercise copyWith({
    SessionExercise? sessionExercise,
    Exercise? exercise,
    List<WorkoutSet>? sets,
  }) {
    return ActiveSessionExercise(
      sessionExercise: sessionExercise ?? this.sessionExercise,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
    );
  }
}

class ActiveWorkoutSession {
  ActiveWorkoutSession({
    required this.session,
    required this.exercises,
  });

  final WorkoutSession session;
  final List<ActiveSessionExercise> exercises;

  List<ActiveSessionExercise> get warmupExercises =>
      exercises.where((e) => e.sessionExercise.phase == 'warmup').toList();

  List<ActiveSessionExercise> get workingExercises =>
      exercises.where((e) => e.sessionExercise.phase == 'working').toList();

  List<ActiveSessionExercise> get cooldownExercises =>
      exercises.where((e) => e.sessionExercise.phase == 'cooldown').toList();

  List<WorkoutSet> get allSets =>
      exercises.expand((e) => e.sets).toList();

  int get totalCompletedSets =>
      allSets.where((s) => s.isCompleted).length;

  int get totalSets => allSets.length;

  double get totalVolume => allSets
      .where((s) => s.isCompleted && s.weight > 0 && s.reps > 0)
      .fold(0.0, (acc, s) => acc + (s.weight * s.reps));
}

class WorkoutPreset {
  const WorkoutPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.modality,
    required this.exercisePhases,
    this.iconName = 'fitness_center',
    this.isCustom = false,
  });

  final String id;
  final String title;
  final String description;
  final String modality; // 'bodyweight', 'free_weights', 'hybrid', 'machines'
  final List<PresetExerciseItem> exercisePhases;
  final String iconName;
  final bool isCustom;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'modality': modality,
      'icon_name': iconName,
      'is_custom': isCustom,
      'exercise_phases': exercisePhases.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutPreset.fromJson(Map<String, dynamic> json) {
    final exercisesJson = json['exercise_phases'] as List? ?? [];
    return WorkoutPreset(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Routine',
      description: json['description'] as String? ?? '',
      modality: json['modality'] as String? ?? 'free_weights',
      iconName: json['icon_name'] as String? ?? 'fitness_center',
      isCustom: json['is_custom'] as bool? ?? true,
      exercisePhases: exercisesJson
          .whereType<Map<String, dynamic>>()
          .map(PresetExerciseItem.fromJson)
          .toList(),
    );
  }

  WorkoutPreset copyWith({
    String? id,
    String? title,
    String? description,
    String? modality,
    List<PresetExerciseItem>? exercisePhases,
    String? iconName,
    bool? isCustom,
  }) {
    return WorkoutPreset(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      modality: modality ?? this.modality,
      exercisePhases: exercisePhases ?? this.exercisePhases,
      iconName: iconName ?? this.iconName,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  static List<WorkoutPreset> getStandardPresets() {
    return [
      const WorkoutPreset(
        id: 'preset-home-bw',
        title: '🏠 Home Zero-Equipment Routine',
        description:
            'Full-body mobility warm-up, core & bodyweight strength, and restorative cool-down stretches.',
        modality: 'bodyweight',
        iconName: 'home',
        isCustom: false,
        exercisePhases: [
          PresetExerciseItem(
            exerciseName: 'World\'s Greatest Stretch',
            phase: 'warmup',
            targetSets: 2,
            targetReps: 8,
          ),
          PresetExerciseItem(
            exerciseName: 'Cat-Cow Stretch',
            phase: 'warmup',
            targetSets: 2,
            targetReps: 10,
          ),
          PresetExerciseItem(
            exerciseName: 'Standard Push-Up',
            phase: 'working',
            targetSets: 3,
            targetReps: 12,
            targetRpe: 8.0,
          ),
          PresetExerciseItem(
            exerciseName: 'Bodyweight Walking Lunges',
            phase: 'working',
            targetSets: 3,
            targetReps: 15,
            targetRpe: 8.0,
          ),
          PresetExerciseItem(
            exerciseName: 'Plank Hold',
            phase: 'working',
            targetSets: 3,
            targetReps: 45,
            targetRpe: 8.5,
          ),
          PresetExerciseItem(
            exerciseName: 'Pigeon Pose / Glute Stretch',
            phase: 'cooldown',
            targetSets: 2,
            targetReps: 30,
          ),
        ],
      ),
      const WorkoutPreset(
        id: 'preset-fw-upper',
        title: '🏋️ Free-Weight Upper Body Push/Pull',
        description:
            'Barbells & dumbbells focusing on chest, lats, shoulders, and arms with mobility activation.',
        modality: 'free_weights',
        iconName: 'fitness_center',
        isCustom: false,
        exercisePhases: [
          PresetExerciseItem(
            exerciseName: 'Band Pull-Aparts',
            phase: 'warmup',
            targetSets: 2,
            targetReps: 15,
          ),
          PresetExerciseItem(
            exerciseName: 'Barbell Bench Press',
            phase: 'working',
            targetSets: 4,
            targetReps: 8,
            targetWeight: 60.0,
            targetRpe: 8.0,
          ),
          PresetExerciseItem(
            exerciseName: 'Barbell Bent-Over Row',
            phase: 'working',
            targetSets: 4,
            targetReps: 8,
            targetWeight: 50.0,
            targetRpe: 8.0,
          ),
          PresetExerciseItem(
            exerciseName: 'Incline Dumbbell Press',
            phase: 'working',
            targetSets: 3,
            targetReps: 10,
            targetWeight: 22.0,
            targetRpe: 8.5,
          ),
          PresetExerciseItem(
            exerciseName: 'Dumbbell Lateral Raise',
            phase: 'working',
            targetSets: 3,
            targetReps: 12,
            targetWeight: 10.0,
            targetRpe: 9.0,
          ),
          PresetExerciseItem(
            exerciseName: 'Doorway Chest & Bicep Stretch',
            phase: 'cooldown',
            targetSets: 2,
            targetReps: 30,
          ),
        ],
      ),
      const WorkoutPreset(
        id: 'preset-fw-lower',
        title: '🏋️ Free-Weight Lower Body Power',
        description:
            'Barbell squats, Romanian deadlifts, and unilateral Bulgarian split squats.',
        modality: 'free_weights',
        iconName: 'directions_run',
        isCustom: false,
        exercisePhases: [
          PresetExerciseItem(
            exerciseName: 'Bodyweight Squats',
            phase: 'warmup',
            targetSets: 2,
            targetReps: 15,
          ),
          PresetExerciseItem(
            exerciseName: 'Barbell Back Squat',
            phase: 'working',
            targetSets: 4,
            targetReps: 6,
            targetWeight: 80.0,
            targetRpe: 8.5,
          ),
          PresetExerciseItem(
            exerciseName: 'Romanian Deadlift (RDL)',
            phase: 'working',
            targetSets: 3,
            targetReps: 8,
            targetWeight: 70.0,
            targetRpe: 8.0,
          ),
          PresetExerciseItem(
            exerciseName: 'Dumbbell Bulgarian Split Squat',
            phase: 'working',
            targetSets: 3,
            targetReps: 10,
            targetWeight: 16.0,
            targetRpe: 9.0,
          ),
          PresetExerciseItem(
            exerciseName: 'Standing Quad & Hip Flexor Stretch',
            phase: 'cooldown',
            targetSets: 2,
            targetReps: 30,
          ),
        ],
      ),
    ];
  }
}

class PresetExerciseItem {
  const PresetExerciseItem({
    required this.exerciseName,
    required this.phase,
    required this.targetSets,
    required this.targetReps,
    this.targetWeight,
    this.targetRpe,
  });

  final String exerciseName;
  final String phase; // 'warmup', 'working', 'cooldown'
  final int targetSets;
  final int targetReps;
  final double? targetWeight;
  final double? targetRpe;

  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      'phase': phase,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'target_rpe': targetRpe,
    };
  }

  factory PresetExerciseItem.fromJson(Map<String, dynamic> json) {
    final rawWeight = json['target_weight'];
    final rawRpe = json['target_rpe'];
    return PresetExerciseItem(
      exerciseName: json['exercise_name'] as String? ?? 'Exercise',
      phase: json['phase'] as String? ?? 'working',
      targetSets: json['target_sets'] as int? ?? 3,
      targetReps: json['target_reps'] as int? ?? 10,
      targetWeight: rawWeight is num ? rawWeight.toDouble() : null,
      targetRpe: rawRpe is num ? rawRpe.toDouble() : null,
    );
  }

  PresetExerciseItem copyWith({
    String? exerciseName,
    String? phase,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    double? targetRpe,
  }) {
    return PresetExerciseItem(
      exerciseName: exerciseName ?? this.exerciseName,
      phase: phase ?? this.phase,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetRpe: targetRpe ?? this.targetRpe,
    );
  }
}
