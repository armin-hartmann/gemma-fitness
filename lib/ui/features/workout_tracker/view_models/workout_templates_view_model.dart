import 'package:flutter/foundation.dart';
import '../../../../data/repositories/workout_template_repository.dart';
import '../../../../domain/models/active_workout_models.dart';

class WorkoutTemplatesViewModel extends ChangeNotifier {
  WorkoutTemplatesViewModel({
    WorkoutTemplateRepository? templateRepository,
  }) : _templateRepo = templateRepository ?? WorkoutTemplateRepository();

  final WorkoutTemplateRepository _templateRepo;

  List<WorkoutPreset> _templates = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;

  List<WorkoutPreset> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  Future<void> loadTemplates() async {
    _isLoading = true;
    notifyListeners();

    try {
      _templates = await _templateRepo.getAllTemplates();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load workout routines: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveTemplate(WorkoutPreset template) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _templateRepo.saveTemplate(template);
      _statusMessage = 'Workout "${template.title}" saved successfully!';
      await loadTemplates();
    } catch (e) {
      _errorMessage = 'Failed to save workout routine: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _templateRepo.deleteTemplate(id);
      _statusMessage = 'Workout routine deleted.';
      await loadTemplates();
    } catch (e) {
      _errorMessage = 'Failed to delete routine: $e';
      notifyListeners();
    }
  }

  Future<void> resetToDefaults() async {
    _isLoading = true;
    notifyListeners();

    try {
      _templates = await _templateRepo.resetToDefaults();
      _statusMessage = 'Reset all workout routines to standard presets.';
    } catch (e) {
      _errorMessage = 'Failed to reset routines: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
