import 'package:flutter/material.dart';
import 'data/database/app_database.dart';
import 'data/repositories/exercise_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'data/services/exercise_sync_service.dart';
import 'data/services/gemini_exercise_service.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/exercise_admin/view_models/exercise_admin_view_model.dart';
import 'ui/features/exercise_admin/views/exercise_admin_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Core Database & Repositories
  final database = AppDatabase();
  final exerciseRepository = ExerciseRepository(database);
  final workoutRepository = WorkoutRepository(database);

  // Services
  final syncService = ExerciseSyncService(exerciseRepository: exerciseRepository);
  final geminiService = GeminiExerciseService();

  // ViewModel
  final exerciseAdminViewModel = ExerciseAdminViewModel(
    exerciseRepository: exerciseRepository,
    syncService: syncService,
    geminiService: geminiService,
  );

  runApp(GemmaFitnessApp(
    viewModel: exerciseAdminViewModel,
    database: database,
    workoutRepository: workoutRepository,
  ));
}

class GemmaFitnessApp extends StatelessWidget {
  const GemmaFitnessApp({
    super.key,
    required this.viewModel,
    required this.database,
    required this.workoutRepository,
  });

  final ExerciseAdminViewModel viewModel;
  final AppDatabase database;
  final WorkoutRepository workoutRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma Fitness',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: ExerciseAdminView(viewModel: viewModel),
    );
  }
}
