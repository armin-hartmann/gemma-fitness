import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/exercise_repository.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../domain/engine/workout_metrics_engine.dart';
import '../../../../domain/models/active_workout_models.dart';

class ActiveWorkoutViewModel extends ChangeNotifier {
  ActiveWorkoutViewModel({
    required WorkoutRepository workoutRepository,
    required ExerciseRepository exerciseRepository,
  })  : _workoutRepo = workoutRepository,
        _exerciseRepo = exerciseRepository;

  final WorkoutRepository _workoutRepo;
  final ExerciseRepository _exerciseRepo;
  final _uuid = const Uuid();

  ActiveWorkoutSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  // Elapsed Workout Timer
  Timer? _sessionTimer;
  Duration _elapsedDuration = Duration.zero;

  // Rest Interval Timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  int _targetRestDuration = 90;
  bool _isRestTimerActive = false;

  // PR Celebrations
  final List<PersonalRecord> _sessionPRs = [];

  // Getters
  ActiveWorkoutSession? get currentSession => _currentSession;
  bool get hasActiveWorkout => _currentSession != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Duration get elapsedDuration => _elapsedDuration;
  String get formattedElapsed => WorkoutMetricsEngine.formatDuration(_elapsedDuration);

  int get restSecondsRemaining => _restSecondsRemaining;
  int get targetRestDuration => _targetRestDuration;
  bool get isRestTimerActive => _isRestTimerActive;
  String get formattedRestRemaining {
    final m = _restSecondsRemaining ~/ 60;
    final s = _restSecondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  double get restProgress => _targetRestDuration > 0
      ? (_restSecondsRemaining / _targetRestDuration).clamp(0.0, 1.0)
      : 0.0;

  List<PersonalRecord> get sessionPRs => List.unmodifiable(_sessionPRs);

  double get currentVolume => _currentSession?.totalVolume ?? 0.0;
  int get completedSetsCount => _currentSession?.totalCompletedSets ?? 0;
  int get totalSetsCount => _currentSession?.totalSets ?? 0;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final unfinished = await _workoutRepo.getActiveUnfinishedSession();
      if (unfinished != null) {
        _currentSession = await _workoutRepo.getFullActiveSession(unfinished.id);
        if (_currentSession != null) {
          _elapsedDuration = DateTime.now().difference(unfinished.dateStarted);
          _startSessionTicker();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to check unfinished workout: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startSessionTicker() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentSession != null) {
        _elapsedDuration =
            DateTime.now().difference(_currentSession!.session.dateStarted);
        notifyListeners();
      }
    });
  }

  /// Starts a fresh workout session from a curated preset.
  Future<bool> startWorkoutFromPreset(WorkoutPreset preset) async {
    _isLoading = true;
    notifyListeners();

    try {
      final sessionId = _uuid.v4();
      final now = DateTime.now();

      await _workoutRepo.insertSession(
        WorkoutSessionsCompanion.insert(
          id: sessionId,
          dateStarted: now,
          notes: Value(preset.title),
        ),
      );

      final allExercises = await _exerciseRepo.getAllExercises();

      int order = 0;
      for (final presetItem in preset.exercisePhases) {
        final exercise = allExercises.firstWhere(
          (e) => e.name.toLowerCase() == presetItem.exerciseName.toLowerCase(),
          orElse: () => allExercises.first,
        );

        final sessionExerciseId = _uuid.v4();
        await _workoutRepo.insertSessionExercise(
          SessionExercisesCompanion.insert(
            id: sessionExerciseId,
            sessionId: sessionId,
            exerciseId: exercise.id,
            phase: Value(presetItem.phase),
            orderInSession: Value(order++),
          ),
        );

        final targetWeight = presetItem.targetWeight;
        final targetRpe = presetItem.targetRpe;

        for (int setIdx = 1; setIdx <= presetItem.targetSets; setIdx++) {
          await _workoutRepo.insertWorkoutSet(
            WorkoutSetsCompanion.insert(
              id: _uuid.v4(),
              sessionExerciseId: sessionExerciseId,
              setNumber: setIdx,
              setType: Value(presetItem.phase == 'warmup' ? 'warmup' : 'normal'),
              weight: targetWeight != null
                  ? Value(targetWeight)
                  : const Value.absent(),
              reps: Value(presetItem.targetReps),
              rpe: targetRpe != null
                  ? Value(targetRpe)
                  : const Value.absent(),
            ),
          );
        }
      }

      _currentSession = await _workoutRepo.getFullActiveSession(sessionId);
      _elapsedDuration = Duration.zero;
      _sessionPRs.clear();
      _startSessionTicker();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to start preset workout: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Starts a custom, blank workout session.
  Future<bool> startBlankWorkout({String title = 'Quick Workout'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final sessionId = _uuid.v4();
      final now = DateTime.now();

      await _workoutRepo.insertSession(
        WorkoutSessionsCompanion.insert(
          id: sessionId,
          dateStarted: now,
          notes: Value(title),
        ),
      );

      _currentSession = await _workoutRepo.getFullActiveSession(sessionId);
      _elapsedDuration = Duration.zero;
      _sessionPRs.clear();
      _startSessionTicker();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to start blank workout: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Adds a new exercise into the active session with an initial set.
  Future<void> addExerciseToSession(
    Exercise exercise, {
    String? phase,
  }) async {
    if (_currentSession == null) return;

    final targetPhase = phase ?? exercise.defaultPhase;
    final sessionExerciseId = _uuid.v4();
    final order = _currentSession!.exercises.length;

    await _workoutRepo.insertSessionExercise(
      SessionExercisesCompanion.insert(
        id: sessionExerciseId,
        sessionId: _currentSession!.session.id,
        exerciseId: exercise.id,
        phase: Value(targetPhase),
        orderInSession: Value(order),
      ),
    );

    // Add initial set
    await _workoutRepo.insertWorkoutSet(
      WorkoutSetsCompanion.insert(
        id: _uuid.v4(),
        sessionExerciseId: sessionExerciseId,
        setNumber: 1,
        setType: Value(targetPhase == 'warmup' ? 'warmup' : 'normal'),
        reps: const Value(10),
        weight: exercise.requiresEquipment ? const Value(20.0) : const Value(0.0),
      ),
    );

    await _refreshCurrentSession();
  }

  /// Removes an exercise from the active session.
  Future<void> removeExerciseFromSession(String sessionExerciseId) async {
    if (_currentSession == null) return;
    await _workoutRepo.deleteSessionExercise(sessionExerciseId);
    await _refreshCurrentSession();
  }

  /// Updates the phase (warmup, working, cooldown) of an exercise in the active session.
  Future<void> updateExercisePhase(String sessionExerciseId, String newPhase) async {
    if (_currentSession == null) return;
    await _workoutRepo.updateSessionExercisePhase(sessionExerciseId, newPhase);
    await _refreshCurrentSession();
  }

  /// Adds another set to an exercise in the active session, copying previous set's weight/reps.
  Future<void> addSetToExercise(ActiveSessionExercise activeExercise) async {
    if (_currentSession == null) return;

    final nextSetNum = activeExercise.sets.length + 1;
    final lastSet =
        activeExercise.sets.isNotEmpty ? activeExercise.sets.last : null;

    await _workoutRepo.insertWorkoutSet(
      WorkoutSetsCompanion.insert(
        id: _uuid.v4(),
        sessionExerciseId: activeExercise.sessionExercise.id,
        setNumber: nextSetNum,
        setType: Value(lastSet?.setType ?? 'normal'),
        weight: lastSet?.weight != null ? Value(lastSet!.weight) : const Value.absent(),
        reps: lastSet?.reps != null ? Value(lastSet!.reps) : const Value(10),
        rpe: lastSet?.rpe != null ? Value(lastSet!.rpe) : const Value.absent(),
      ),
    );

    await _refreshCurrentSession();
  }

  /// Updates weight, reps, RPE, or type of a set.
  Future<void> updateSet(
    WorkoutSet set, {
    double? weight,
    int? reps,
    double? rpe,
    String? setType,
    bool? isCompleted,
  }) async {
    final updated = set.copyWith(
      weight: weight ?? set.weight,
      reps: reps ?? set.reps,
      rpe: rpe != null ? Value(rpe) : Value(set.rpe),
      setType: setType ?? set.setType,
      isCompleted: isCompleted ?? set.isCompleted,
    );

    await _workoutRepo.updateWorkoutSet(updated.toCompanion(false));

    // If toggled to completed, start rest timer automatically & check for PR
    if (isCompleted == true && !set.isCompleted) {
      startRestTimer(_targetRestDuration);
      _checkForPR(set.sessionExerciseId, updated);
    }

    await _refreshCurrentSession();
  }

  /// Removes a set from an exercise.
  Future<void> deleteSet(String setId) async {
    await _workoutRepo.deleteWorkoutSet(setId);
    await _refreshCurrentSession();
  }

  Future<void> _checkForPR(String sessionExerciseId, WorkoutSet completedSet) async {
    if (_currentSession == null) return;
    final se = _currentSession!.exercises.firstWhere(
      (e) => e.sessionExercise.id == sessionExerciseId,
      orElse: () => throw StateError('Exercise not found'),
    );

    final historical =
        await _workoutRepo.getHistoricalSetsForExercise(se.exercise.id);
    final prs = WorkoutMetricsEngine.detectPersonalRecords(
      exercise: se.exercise,
      currentSets: se.sets,
      historicalSets: historical,
    );

    for (final pr in prs) {
      if (!_sessionPRs.any((p) => p.exerciseId == pr.exerciseId && p.type == pr.type)) {
        _sessionPRs.add(pr);
      }
    }
  }

  Future<void> _refreshCurrentSession() async {
    if (_currentSession == null) return;
    _currentSession =
        await _workoutRepo.getFullActiveSession(_currentSession!.session.id);
    notifyListeners();
  }

  // REST TIMER
  void startRestTimer([int durationSeconds = 90]) {
    _targetRestDuration = durationSeconds;
    _restSecondsRemaining = durationSeconds;
    _isRestTimerActive = true;
    _restTimer?.cancel();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        _restSecondsRemaining--;
        notifyListeners();
      } else {
        _isRestTimerActive = false;
        timer.cancel();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void addRestTime([int seconds = 30]) {
    _restSecondsRemaining += seconds;
    _targetRestDuration += seconds;
    _isRestTimerActive = true;
    notifyListeners();
  }

  void skipRestTimer() {
    _restTimer?.cancel();
    _restSecondsRemaining = 0;
    _isRestTimerActive = false;
    notifyListeners();
  }

  /// Finishes the active workout session and saves completion timestamp.
  Future<ActiveWorkoutSession?> finishWorkout({String? notes}) async {
    if (_currentSession == null) return null;

    final completedSession = _currentSession!;
    final now = DateTime.now();

    await _workoutRepo.completeSession(
      completedSession.session.id,
      dateEnded: now,
      notes: notes ?? completedSession.session.notes,
    );

    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _isRestTimerActive = false;
    _currentSession = null;
    _elapsedDuration = Duration.zero;
    notifyListeners();

    return completedSession;
  }

  /// Discards the active workout and deletes all unfinished records.
  Future<void> discardWorkout() async {
    if (_currentSession == null) return;

    final id = _currentSession!.session.id;
    await _workoutRepo.deleteSession(id);

    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _isRestTimerActive = false;
    _currentSession = null;
    _elapsedDuration = Duration.zero;
    _sessionPRs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}
