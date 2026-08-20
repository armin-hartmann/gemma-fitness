enum SetType {
  warmup,
  normal,
  dropSet,
  failure;

  String get displayName {
    switch (this) {
      case SetType.warmup:
        return 'Warm-up';
      case SetType.normal:
        return 'Normal';
      case SetType.dropSet:
        return 'Drop Set';
      case SetType.failure:
        return 'Failure';
    }
  }

  static SetType fromString(String value) {
    return SetType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SetType.normal,
    );
  }
}
