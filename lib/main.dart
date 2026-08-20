import 'package:flutter/material.dart';
import 'data/database/app_database.dart';
import 'data/repositories/exercise_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'data/services/exercise_sync_service.dart';
import 'data/services/gemini_exercise_service.dart';
import 'data/services/settings_service.dart';
import 'ui/core/navigation/app_shell.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/exercise_admin/view_models/exercise_admin_view_model.dart';
import 'ui/features/workout_tracker/view_models/active_workout_view_model.dart';
import 'ui/features/workout_tracker/view_models/workout_history_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Core Database & Repositories
  final database = AppDatabase();
  final exerciseRepository = ExerciseRepository(database);
  final workoutRepository = WorkoutRepository(database);

  // Services
  final settingsService = SettingsService();
  final syncService = ExerciseSyncService(exerciseRepository: exerciseRepository);
  final geminiService = GeminiExerciseService(settingsService: settingsService);

  // ViewModels
  final exerciseAdminViewModel = ExerciseAdminViewModel(
    exerciseRepository: exerciseRepository,
    syncService: syncService,
    geminiService: geminiService,
    settingsService: settingsService,
  );

  final activeWorkoutViewModel = ActiveWorkoutViewModel(
    workoutRepository: workoutRepository,
    exerciseRepository: exerciseRepository,
  );

  final workoutHistoryViewModel = WorkoutHistoryViewModel(
    workoutRepository: workoutRepository,
  );

  runApp(GemmaFitnessApp(
    exerciseAdminViewModel: exerciseAdminViewModel,
    activeWorkoutViewModel: activeWorkoutViewModel,
    workoutHistoryViewModel: workoutHistoryViewModel,
    exerciseRepository: exerciseRepository,
    database: database,
    workoutRepository: workoutRepository,
  ));
}

class GemmaFitnessApp extends StatelessWidget {
  const GemmaFitnessApp({
    super.key,
    required this.exerciseAdminViewModel,
    required this.activeWorkoutViewModel,
    required this.workoutHistoryViewModel,
    required this.exerciseRepository,
    required this.database,
    required this.workoutRepository,
  });

  final ExerciseAdminViewModel exerciseAdminViewModel;
  final ActiveWorkoutViewModel activeWorkoutViewModel;
  final WorkoutHistoryViewModel workoutHistoryViewModel;
  final ExerciseRepository exerciseRepository;
  final AppDatabase database;
  final WorkoutRepository workoutRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma Fitness',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AppShell(
        exerciseAdminViewModel: exerciseAdminViewModel,
        activeWorkoutViewModel: activeWorkoutViewModel,
        workoutHistoryViewModel: workoutHistoryViewModel,
        exerciseRepository: exerciseRepository,
      ),
    );
  }
}
