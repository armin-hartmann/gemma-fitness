import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/active_workout_models.dart';

class WorkoutTemplateRepository {
  static const String _templatesPrefKey = 'saved_workout_templates';

  /// Retrieves all workout templates, seeding standard presets if not yet initialized.
  Future<List<WorkoutPreset>> getAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_templatesPrefKey);

    if (jsonStr == null || jsonStr.trim().isEmpty) {
      final defaults = WorkoutPreset.getStandardPresets();
      await saveAllTemplates(defaults);
      return defaults;
    }

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(WorkoutPreset.fromJson)
            .toList();
      }
    } catch (_) {}

    final defaults = WorkoutPreset.getStandardPresets();
    await saveAllTemplates(defaults);
    return defaults;
  }

  /// Saves a new or modified workout template.
  Future<void> saveTemplate(WorkoutPreset template) async {
    final templates = await getAllTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);

    if (index >= 0) {
      templates[index] = template;
    } else {
      templates.add(template);
    }

    await saveAllTemplates(templates);
  }

  /// Deletes a workout template by ID.
  Future<void> deleteTemplate(String id) async {
    final templates = await getAllTemplates();
    templates.removeWhere((t) => t.id == id);
    await saveAllTemplates(templates);
  }

  /// Resets all templates to the original built-in presets.
  Future<List<WorkoutPreset>> resetToDefaults() async {
    final defaults = WorkoutPreset.getStandardPresets();
    await saveAllTemplates(defaults);
    return defaults;
  }

  /// Persists full list of templates to storage.
  Future<void> saveAllTemplates(List<WorkoutPreset> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final list = templates.map((t) => t.toJson()).toList();
    final jsonStr = jsonEncode(list);
    await prefs.setString(_templatesPrefKey, jsonStr);
  }
}
