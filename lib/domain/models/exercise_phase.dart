enum ExercisePhase {
  warmup,
  working,
  cooldown,
  versatile;

  String get displayName {
    switch (this) {
      case ExercisePhase.warmup:
        return 'Warm-up';
      case ExercisePhase.working:
        return 'Working';
      case ExercisePhase.cooldown:
        return 'Cool-down';
      case ExercisePhase.versatile:
        return 'Versatile';
    }
  }

  static ExercisePhase fromString(String value) {
    return ExercisePhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExercisePhase.working,
    );
  }
}
