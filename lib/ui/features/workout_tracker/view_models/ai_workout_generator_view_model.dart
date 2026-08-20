import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/repositories/exercise_repository.dart';
import '../../../../domain/models/active_workout_models.dart';
import '../../../../domain/services/workout_ai_service.dart';
import 'workout_templates_view_model.dart';

class AiWorkoutGeneratorViewModel extends ChangeNotifier {
  AiWorkoutGeneratorViewModel({
    required this.aiService,
    required this.exerciseRepository,
    required this.templatesViewModel,
  });

  final WorkoutAiService aiService;
  final ExerciseRepository exerciseRepository;
  final WorkoutTemplatesViewModel templatesViewModel;
  final _uuid = const Uuid();

  // Questionnaire State
  String _selectedGoal = 'Hypertrophy';
  String _selectedModality = 'bodyweight';
  List<String> _selectedMuscles = ['Full Body'];
  int _selectedDuration = 30;
  String _selectedFitnessLevel = 'intermediate';
  String _customInstructions = '';

  // Generation Output State
  GeneratedWorkoutResult? _generatedResult;
  bool _isGenerating = false;
  String? _errorMessage;

  // Getters
  String get selectedGoal => _selectedGoal;
  String get selectedModality => _selectedModality;
  List<String> get selectedMuscles => _selectedMuscles;
  int get selectedDuration => _selectedDuration;
  String get selectedFitnessLevel => _selectedFitnessLevel;
  String get customInstructions => _customInstructions;
  GeneratedWorkoutResult? get generatedResult => _generatedResult;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;

  void setGoal(String goal) {
    _selectedGoal = goal;
    notifyListeners();
  }

  void setModality(String modality) {
    _selectedModality = modality;
    notifyListeners();
  }

  void toggleMuscle(String muscle) {
    if (muscle == 'Full Body') {
      _selectedMuscles = ['Full Body'];
    } else {
      _selectedMuscles.remove('Full Body');
      if (_selectedMuscles.contains(muscle)) {
        _selectedMuscles.remove(muscle);
        if (_selectedMuscles.isEmpty) {
          _selectedMuscles.add('Full Body');
        }
      } else {
        _selectedMuscles.add(muscle);
      }
    }
    notifyListeners();
  }

  void setDuration(int minutes) {
    _selectedDuration = minutes;
    notifyListeners();
  }

  void setFitnessLevel(String level) {
    _selectedFitnessLevel = level;
    notifyListeners();
  }

  void setCustomInstructions(String instructions) {
    _customInstructions = instructions;
  }

  Future<void> generateWorkout({String? overrideApiKey}) async {
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existingExercises = await exerciseRepository.getAllExercises();
      final exerciseNames = existingExercises.map((e) => e.name).toList();

      final request = WorkoutGenerationRequest(
        goal: _selectedGoal,
        modality: _selectedModality,
        targetMuscles: _selectedMuscles,
        durationMinutes: _selectedDuration,
        fitnessLevel: _selectedFitnessLevel,
        customPrompt: _customInstructions.isNotEmpty ? _customInstructions : null,
        availableExerciseNames: exerciseNames,
      );

      final result = await aiService.generateWorkout(
        request,
        overrideApiKey: overrideApiKey,
      );

      _generatedResult = result;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'AI Workout Generation failed: $e';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void updateExerciseSets(int index, int newSets) {
    if (_generatedResult == null) return;
    final exercises = List<GeneratedExerciseItem>.from(_generatedResult!.exercises);
    final item = exercises[index];
    exercises[index] = GeneratedExerciseItem(
      presetItem: item.presetItem.copyWith(targetSets: newSets),
      newExerciseDefinition: item.newExerciseDefinition,
      coachingCue: item.coachingCue,
    );

    _generatedResult = GeneratedWorkoutResult(
      title: _generatedResult!.title,
      description: _generatedResult!.description,
      modality: _generatedResult!.modality,
      reasoning: _generatedResult!.reasoning,
      exercises: exercises,
    );
    notifyListeners();
  }

  void updateExerciseReps(int index, int newReps) {
    if (_generatedResult == null) return;
    final exercises = List<GeneratedExerciseItem>.from(_generatedResult!.exercises);
    final item = exercises[index];
    exercises[index] = GeneratedExerciseItem(
      presetItem: item.presetItem.copyWith(targetReps: newReps),
      newExerciseDefinition: item.newExerciseDefinition,
      coachingCue: item.coachingCue,
    );

    _generatedResult = GeneratedWorkoutResult(
      title: _generatedResult!.title,
      description: _generatedResult!.description,
      modality: _generatedResult!.modality,
      reasoning: _generatedResult!.reasoning,
      exercises: exercises,
    );
    notifyListeners();
  }

  void updateExerciseWeight(int index, double? newWeight) {
    if (_generatedResult == null) return;
    final exercises = List<GeneratedExerciseItem>.from(_generatedResult!.exercises);
    final item = exercises[index];
    exercises[index] = GeneratedExerciseItem(
      presetItem: item.presetItem.copyWith(targetWeight: newWeight),
      newExerciseDefinition: item.newExerciseDefinition,
      coachingCue: item.coachingCue,
    );

    _generatedResult = GeneratedWorkoutResult(
      title: _generatedResult!.title,
      description: _generatedResult!.description,
      modality: _generatedResult!.modality,
      reasoning: _generatedResult!.reasoning,
      exercises: exercises,
    );
    notifyListeners();
  }

  void updateExercisePhase(int index, String newPhase) {
    if (_generatedResult == null) return;
    final exercises = List<GeneratedExerciseItem>.from(_generatedResult!.exercises);
    final item = exercises[index];
    exercises[index] = GeneratedExerciseItem(
      presetItem: item.presetItem.copyWith(phase: newPhase),
      newExerciseDefinition: item.newExerciseDefinition,
      coachingCue: item.coachingCue,
    );

    // Re-sort by phase order: warmup -> working -> cooldown
    const order = {'warmup': 0, 'working': 1, 'cooldown': 2};
    exercises.sort((a, b) =>
        (order[a.presetItem.phase] ?? 1).compareTo(order[b.presetItem.phase] ?? 1));

    _generatedResult = GeneratedWorkoutResult(
      title: _generatedResult!.title,
      description: _generatedResult!.description,
      modality: _generatedResult!.modality,
      reasoning: _generatedResult!.reasoning,
      exercises: exercises,
    );
    notifyListeners();
  }

  /// Saves the generated preset to the user's saved routines and syncs any missing exercise definitions to the catalog.
  Future<WorkoutPreset?> saveGeneratedPreset() async {
    if (_generatedResult == null) return null;

    final preset = _generatedResult!.toPreset(id: _uuid.v4());

    // 1. Sync any newly introduced exercise definitions to the SQLite catalog
    for (final item in _generatedResult!.exercises) {
      if (item.newExerciseDefinition != null) {
        await exerciseRepository.upsertExerciseByName(
          item.newExerciseDefinition!.toCompanion(),
        );
      }
    }

    // 2. Save the routine into the template repository
    await templatesViewModel.saveTemplate(preset);
    return preset;
  }
}
