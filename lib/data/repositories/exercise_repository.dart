import '../database/app_database.dart';

class ExerciseRepository {
  ExerciseRepository(this._db);

  final AppDatabase _db;

  Future<List<Exercise>> getAllExercises() {
    return _db.select(_db.exercises).get();
  }

  Future<Exercise?> getExerciseById(String id) {
    return (_db.select(_db.exercises)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
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

  Future<void> bulkUpsertExercises(List<ExercisesCompanion> exercisesList) {
    return _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.exercises, exercisesList);
    });
  }

  Stream<List<Exercise>> watchAllExercises() {
    return _db.select(_db.exercises).watch();
  }
}
