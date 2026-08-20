import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../data/database/app_database.dart';

class ExerciseDto {
  ExerciseDto({
    this.id,
    required this.name,
    required this.category,
    required this.primaryMuscle,
    required this.equipment,
    this.instructions,
    this.defaultPhase = 'working',
  });

  final String? id;
  final String name;
  final String category;
  final String primaryMuscle;
  final String equipment;
  final String? instructions;
  final String defaultPhase;

  factory ExerciseDto.fromJson(Map<String, dynamic> json) {
    return ExerciseDto(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Unnamed Exercise',
      category: json['category'] as String? ?? 'Strength',
      primaryMuscle: json['primary_muscle'] as String? ??
          json['primaryMuscle'] as String? ??
          'Full Body',
      equipment: json['equipment'] as String? ?? 'Bodyweight',
      instructions: json['instructions'] as String?,
      defaultPhase: json['default_phase'] as String? ??
          json['defaultPhase'] as String? ??
          'working',
    );
  }

  factory ExerciseDto.fromExercise(Exercise exercise) {
    return ExerciseDto(
      id: exercise.id,
      name: exercise.name,
      category: exercise.category,
      primaryMuscle: exercise.primaryMuscle,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      defaultPhase: exercise.defaultPhase,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'primary_muscle': primaryMuscle,
      'equipment': equipment,
      'instructions': instructions,
      'default_phase': defaultPhase,
    };
  }

  ExercisesCompanion toCompanion({String? fallbackId}) {
    const uuid = Uuid();
    return ExercisesCompanion(
      id: Value(id ?? fallbackId ?? uuid.v4()),
      name: Value(name),
      category: Value(category),
      primaryMuscle: Value(primaryMuscle),
      equipment: Value(equipment),
      instructions: Value(instructions),
      defaultPhase: Value(defaultPhase),
    );
  }

  ExerciseDto copyWith({
    String? id,
    String? name,
    String? category,
    String? primaryMuscle,
    String? equipment,
    String? instructions,
    String? defaultPhase,
  }) {
    return ExerciseDto(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
      defaultPhase: defaultPhase ?? this.defaultPhase,
    );
  }
}
