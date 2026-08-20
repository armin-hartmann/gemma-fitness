import 'package:flutter/foundation.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../domain/models/active_workout_models.dart';

class WorkoutHistoryViewModel extends ChangeNotifier {
  WorkoutHistoryViewModel({
    required WorkoutRepository workoutRepository,
  }) : _workoutRepo = workoutRepository;

  final WorkoutRepository _workoutRepo;

  List<ActiveWorkoutSession> _completedSessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ActiveWorkoutSession> get completedSessions => _completedSessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalWorkoutsCount => _completedSessions.length;
  double get allTimeVolume =>
      _completedSessions.fold(0.0, (sum, s) => sum + s.totalVolume);

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final sessions = await _workoutRepo.getCompletedSessions();
      final List<ActiveWorkoutSession> fullSessions = [];

      for (final s in sessions) {
        final full = await _workoutRepo.getFullActiveSession(s.id);
        if (full != null) {
          fullSessions.add(full);
        }
      }

      _completedSessions = fullSessions;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load workout history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteWorkout(String sessionId) async {
    try {
      await _workoutRepo.deleteSession(sessionId);
      await loadHistory();
    } catch (e) {
      _errorMessage = 'Failed to delete workout: $e';
      notifyListeners();
    }
  }
}
