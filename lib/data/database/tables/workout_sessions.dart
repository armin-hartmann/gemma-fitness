import 'package:drift/drift.dart';

@DataClassName('WorkoutSession')
class WorkoutSessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get dateStarted => dateTime()();
  DateTimeColumn get dateEnded => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get aiSummary => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
