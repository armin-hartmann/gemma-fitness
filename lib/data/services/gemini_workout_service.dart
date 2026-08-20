import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/models/active_workout_models.dart';
import '../../domain/models/exercise_dto.dart';
import '../../domain/services/workout_ai_service.dart';
import 'settings_service.dart';

class GeminiWorkoutService implements WorkoutAiService {
  GeminiWorkoutService({
    SettingsService? settingsService,
    this.apiKey,
    this.modelName = 'gemini-3.6-flash',
  }) : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;
  final String? apiKey;
  final String modelName;

  @override
  Future<bool> get isReady async {
    if (apiKey != null && apiKey!.trim().isNotEmpty) return true;
    final storedKey = await _settingsService.getGeminiApiKey();
    return storedKey != null && storedKey.isNotEmpty;
  }

  @override
  Future<GeneratedWorkoutResult> generateWorkout(
    WorkoutGenerationRequest request, {
    String? overrideApiKey,
  }) async {
    String? keyToUse;
    if (overrideApiKey != null && overrideApiKey.trim().isNotEmpty) {
      keyToUse = overrideApiKey.trim();
    } else if (apiKey != null && apiKey!.trim().isNotEmpty) {
      keyToUse = apiKey!.trim();
    } else {
      keyToUse = await _settingsService.getGeminiApiKey();
    }

    if (keyToUse == null || keyToUse.trim().isEmpty) {
      throw StateError(
        'Gemini API key is not configured. Please enter your API key in settings or dialog.',
      );
    }

    final model = GenerativeModel(
      model: modelName,
      apiKey: keyToUse,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.3,
      ),
      systemInstruction: Content.system('''
You are an elite AI Strength & Conditioning Coach and Exercise Physiologist.
Your task is to design a high-quality, scientifically sound workout routine based on the user's specific goals, available equipment, target muscle groups, time constraints, and preferences.

ROUTINE STRUCTURE GUIDELINES:
1. Warm-up Phase ("warmup"): 1 to 3 dynamic mobility, activation, or movement-prep exercises (e.g. dynamic stretches, glute bridges, band pull-aparts). Low intensity, higher reps (8-15) or timed holds.
2. Working Sets Phase ("working"): 3 to 6 primary compound and accessory strength exercises targeting the specified muscle groups with appropriate set/rep/RPE volume fitting the requested duration.
3. Cool-down Phase ("cooldown"): 1 to 3 static stretches or myofascial relaxation exercises (20-30s holds).

JSON SCHEMA REQUIREMENT:
Return a strictly valid JSON object matching this schema:
{
  "title": "String (e.g. '⚡ 30-Min Dumbbell Upper Body Blast')",
  "description": "String (engaging 1-2 sentence overview of the session focus)",
  "modality": "String ('bodyweight' | 'free_weights' | 'machines' | 'hybrid')",
  "reasoning": "String (2-3 sentences explaining why this routine fits the user's goal, time limit, and equipment)",
  "exercises": [
    {
      "exercise_name": "String (clear, standard name)",
      "phase": "String ('warmup' | 'working' | 'cooldown')",
      "target_sets": "Integer (e.g. 3)",
      "target_reps": "Integer (e.g. 10)",
      "target_weight": "Number or null (suggested weight in kg if free weights/equipment; null for bodyweight)",
      "target_rpe": "Number or null (e.g. 8.0)",
      "coaching_cue": "String (key form tip, e.g. 'Tuck elbows at 45 degrees, slow eccentric')",
      "category": "String (e.g. 'Strength', 'Hypertrophy', 'Mobility')",
      "primary_muscle": "String (e.g. 'Chest', 'Lats', 'Quads', 'Hamstrings', 'Glutes', 'Shoulders', 'Abs')",
      "equipment": "String (e.g. 'Bodyweight', 'Dumbbell', 'Barbell', 'Kettlebell', 'Resistance Band')",
      "requires_equipment": "Boolean (false for bodyweight/stretches; true for dumbbells/barbells/machines)"
    }
  ]
}
'''),
    );

    final promptBuilder = StringBuffer();
    promptBuilder.writeln('Please design a custom workout routine with the following parameters:');
    promptBuilder.writeln('- Goal: ${request.goal}');
    promptBuilder.writeln('- Equipment Modality: ${request.modality}');
    promptBuilder.writeln('- Target Muscles: ${request.targetMuscles.join(', ')}');
    promptBuilder.writeln('- Available Duration: ${request.durationMinutes} minutes');
    promptBuilder.writeln('- Fitness Experience Level: ${request.fitnessLevel}');

    if (request.customPrompt != null && request.customPrompt!.trim().isNotEmpty) {
      promptBuilder.writeln('- User Special Instructions / Notes: "${request.customPrompt!.trim()}"');
    }

    if (request.availableExerciseNames != null && request.availableExerciseNames!.isNotEmpty) {
      promptBuilder.writeln('- Master Catalog Exercises to prioritize (if appropriate): ${request.availableExerciseNames!.take(40).join(', ')}');
    }

    final response = await model.generateContent([Content.text(promptBuilder.toString())]);
    final text = response.text;

    if (text == null || text.trim().isEmpty) {
      throw Exception('Empty response received from Gemini API.');
    }

    return parseWorkoutResultFromJson(text, request.modality);
  }

  /// Parses JSON response into a [GeneratedWorkoutResult].
  GeneratedWorkoutResult parseWorkoutResultFromJson(String jsonString, String defaultModality) {
    var cleaned = jsonString.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final dynamic decoded = jsonDecode(cleaned);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid JSON format for workout result.');
    }

    final title = decoded['title'] as String? ?? 'AI Custom Workout Routine';
    final description = decoded['description'] as String? ?? 'Personalized routine created by AI.';
    final modality = decoded['modality'] as String? ?? defaultModality;
    final reasoning = decoded['reasoning'] as String? ?? 'Tailored to your target muscles and equipment.';

    final rawExercises = decoded['exercises'] as List? ?? [];
    final List<GeneratedExerciseItem> items = [];

    for (final raw in rawExercises) {
      if (raw is Map<String, dynamic>) {
        final name = raw['exercise_name'] as String? ?? 'Exercise';
        final phase = raw['phase'] as String? ?? 'working';
        final sets = raw['target_sets'] as int? ?? 3;
        final reps = raw['target_reps'] as int? ?? 10;
        final rawWeight = raw['target_weight'];
        final rawRpe = raw['target_rpe'];
        final weight = rawWeight is num ? rawWeight.toDouble() : null;
        final rpe = rawRpe is num ? rawRpe.toDouble() : null;
        final cue = raw['coaching_cue'] as String?;

        final category = raw['category'] as String? ?? 'Strength';
        final muscle = raw['primary_muscle'] as String? ?? 'Full Body';
        final equipment = raw['equipment'] as String? ?? (modality == 'bodyweight' ? 'Bodyweight' : 'Dumbbell');
        final reqEquipment = raw['requires_equipment'] as bool? ?? (modality != 'bodyweight');

        final presetItem = PresetExerciseItem(
          exerciseName: name,
          phase: phase,
          targetSets: sets,
          targetReps: reps,
          targetWeight: weight,
          targetRpe: rpe,
        );

        final newDto = ExerciseDto(
          name: name,
          category: category,
          primaryMuscle: muscle,
          equipment: equipment,
          instructions: cue,
          defaultPhase: phase,
          requiresEquipment: reqEquipment,
        );

        items.add(
          GeneratedExerciseItem(
            presetItem: presetItem,
            newExerciseDefinition: newDto,
            coachingCue: cue,
          ),
        );
      }
    }

    return GeneratedWorkoutResult(
      title: title,
      description: description,
      modality: modality,
      reasoning: reasoning,
      exercises: items,
    );
  }
}
