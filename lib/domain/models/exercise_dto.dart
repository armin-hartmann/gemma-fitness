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
    bool? requiresEquipment,
  }) : requiresEquipment =
            requiresEquipment ?? (equipment.trim().toLowerCase() != 'bodyweight');

  final String? id;
  final String name;
  final String category;
  final String primaryMuscle;
  final String equipment;
  final String? instructions;
  final String defaultPhase;
  final bool requiresEquipment;

  factory ExerciseDto.fromJson(Map<String, dynamic> json) {
    final equip = json['equipment'] as String? ?? 'Bodyweight';
    final explicitReq = json['requires_equipment'] as bool? ??
        json['requiresEquipment'] as bool?;

    return ExerciseDto(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Unnamed Exercise',
      category: json['category'] as String? ?? 'Strength',
      primaryMuscle: json['primary_muscle'] as String? ??
          json['primaryMuscle'] as String? ??
          'Full Body',
      equipment: equip,
      instructions: json['instructions'] as String?,
      defaultPhase: json['default_phase'] as String? ??
          json['defaultPhase'] as String? ??
          'working',
      requiresEquipment: explicitReq ?? (equip.trim().toLowerCase() != 'bodyweight'),
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
      requiresEquipment: exercise.requiresEquipment,
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
      'requires_equipment': requiresEquipment,
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
      requiresEquipment: Value(requiresEquipment),
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
    bool? requiresEquipment,
  }) {
    return ExerciseDto(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
      defaultPhase: defaultPhase ?? this.defaultPhase,
      requiresEquipment: requiresEquipment ?? this.requiresEquipment,
    );
  }
}
