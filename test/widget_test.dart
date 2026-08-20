import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/database/app_database.dart';
import 'package:gemma_fitness/data/repositories/exercise_repository.dart';
import 'package:gemma_fitness/data/repositories/workout_repository.dart';
import 'package:gemma_fitness/data/services/exercise_sync_service.dart';
import 'package:gemma_fitness/data/services/gemini_exercise_service.dart';
import 'package:gemma_fitness/main.dart';
import 'package:gemma_fitness/ui/features/exercise_admin/view_models/exercise_admin_view_model.dart';

void main() {
  testWidgets('GemmaFitnessApp smoke test and master exercise screen rendering',
      (WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final exerciseRepo = ExerciseRepository(db);
    final workoutRepo = WorkoutRepository(db);
    final syncService = ExerciseSyncService(exerciseRepository: exerciseRepo);
    final geminiService = GeminiExerciseService(apiKey: 'test');

    final viewModel = ExerciseAdminViewModel(
      exerciseRepository: exerciseRepo,
      syncService: syncService,
      geminiService: geminiService,
    );

    await tester.pumpWidget(GemmaFitnessApp(
      viewModel: viewModel,
      database: db,
      workoutRepository: workoutRepo,
    ));

    await tester.pumpAndSettle();

    expect(find.text('Gemma Fitness'), findsOneWidget);
    expect(find.text('Master Exercise Library & Cloud Ingestion'), findsOneWidget);
    expect(find.text('AI Ingest (Gemini)'), findsOneWidget);
    expect(find.text('New Exercise'), findsOneWidget);

    await db.close();
  });
}
