import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/database/app_database.dart';
import 'package:gemma_fitness/data/repositories/exercise_repository.dart';
import 'package:gemma_fitness/data/repositories/workout_repository.dart';
import 'package:gemma_fitness/data/repositories/workout_template_repository.dart';
import 'package:gemma_fitness/data/services/exercise_sync_service.dart';
import 'package:gemma_fitness/data/services/gemini_exercise_service.dart';
import 'package:gemma_fitness/data/services/gemini_workout_service.dart';
import 'package:gemma_fitness/main.dart';
import 'package:gemma_fitness/ui/features/exercise_admin/view_models/exercise_admin_view_model.dart';
import 'package:gemma_fitness/ui/features/workout_tracker/view_models/active_workout_view_model.dart';
import 'package:gemma_fitness/ui/features/workout_tracker/view_models/workout_history_view_model.dart';
import 'package:gemma_fitness/ui/features/workout_tracker/view_models/workout_templates_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('GemmaFitnessApp smoke test and master exercise screen rendering',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final exerciseRepo = ExerciseRepository(db);
    final workoutRepo = WorkoutRepository(db);
    final templateRepo = WorkoutTemplateRepository();
    final syncService = ExerciseSyncService(exerciseRepository: exerciseRepo);
    final geminiExerciseService = GeminiExerciseService(apiKey: 'test');
    final geminiWorkoutService = GeminiWorkoutService(apiKey: 'test');

    final adminViewModel = ExerciseAdminViewModel(
      exerciseRepository: exerciseRepo,
      syncService: syncService,
      geminiService: geminiExerciseService,
    );

    final activeWorkoutViewModel = ActiveWorkoutViewModel(
      workoutRepository: workoutRepo,
      exerciseRepository: exerciseRepo,
    );

    final historyViewModel = WorkoutHistoryViewModel(
      workoutRepository: workoutRepo,
    );

    final templatesViewModel = WorkoutTemplatesViewModel(
      templateRepository: templateRepo,
    );

    await tester.pumpWidget(GemmaFitnessApp(
      exerciseAdminViewModel: adminViewModel,
      activeWorkoutViewModel: activeWorkoutViewModel,
      workoutHistoryViewModel: historyViewModel,
      workoutTemplatesViewModel: templatesViewModel,
      exerciseRepository: exerciseRepo,
      database: db,
      workoutRepository: workoutRepo,
      aiService: geminiWorkoutService,
    ));

    await tester.pumpAndSettle();

    // Verify initial Workout tab is rendered with AI generator and routines
    expect(find.text('Ready to Train?'), findsOneWidget);
    expect(find.text('AI Routine Generator'), findsOneWidget);
    expect(find.text('Workout Routines'), findsOneWidget);

    await db.close();
  });
}
