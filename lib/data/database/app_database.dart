import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/exercises.dart';
import 'tables/session_exercises.dart';
import 'tables/workout_sessions.dart';
import 'tables/workout_sets.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    WorkoutSessions,
    SessionExercises,
    WorkoutSets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  AppDatabase.forConnection(super.connection);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(exercises, exercises.requiresEquipment);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'gemma_fitness',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
