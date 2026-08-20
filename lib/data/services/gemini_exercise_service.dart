import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/models/exercise_dto.dart';
import 'settings_service.dart';

class GeminiExerciseService {
  GeminiExerciseService({
    SettingsService? settingsService,
    this._apiKey,
    this._modelName = 'gemini-3.6-flash',
  }) : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;
  final String? _apiKey;
  final String _modelName;

  /// Returns true if either an explicit key, environment key, or local persisted key is found.
  Future<bool> get isConfigured async {
    if (_apiKey != null && _apiKey.trim().isNotEmpty) return true;
    final storedKey = await _settingsService.getGeminiApiKey();
    return storedKey != null && storedKey.isNotEmpty;
  }

  /// Parses raw, unstructured text into a structured list of [ExerciseDto] objects.
  Future<List<ExerciseDto>> parseExercisesFromRawText(
    String rawText, {
    String? overrideApiKey,
  }) async {
    String? keyToUse;
    if (overrideApiKey != null && overrideApiKey.trim().isNotEmpty) {
      keyToUse = overrideApiKey.trim();
    } else if (_apiKey != null && _apiKey.trim().isNotEmpty) {
      keyToUse = _apiKey.trim();
    } else {
      keyToUse = await _settingsService.getGeminiApiKey();
    }

    if (keyToUse == null || keyToUse.trim().isEmpty) {
      throw StateError(
        'Gemini API key is not configured. Please supply an API key in Settings or pass GEMINI_API_KEY.',
      );
    }

    final model = GenerativeModel(
      model: _modelName,
      apiKey: keyToUse,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
      systemInstruction: Content.system('''
You are an expert fitness database assistant. 
Your job is to analyze unstructured fitness text, workout descriptions, routine notes, or exercise lists, and extract every exercise into a structured JSON array.

Each item in the array MUST strictly have the following fields:
- "name": String (clear, standard exercise name)
- "category": String (e.g. "Strength", "Hypertrophy", "Mobility", "Cardio", "Core", "Plyometrics")
- "primary_muscle": String (e.g. "Chest", "Upper Back", "Lats", "Quads", "Hamstrings", "Glutes", "Shoulders", "Biceps", "Triceps", "Abs", "Calves")
- "equipment": String (e.g. "Bodyweight", "Dumbbell", "Barbell", "Kettlebell", "Cable", "Machine", "Resistance Band", "Foam Roller")
- "instructions": String (concise setup, execution steps, and form cues)
- "default_phase": String (strictly one of: "warmup", "working", "cooldown")
- "requires_equipment": Boolean (false for bodyweight/calisthenics/stretches requiring no apparatus; true for barbell, dumbbell, cable, machine, etc.)

Return a JSON array of objects.
'''),
    );

    final prompt = '''
Extract all exercises from the following text:

---
$rawText
---
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final responseText = response.text;

    if (responseText == null || responseText.trim().isEmpty) {
      throw Exception('Empty response received from Gemini API.');
    }

    return parseExercisesFromJson(responseText);
  }

  /// Parses a JSON string containing either a list of exercises or a wrapper object.
  List<ExerciseDto> parseExercisesFromJson(String jsonString) {
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

    List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic>) {
      if (decoded['exercises'] is List) {
        items = decoded['exercises'] as List;
      } else if (decoded['data'] is List) {
        items = decoded['data'] as List;
      } else {
        final firstList = decoded.values.firstWhere(
          (v) => v is List,
          orElse: () => [decoded],
        );
        items = firstList is List ? firstList : [decoded];
      }
    } else {
      throw FormatException('Unexpected JSON structure from Gemini: $decoded');
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => ExerciseDto.fromJson(item))
        .toList();
  }
}
