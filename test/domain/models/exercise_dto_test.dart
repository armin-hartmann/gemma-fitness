import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/domain/models/exercise_dto.dart';

void main() {
  group('ExerciseDto', () {
    test('Can serialize and deserialize from JSON', () {
      final json = {
        'id': 'ex-123',
        'name': 'Incline Dumbbell Press',
        'category': 'Hypertrophy',
        'primary_muscle': 'Upper Chest',
        'equipment': 'Dumbbell',
        'instructions': 'Press up at 30 degrees angle.',
        'default_phase': 'working',
      };

      final dto = ExerciseDto.fromJson(json);
      expect(dto.id, 'ex-123');
      expect(dto.name, 'Incline Dumbbell Press');
      expect(dto.category, 'Hypertrophy');
      expect(dto.primaryMuscle, 'Upper Chest');
      expect(dto.equipment, 'Dumbbell');
      expect(dto.instructions, 'Press up at 30 degrees angle.');
      expect(dto.defaultPhase, 'working');
      expect(dto.requiresEquipment, isTrue);

      final serialized = dto.toJson();
      expect(serialized['id'], 'ex-123');
      expect(serialized['name'], 'Incline Dumbbell Press');
      expect(serialized['primary_muscle'], 'Upper Chest');
      expect(serialized['requires_equipment'], isTrue);
    });

    test('Can convert to ExercisesCompanion with fallback UUID and auto-detects bodyweight requiresEquipment as false', () {
      final dto = ExerciseDto(
        name: 'Pull-up',
        category: 'Strength',
        primaryMuscle: 'Lats',
        equipment: 'Bodyweight',
        defaultPhase: 'working',
      );

      expect(dto.requiresEquipment, isFalse);

      final companion = dto.toCompanion();
      expect(companion.id.present, isTrue);
      expect(companion.name.value, 'Pull-up');
      expect(companion.primaryMuscle.value, 'Lats');
      expect(companion.defaultPhase.value, 'working');
      expect(companion.requiresEquipment.value, isFalse);
    });
  });
}
