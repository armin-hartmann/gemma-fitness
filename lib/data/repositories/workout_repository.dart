import 'package:drift/drift.dart';
import '../../domain/models/active_workout_models.dart';
import '../database/app_database.dart';

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  // SESSIONS
  Future<void> insertSession(WorkoutSessionsCompanion session) {
    return _db.into(_db.workoutSessions).insert(session);
  }

  Future<void> createSession(WorkoutSessionsCompanion session) =>
      insertSession(session);

  Future<WorkoutSession?> getSessionById(String id) {
    return (_db.select(_db.workoutSessions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<WorkoutSession>> getAllSessions() {
    return (_db.select(_db.workoutSessions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.dateStarted, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<List<WorkoutSession>> getCompletedSessions() {
    return (_db.select(_db.workoutSessions)
          ..where((tbl) => tbl.dateEnded.isNotNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.dateStarted, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<WorkoutSession?> getActiveUnfinishedSession() {
    return (_db.select(_db.workoutSessions)
          ..where((tbl) => tbl.dateEnded.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.dateStarted, mode: OrderingMode.desc),
          ]))
        .getSingleOrNull();
  }

  Future<void> updateSession(WorkoutSessionsCompanion session) {
    return _db.update(_db.workoutSessions).replace(session);
  }

  Future<void> completeSession(
    String sessionId, {
    DateTime? dateEnded,
    String? notes,
    String? aiSummary,
  }) {
    final ended = dateEnded ?? DateTime.now();
    return (_db.update(_db.workoutSessions)..where((tbl) => tbl.id.equals(sessionId)))
        .write(
      WorkoutSessionsCompanion(
        dateEnded: Value(ended),
        notes: notes != null ? Value(notes) : const Value.absent(),
        aiSummary: aiSummary != null ? Value(aiSummary) : const Value.absent(),
      ),
    );
  }

  Future<int> deleteSession(String id) {
    return (_db.delete(_db.workoutSessions)..where((tbl) => tbl.id.equals(id))).go();
  }

  // FULL SESSION WITH RELATIONS
  Future<ActiveWorkoutSession?> getFullActiveSession(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return null;

    final sessionExercises = await (_db.select(_db.sessionExercises)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderInSession)]))
        .get();

    final List<ActiveSessionExercise> activeExercises = [];

    for (final se in sessionExercises) {
      final exercise = await (_db.select(_db.exercises)
            ..where((tbl) => tbl.id.equals(se.exerciseId)))
          .getSingleOrNull();

      if (exercise != null) {
        final sets = await (_db.select(_db.workoutSets)
              ..where((tbl) => tbl.sessionExerciseId.equals(se.id))
              ..orderBy([(t) => OrderingTerm(expression: t.setNumber)]))
            .get();

        activeExercises.add(
          ActiveSessionExercise(
            sessionExercise: se,
            exercise: exercise,
            sets: sets,
          ),
        );
      }
    }

    return ActiveWorkoutSession(
      session: session,
      exercises: activeExercises,
    );
  }

  Future<ActiveWorkoutSession?> getFullSessionDetails(String sessionId) =>
      getFullActiveSession(sessionId);

  // SESSION EXERCISES
  Future<void> insertSessionExercise(SessionExercisesCompanion sessionExercise) {
    return _db.into(_db.sessionExercises).insert(sessionExercise);
  }

  Future<void> addExerciseToSession(SessionExercisesCompanion sessionExercise) =>
      insertSessionExercise(sessionExercise);

  Future<List<SessionExercise>> getSessionExercises(String sessionId) {
    return (_db.select(_db.sessionExercises)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderInSession)]))
        .get();
  }

  Future<void> updateSessionExercisePhase(String id, String phase) {
    return (_db.update(_db.sessionExercises)..where((tbl) => tbl.id.equals(id)))
        .write(SessionExercisesCompanion(phase: Value(phase)));
  }

  Future<int> deleteSessionExercise(String id) {
    return (_db.delete(_db.sessionExercises)..where((tbl) => tbl.id.equals(id))).go();
  }

  // SETS
  Future<void> insertWorkoutSet(WorkoutSetsCompanion set) {
    return _db.into(_db.workoutSets).insert(set);
  }

  Future<void> addSet(WorkoutSetsCompanion set) => insertWorkoutSet(set);

  Future<void> updateWorkoutSet(WorkoutSetsCompanion set) {
    return _db.update(_db.workoutSets).replace(set);
  }

  Future<void> updateSet(WorkoutSetsCompanion set) => updateWorkoutSet(set);

  Future<List<WorkoutSet>> getSetsForSessionExercise(String sessionExerciseId) {
    return (_db.select(_db.workoutSets)
          ..where((tbl) => tbl.sessionExerciseId.equals(sessionExerciseId))
          ..orderBy([(t) => OrderingTerm(expression: t.setNumber)]))
        .get();
  }

  Future<int> deleteWorkoutSet(String id) {
    return (_db.delete(_db.workoutSets)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> deleteSet(String id) => deleteWorkoutSet(id);

  /// Retrieves all historical sets logged across all sessions for a specific exercise ID.
  Future<List<WorkoutSet>> getHistoricalSetsForExercise(String exerciseId) async {
    final query = _db.select(_db.workoutSets).join([
      innerJoin(
        _db.sessionExercises,
        _db.sessionExercises.id.equalsExp(_db.workoutSets.sessionExerciseId),
      ),
    ])
      ..where(_db.sessionExercises.exerciseId.equals(exerciseId));

    final rows = await query.get();
    return rows.map((r) => r.readTable(_db.workoutSets)).toList();
  }
}
