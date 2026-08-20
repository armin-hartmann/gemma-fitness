import 'package:drift/drift.dart';
import 'session_exercises.dart';

@DataClassName('WorkoutSet')
class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionExerciseId => text().references(
        SessionExercises,
        #id,
        onDelete: KeyAction.cascade,
      )();
  IntColumn get setNumber => integer()();
  TextColumn get setType => text().withDefault(const Constant('normal'))();
  RealColumn get weight => real().withDefault(const Constant(0.0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
