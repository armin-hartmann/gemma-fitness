import '../models/active_workout_models.dart';
import '../models/exercise_dto.dart';

class WorkoutGenerationRequest {
  const WorkoutGenerationRequest({
    required this.goal,
    required this.modality,
    required this.targetMuscles,
    required this.durationMinutes,
    this.fitnessLevel = 'intermediate',
    this.customPrompt,
    this.availableExerciseNames,
  });

  final String goal; // 'Strength', 'Hypertrophy', 'Endurance', 'Fat Loss', 'Mobility & Recovery', 'HIIT'
  final String modality; // 'bodyweight', 'free_weights', 'machines', 'hybrid'
  final List<String> targetMuscles; // e.g. ['Chest', 'Triceps'], ['Full Body'], ['Quads', 'Glutes']
  final int durationMinutes; // e.g. 15, 30, 45, 60
  final String fitnessLevel; // 'beginner', 'intermediate', 'advanced'
  final String? customPrompt; // e.g. 'No jumping, focus on push-up variations'
  final List<String>? availableExerciseNames;
}

class GeneratedExerciseItem {
  const GeneratedExerciseItem({
    required this.presetItem,
    this.newExerciseDefinition,
    this.coachingCue,
  });

  final PresetExerciseItem presetItem;
  final ExerciseDto? newExerciseDefinition;
  final String? coachingCue;
}

class GeneratedWorkoutResult {
  const GeneratedWorkoutResult({
    required this.title,
    required this.description,
    required this.modality,
    required this.reasoning,
    required this.exercises,
  });

  final String title;
  final String description;
  final String modality;
  final String reasoning;
  final List<GeneratedExerciseItem> exercises;

  WorkoutPreset toPreset({required String id}) {
    return WorkoutPreset(
      id: id,
      title: title,
      description: description,
      modality: modality,
      iconName: modality == 'bodyweight' ? 'home' : 'fitness_center',
      isCustom: true,
      exercisePhases: exercises.map((e) => e.presetItem).toList(),
    );
  }
}

abstract class WorkoutAiService {
  /// Generates a complete, structured workout routine from user preferences.
  Future<GeneratedWorkoutResult> generateWorkout(
    WorkoutGenerationRequest request, {
    String? overrideApiKey,
  });

  /// Returns whether the AI service is ready/configured to generate workouts.
  Future<bool> get isReady;
}
