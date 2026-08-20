import 'package:drift/drift.dart';
import '../database/app_database.dart';

class SessionExerciseWithDetails {
  SessionExerciseWithDetails({
    required this.sessionExercise,
    required this.exercise,
    required this.sets,
  });

  final SessionExercise sessionExercise;
  final Exercise exercise;
  final List<WorkoutSet> sets;
}

class WorkoutSessionDetails {
  WorkoutSessionDetails({
    required this.session,
    required this.exercises,
  });

  final WorkoutSession session;
  final List<SessionExerciseWithDetails> exercises;
}

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  Future<void> createSession(WorkoutSessionsCompanion session) {
    return _db.into(_db.workoutSessions).insert(session);
  }

  Future<WorkoutSession?> getSessionById(String id) {
    return (_db.select(_db.workoutSessions)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<WorkoutSession>> getAllSessions() {
    return (_db.select(_db.workoutSessions)
          ..orderBy([
            (tbl) => OrderingTerm(
                  expression: tbl.dateStarted,
                  mode: OrderingMode.desc,
                )
          ]))
        .get();
  }

  Future<void> completeSession(
    String sessionId, {
    DateTime? dateEnded,
    String? notes,
    String? aiSummary,
  }) async {
    final companion = WorkoutSessionsCompanion(
      dateEnded: Value(dateEnded ?? DateTime.now()),
      notes: notes != null ? Value(notes) : const Value.absent(),
      aiSummary: aiSummary != null ? Value(aiSummary) : const Value.absent(),
    );
    await (_db.update(_db.workoutSessions)
          ..where((tbl) => tbl.id.equals(sessionId)))
        .write(companion);
  }

  Future<int> deleteSession(String sessionId) {
    return (_db.delete(_db.workoutSessions)
          ..where((tbl) => tbl.id.equals(sessionId)))
        .go();
  }

  Future<void> addExerciseToSession(
      SessionExercisesCompanion sessionExercise) {
    return _db.into(_db.sessionExercises).insert(sessionExercise);
  }

  Future<List<SessionExercise>> getSessionExercises(String sessionId) {
    return (_db.select(_db.sessionExercises)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.orderInSession)]))
        .get();
  }

  Future<int> deleteSessionExercise(String sessionExerciseId) {
    return (_db.delete(_db.sessionExercises)
          ..where((tbl) => tbl.id.equals(sessionExerciseId)))
        .go();
  }

  Future<void> addSet(WorkoutSetsCompanion set) {
    return _db.into(_db.workoutSets).insert(set);
  }

  Future<List<WorkoutSet>> getSetsForSessionExercise(
      String sessionExerciseId) {
    return (_db.select(_db.workoutSets)
          ..where((tbl) => tbl.sessionExerciseId.equals(sessionExerciseId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.setNumber)]))
        .get();
  }

  Future<void> updateSet(WorkoutSetsCompanion set) {
    return _db.update(_db.workoutSets).replace(set);
  }

  Future<int> deleteSet(String setId) {
    return (_db.delete(_db.workoutSets)..where((tbl) => tbl.id.equals(setId)))
        .go();
  }

  Future<WorkoutSessionDetails?> getFullSessionDetails(
      String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return null;

    final sessionExercisesList = await (_db.select(_db.sessionExercises)
          ..where((tbl) => tbl.sessionId.equals(sessionId))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.orderInSession)]))
        .get();

    final exercisesWithDetails = <SessionExerciseWithDetails>[];
    for (final se in sessionExercisesList) {
      final exercise = await (_db.select(_db.exercises)
            ..where((tbl) => tbl.id.equals(se.exerciseId)))
          .getSingle();

      final sets = await (_db.select(_db.workoutSets)
            ..where((tbl) => tbl.sessionExerciseId.equals(se.id))
            ..orderBy([(tbl) => OrderingTerm.asc(tbl.setNumber)]))
          .get();

      exercisesWithDetails.add(
        SessionExerciseWithDetails(
          sessionExercise: se,
          exercise: exercise,
          sets: sets,
        ),
      );
    }

    return WorkoutSessionDetails(
      session: session,
      exercises: exercisesWithDetails,
    );
  }
}
