import 'package:flutter/foundation.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/exercise_repository.dart';
import '../../../../data/services/exercise_sync_service.dart';
import '../../../../data/services/gemini_exercise_service.dart';
import '../../../../data/services/settings_service.dart';
import '../../../../domain/models/exercise_dto.dart';

class ExerciseAdminViewModel extends ChangeNotifier {
  ExerciseAdminViewModel({
    required ExerciseRepository exerciseRepository,
    required this._syncService,
    required this._geminiService,
    SettingsService? settingsService,
  })  : _exerciseRepo = exerciseRepository,
        _settingsService = settingsService ?? SettingsService();

  final ExerciseRepository _exerciseRepo;
  final ExerciseSyncService _syncService;
  final GeminiExerciseService _geminiService;
  final SettingsService _settingsService;

  List<Exercise> _allExercises = [];
  bool _isLoading = false;
  bool _isIngesting = false;
  String? _errorMessage;
  String? _statusMessage;
  String? _savedApiKey;

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedMuscle;
  String? _selectedPhase;
  String? _selectedEquipmentFilter;

  // Bulk Ingestion state
  List<ExerciseDto> _parsedIngestionResults = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isIngesting => _isIngesting;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedMuscle => _selectedMuscle;
  String? get selectedPhase => _selectedPhase;
  String? get selectedEquipmentFilter => _selectedEquipmentFilter;
  List<ExerciseDto> get parsedIngestionResults => _parsedIngestionResults;
  String? get savedApiKey => _savedApiKey;
  bool get hasApiKey =>
      (_savedApiKey != null && _savedApiKey!.isNotEmpty) ||
      _settingsService.hasEnvironmentKey;

  List<Exercise> get filteredExercises {
    return _allExercises.where((ex) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = ex.name.toLowerCase().contains(q);
        final matchesMuscle = ex.primaryMuscle.toLowerCase().contains(q);
        final matchesCat = ex.category.toLowerCase().contains(q);
        final matchesEquip = ex.equipment.toLowerCase().contains(q);
        if (!matchesName && !matchesMuscle && !matchesCat && !matchesEquip) {
          return false;
        }
      }

      if (_selectedCategory != null && ex.category != _selectedCategory) {
        return false;
      }

      if (_selectedMuscle != null && ex.primaryMuscle != _selectedMuscle) {
        return false;
      }

      if (_selectedPhase != null &&
          ex.defaultPhase.toLowerCase() != _selectedPhase!.toLowerCase()) {
        return false;
      }

      if (_selectedEquipmentFilter != null) {
        switch (_selectedEquipmentFilter) {
          case 'no_equipment':
            if (ex.requiresEquipment &&
                ex.equipment.toLowerCase() != 'bodyweight') {
              return false;
            }
            break;
          case 'free_weights':
            final eq = ex.equipment.toLowerCase();
            if (!eq.contains('barbell') &&
                !eq.contains('dumbbell') &&
                !eq.contains('kettlebell')) {
              return false;
            }
            break;
          case 'machines':
            final eq = ex.equipment.toLowerCase();
            if (!eq.contains('machine') && !eq.contains('cable')) {
              return false;
            }
            break;
        }
      }

      return true;
    }).toList();
  }

  int get totalCount => _allExercises.length;
  int get warmupCount =>
      _allExercises.where((e) => e.defaultPhase.toLowerCase() == 'warmup').length;
  int get workingCount =>
      _allExercises.where((e) => e.defaultPhase.toLowerCase() == 'working').length;
  int get cooldownCount =>
      _allExercises.where((e) => e.defaultPhase.toLowerCase() == 'cooldown').length;

  int get noEquipmentCount => _allExercises
      .where((e) => !e.requiresEquipment || e.equipment.toLowerCase() == 'bodyweight')
      .length;

  int get freeWeightsCount => _allExercises.where((e) {
        final eq = e.equipment.toLowerCase();
        return eq.contains('barbell') ||
            eq.contains('dumbbell') ||
            eq.contains('kettlebell');
      }).length;

  int get machinesCount => _allExercises.where((e) {
        final eq = e.equipment.toLowerCase();
        return eq.contains('machine') || eq.contains('cable');
      }).length;

  List<String> get availableCategories {
    final set = _allExercises.map((e) => e.category).toSet();
    return set.toList()..sort();
  }

  List<String> get availableMuscles {
    final set = _allExercises.map((e) => e.primaryMuscle).toSet();
    return set.toList()..sort();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _savedApiKey = await _settingsService.getGeminiApiKey();
      await _syncService.seedInitialExercisesIfEmpty();
      await loadExercises();
    } catch (e) {
      _errorMessage = 'Failed to initialize exercises: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveApiKey(String key) async {
    await _settingsService.saveGeminiApiKey(key);
    _savedApiKey = key.trim();
    _statusMessage = 'Gemini API key saved to device!';
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    await _settingsService.clearGeminiApiKey();
    _savedApiKey = null;
    _statusMessage = 'Gemini API key removed from device.';
    notifyListeners();
  }

  Future<void> reseedDatabase() async {
    _isLoading = true;
    notifyListeners();

    try {
      final seeds = ExerciseSyncService.getCuratedMasterLibrary();
      final companions = seeds.map((dto) => dto.toCompanion()).toList();
      await _exerciseRepo.bulkUpsertExercises(companions);
      await loadExercises();
      _statusMessage = 'Successfully seeded master catalog with ${companions.length} exercises.';
    } catch (e) {
      _errorMessage = 'Failed to reseed database: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExercises() async {
    try {
      _allExercises = await _exerciseRepo.getAllExercises();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error loading exercises: $e';
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = (_selectedCategory == category) ? null : category;
    notifyListeners();
  }

  void setMuscle(String? muscle) {
    _selectedMuscle = (_selectedMuscle == muscle) ? null : muscle;
    notifyListeners();
  }

  void setPhase(String? phase) {
    _selectedPhase = (_selectedPhase == phase) ? null : phase;
    notifyListeners();
  }

  void setEquipmentFilter(String? filter) {
    _selectedEquipmentFilter =
        (_selectedEquipmentFilter == filter) ? null : filter;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedMuscle = null;
    _selectedPhase = null;
    _selectedEquipmentFilter = null;
    notifyListeners();
  }

  Future<bool> saveExercise(ExerciseDto dto) async {
    try {
      final companion = dto.toCompanion();
      await _exerciseRepo.insertExercise(companion);
      await loadExercises();
      _statusMessage = 'Exercise "${dto.name}" saved successfully.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save exercise: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExercise(ExerciseDto dto) async {
    if (dto.id == null) return false;
    try {
      final companion = dto.toCompanion(fallbackId: dto.id);
      await _exerciseRepo.updateExercise(companion);
      await loadExercises();
      _statusMessage = 'Exercise "${dto.name}" updated successfully.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update exercise: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExercise(String id) async {
    try {
      await _exerciseRepo.deleteExercise(id);
      await loadExercises();
      _statusMessage = 'Exercise deleted.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete exercise (it may be linked to a workout).';
      notifyListeners();
      return false;
    }
  }

  Future<bool> parseRawWorkoutTextWithGemini(
    String rawText, {
    String? overrideApiKey,
  }) async {
    if (rawText.trim().isEmpty) {
      _errorMessage = 'Please enter workout or exercise text to ingest.';
      notifyListeners();
      return false;
    }

    _isIngesting = true;
    _errorMessage = null;
    _statusMessage = 'Analyzing text with Gemini API...';
    notifyListeners();

    try {
      _parsedIngestionResults = await _geminiService.parseExercisesFromRawText(
        rawText,
        overrideApiKey: overrideApiKey,
      );
      _statusMessage =
          'Successfully parsed ${_parsedIngestionResults.length} exercises from text.';
      _isIngesting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gemini Ingestion failed: $e';
      _isIngesting = false;
      notifyListeners();
      return false;
    }
  }

  void updateIngestedItem(int index, ExerciseDto updated) {
    if (index >= 0 && index < _parsedIngestionResults.length) {
      _parsedIngestionResults[index] = updated;
      notifyListeners();
    }
  }

  void removeIngestedItem(int index) {
    if (index >= 0 && index < _parsedIngestionResults.length) {
      _parsedIngestionResults.removeAt(index);
      notifyListeners();
    }
  }

  void clearIngestionResults() {
    _parsedIngestionResults = [];
    notifyListeners();
  }

  Future<int> saveParsedIngestionResults() async {
    if (_parsedIngestionResults.isEmpty) return 0;

    _isLoading = true;
    notifyListeners();

    try {
      final companions = _parsedIngestionResults.map((d) => d.toCompanion()).toList();
      await _exerciseRepo.bulkUpsertExercises(companions);
      final count = _parsedIngestionResults.length;
      _parsedIngestionResults = [];
      await loadExercises();
      _statusMessage = 'Successfully added $count exercises to master database.';
      _isLoading = false;
      notifyListeners();
      return count;
    } catch (e) {
      _errorMessage = 'Failed to save parsed exercises: $e';
      _isLoading = false;
      notifyListeners();
      return 0;
    }
  }

  Future<String> exportToJson() async {
    return _syncService.exportExercisesToJson();
  }

  Future<int> importFromJson(String json) async {
    _isLoading = true;
    notifyListeners();
    try {
      final count = await _syncService.importExercisesFromJson(json);
      await loadExercises();
      _statusMessage = 'Imported $count exercises successfully.';
      _isLoading = false;
      notifyListeners();
      return count;
    } catch (e) {
      _errorMessage = 'Import failed: $e';
      _isLoading = false;
      notifyListeners();
      return 0;
    }
  }
}
