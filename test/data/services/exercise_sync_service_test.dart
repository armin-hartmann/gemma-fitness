import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/database/app_database.dart';
import 'package:gemma_fitness/data/repositories/exercise_repository.dart';
import 'package:gemma_fitness/data/services/exercise_sync_service.dart';

void main() {
  late AppDatabase db;
  late ExerciseRepository repo;
  late ExerciseSyncService syncService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExerciseRepository(db);
    syncService = ExerciseSyncService(exerciseRepository: repo);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExerciseSyncService', () {
    test('Seeds database when empty and does not re-seed when populated', () async {
      final seededCount = await syncService.seedInitialExercisesIfEmpty();
      expect(seededCount, greaterThanOrEqualTo(20));

      final all = await repo.getAllExercises();
      expect(all.length, seededCount);

      // Subsequent call should do nothing
      final secondCall = await syncService.seedInitialExercisesIfEmpty();
      expect(secondCall, 0);
    });

    test('Can export and re-import exercises via JSON', () async {
      await syncService.seedInitialExercisesIfEmpty();

      final jsonString = await syncService.exportExercisesToJson();
      expect(jsonString, contains('Barbell Bench Press'));
      expect(jsonString, contains('World\'s Greatest Stretch'));

      // Close original db before creating a fresh database
      await db.close();

      final freshDb = AppDatabase.forTesting(NativeDatabase.memory());
      final freshRepo = ExerciseRepository(freshDb);
      final freshSync = ExerciseSyncService(exerciseRepository: freshRepo);

      final importedCount = await freshSync.importExercisesFromJson(jsonString);
      expect(importedCount, greaterThanOrEqualTo(20));

      final importedExercises = await freshRepo.getAllExercises();
      expect(importedExercises.length, importedCount);

      await freshDb.close();
    });
  });
}
