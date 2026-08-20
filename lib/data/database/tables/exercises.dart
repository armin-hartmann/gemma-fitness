import 'package:drift/drift.dart';

@DataClassName('Exercise')
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get category => text()();
  TextColumn get primaryMuscle => text()();
  TextColumn get equipment => text()();
  TextColumn get instructions => text().nullable()();
  TextColumn get defaultPhase => text().withDefault(const Constant('working'))();
  BoolColumn get requiresEquipment =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
