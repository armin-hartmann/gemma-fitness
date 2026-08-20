import 'package:drift/drift.dart';
import '../database/app_database.dart';

class ExerciseRepository {
  ExerciseRepository(this._db);

  final AppDatabase _db;

  /// Normalizes an exercise name for deduplication (case-insensitive, trimmed).
  static String normalizeName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<List<Exercise>> getAllExercises() {
    return _db.select(_db.exercises).get();
  }

  Future<Exercise?> getExerciseById(String id) {
    return (_db.select(_db.exercises)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Exercise?> getExerciseByName(String name) async {
    final normalized = normalizeName(name);
    final all = await getAllExercises();
    for (final ex in all) {
      if (normalizeName(ex.name) == normalized) {
        return ex;
      }
    }
    return null;
  }

  Future<List<Exercise>> getExercisesByPhase(String phase) {
    return (_db.select(_db.exercises)
          ..where((tbl) => tbl.defaultPhase.equals(phase)))
        .get();
  }

  Future<List<Exercise>> getExercisesByCategory(String category) {
    return (_db.select(_db.exercises)
          ..where((tbl) => tbl.category.equals(category)))
        .get();
  }

  Future<List<Exercise>> getExercisesByMuscle(String primaryMuscle) {
    return (_db.select(_db.exercises)
          ..where((tbl) => tbl.primaryMuscle.equals(primaryMuscle)))
        .get();
  }

  Future<List<Exercise>> getExercisesByEquipmentRequirement(
      bool requiresEquipment) {
    return (_db.select(_db.exercises)
          ..where((tbl) => tbl.requiresEquipment.equals(requiresEquipment)))
        .get();
  }

  Future<void> insertExercise(ExercisesCompanion exercise) {
    return _db.into(_db.exercises).insert(exercise);
  }

  Future<void> updateExercise(ExercisesCompanion exercise) {
    return _db.update(_db.exercises).replace(exercise);
  }

  Future<int> deleteExercise(String id) {
    return (_db.delete(_db.exercises)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Inserts a new exercise or updates the existing one if an exercise with the same normalized name exists.
  /// Guarantees that duplicate exercises with the same name are never created.
  Future<String> upsertExerciseByName(ExercisesCompanion exercise) async {
    final exerciseName = exercise.name.value;
    Exercise? existing;
    if (exercise.id.present) {
      existing = await getExerciseById(exercise.id.value);
    }
    existing ??= await getExerciseByName(exerciseName);

    if (existing != null) {
      final targetId = existing.id;
      final updated = ExercisesCompanion(
        id: Value(targetId),
        name: exercise.name.present ? exercise.name : Value(existing.name),
        category: exercise.category.present ? exercise.category : Value(existing.category),
        primaryMuscle: exercise.primaryMuscle.present ? exercise.primaryMuscle : Value(existing.primaryMuscle),
        equipment: exercise.equipment.present ? exercise.equipment : Value(existing.equipment),
        instructions: (exercise.instructions.present && (exercise.instructions.value?.isNotEmpty ?? false))
            ? exercise.instructions
            : Value(existing.instructions),
        defaultPhase: exercise.defaultPhase.present ? exercise.defaultPhase : Value(existing.defaultPhase),
        requiresEquipment: exercise.requiresEquipment.present
            ? exercise.requiresEquipment
            : Value(existing.requiresEquipment),
      );
      await updateExercise(updated);
      return targetId;
    } else {
      await insertExercise(exercise);
      return exercise.id.value;
    }
  }

  /// Bulk upserts a list of exercises while preventing duplicate names.
  Future<int> bulkUpsertExercises(List<ExercisesCompanion> exercisesList) async {
    int count = 0;
    for (final companion in exercisesList) {
      await upsertExerciseByName(companion);
      count++;
    }
    return count;
  }

  /// Scans the entire exercises table, identifies any duplicate exercise names,
  /// remaps any session references to the canonical record, and purges duplicate rows.
  Future<int> deduplicateExercises() async {
    final all = await getAllExercises();
    final Map<String, List<Exercise>> grouped = {};

    for (final ex in all) {
      final key = normalizeName(ex.name);
      grouped.putIfAbsent(key, () => []).add(ex);
    }

    int removedCount = 0;

    for (final entry in grouped.entries) {
      final duplicates = entry.value;
      if (duplicates.length > 1) {
        // Pick the best canonical exercise (e.g. longest instructions or non-null values)
        duplicates.sort((a, b) {
          final aInstr = a.instructions?.length ?? 0;
          final bInstr = b.instructions?.length ?? 0;
          return bInstr.compareTo(aInstr);
        });

        final canonical = duplicates.first;
        final toRemove = duplicates.sublist(1);

        for (final dup in toRemove) {
          // Remap any session_exercises referencing the duplicate to the canonical ID
          await (_db.update(_db.sessionExercises)
                ..where((tbl) => tbl.exerciseId.equals(dup.id)))
              .write(SessionExercisesCompanion(
            exerciseId: Value(canonical.id),
          ));

          // Delete the duplicate exercise row
          await (_db.delete(_db.exercises)..where((tbl) => tbl.id.equals(dup.id)))
              .go();
          removedCount++;
        }
      }
    }

    return removedCount;
  }

  Stream<List<Exercise>> watchAllExercises() {
    return _db.select(_db.exercises).watch();
  }
}
