import 'package:drift/drift.dart';
import 'exercises.dart';
import 'workout_sessions.dart';

@DataClassName('SessionExercise')
class SessionExercises extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(
        WorkoutSessions,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get exerciseId => text().references(
        Exercises,
        #id,
        onDelete: KeyAction.restrict,
      )();
  TextColumn get phase => text().withDefault(const Constant('working'))();
  IntColumn get orderInSession => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
