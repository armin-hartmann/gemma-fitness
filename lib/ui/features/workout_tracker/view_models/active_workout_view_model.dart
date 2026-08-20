import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/exercise_repository.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/audio_feedback_service.dart';
import '../../../../data/services/cross_platform_voice_coach_service.dart';
import '../../../../domain/engine/workout_metrics_engine.dart';
import '../../../../domain/models/active_workout_models.dart';
import '../../../../domain/services/voice_coach_service.dart';

class ActiveWorkoutViewModel extends ChangeNotifier {
  ActiveWorkoutViewModel({
    required WorkoutRepository workoutRepository,
    required ExerciseRepository exerciseRepository,
    AudioFeedbackService? audioFeedbackService,
    VoiceCoachService? voiceCoachService,
  })  : _workoutRepo = workoutRepository,
        _exerciseRepo = exerciseRepository,
        _audioService = audioFeedbackService ?? AudioFeedbackService(),
        _voiceCoach = voiceCoachService ?? CrossPlatformVoiceCoachService();

  final WorkoutRepository _workoutRepo;
  final ExerciseRepository _exerciseRepo;
  final AudioFeedbackService _audioService;
  final VoiceCoachService _voiceCoach;
  final _uuid = const Uuid();

  ActiveWorkoutSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;

  // Elapsed Workout Timer
  Timer? _sessionTimer;
  Duration _elapsedDuration = Duration.zero;

  // Smart Rest Interval Timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  int _targetRestDuration = 90;
  bool _isRestTimerActive = false;
  bool _isRestPaused = false;

  // Audio & Voice Coach Settings
  bool _isVoiceCoachEnabled = true;
  bool _isSoundEffectsEnabled = true;
  bool _isAutoRestEnabled = true;

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
  bool get isRestPaused => _isRestPaused;

  bool get isVoiceCoachEnabled => _isVoiceCoachEnabled;
  bool get isSoundEffectsEnabled => _isSoundEffectsEnabled;
  bool get isAutoRestEnabled => _isAutoRestEnabled;

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

  /// Returns the next pending exercise and set for preview during rest.
  (ActiveSessionExercise?, WorkoutSet?) get nextUpcomingExerciseAndSet {
    if (_currentSession == null) return (null, null);
    for (final ex in _currentSession!.exercises) {
      for (final s in ex.sets) {
        if (!s.isCompleted) {
          return (ex, s);
        }
      }
    }
    return (null, null);
  }

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

      for (int i = 0; i < preset.exercisePhases.length; i++) {
        final presetItem = preset.exercisePhases[i];
        final exercise = await _exerciseRepo.getExerciseByName(presetItem.exerciseName);

        String exerciseId;
        if (exercise == null) {
          exerciseId = _uuid.v4();
          await _exerciseRepo.insertExercise(
            ExercisesCompanion.insert(
              id: exerciseId,
              name: presetItem.exerciseName,
              category: 'General',
              primaryMuscle: 'Full Body',
              equipment: 'Bodyweight',
              defaultPhase: Value(presetItem.phase),
            ),
          );
        } else {
          exerciseId = exercise.id;
        }

        final sessionExerciseId = _uuid.v4();
        await _workoutRepo.insertSessionExercise(
          SessionExercisesCompanion.insert(
            id: sessionExerciseId,
            sessionId: sessionId,
            exerciseId: exerciseId,
            phase: Value(presetItem.phase),
            orderInSession: Value(i + 1),
          ),
        );

        for (int setNum = 1; setNum <= presetItem.targetSets; setNum++) {
          await _workoutRepo.insertWorkoutSet(
            WorkoutSetsCompanion.insert(
              id: _uuid.v4(),
              sessionExerciseId: sessionExerciseId,
              setNumber: setNum,
              setType: Value(presetItem.phase == 'warmup' ? 'warmup' : 'normal'),
              reps: Value(presetItem.targetReps),
              weight: presetItem.targetWeight != null
                  ? Value(presetItem.targetWeight!)
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

      if (_isVoiceCoachEnabled) {
        _voiceCoach.speak('Workout started: ${preset.title}. Let\'s make it count!');
      }

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

      if (_isVoiceCoachEnabled) {
        _voiceCoach.speak('Quick workout started. Ready for your first exercise.');
      }

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
        setType: Value(activeExercise.sessionExercise.phase == 'warmup'
            ? 'warmup'
            : 'normal'),
        reps: Value(lastSet?.reps ?? 10),
        weight: Value(lastSet?.weight ?? 0.0),
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
      if (_isSoundEffectsEnabled) {
        _audioService.playButtonClick();
      }
      if (_isAutoRestEnabled) {
        startRestTimer(_targetRestDuration);
      }
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
        if (_isSoundEffectsEnabled) {
          _audioService.playPrFanfare();
        }
        if (_isVoiceCoachEnabled) {
          _voiceCoach.speak('Awesome! New Personal Record on ${se.exercise.name}!');
        }
      }
    }
  }

  Future<void> _refreshCurrentSession() async {
    if (_currentSession == null) return;
    _currentSession =
        await _workoutRepo.getFullActiveSession(_currentSession!.session.id);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // SMART REST TIMER WITH AUDIO CUES & VOICE ANNOUNCER
  // -------------------------------------------------------------
  void startRestTimer([int? durationSeconds]) {
    final duration = durationSeconds ?? _targetRestDuration;
    _targetRestDuration = duration;
    _restSecondsRemaining = duration;
    _isRestTimerActive = true;
    _isRestPaused = false;
    _restTimer?.cancel();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRestPaused) return;

      if (_restSecondsRemaining > 0) {
        _restSecondsRemaining--;
        // Countdown ticks at 3s, 2s, 1s
        if (_isSoundEffectsEnabled && _restSecondsRemaining <= 3 && _restSecondsRemaining > 0) {
          _audioService.playCountdownTick(_restSecondsRemaining);
        }
        notifyListeners();
      } else {
        _isRestTimerActive = false;
        timer.cancel();
        _onRestCompleted();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void _onRestCompleted() {
    if (_isSoundEffectsEnabled) {
      _audioService.playRestComplete();
    }

    if (_isVoiceCoachEnabled) {
      final (nextEx, nextSet) = nextUpcomingExerciseAndSet;
      if (nextEx != null && nextSet != null) {
        final weightStr = nextSet.weight > 0
            ? ' at ${nextSet.weight == nextSet.weight.roundToDouble() ? nextSet.weight.toInt() : nextSet.weight} kilograms'
            : '';
        _voiceCoach.speak('Rest complete. Up next: ${nextEx.exercise.name}, set ${nextSet.setNumber}, ${nextSet.reps} reps$weightStr.');
      } else {
        _voiceCoach.speak('Rest complete. All sets completed!');
      }
    }
  }

  void addRestTime([int seconds = 30]) {
    _restSecondsRemaining += seconds;
    _targetRestDuration += seconds;
    if (!_isRestTimerActive) {
      startRestTimer(_restSecondsRemaining);
    } else {
      notifyListeners();
    }
  }

  void subtractRestTime([int seconds = 15]) {
    if (_restSecondsRemaining > seconds) {
      _restSecondsRemaining -= seconds;
    } else {
      _restSecondsRemaining = 1;
    }
    notifyListeners();
  }

  void togglePauseRest() {
    _isRestPaused = !_isRestPaused;
    notifyListeners();
  }

  void skipRestTimer() {
    _restTimer?.cancel();
    _isRestTimerActive = false;
    _isRestPaused = false;
    _restSecondsRemaining = 0;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // AUDIO & VOICE COACH SETTINGS & ACTIONS
  // -------------------------------------------------------------
  void toggleVoiceCoach([bool? enabled]) {
    _isVoiceCoachEnabled = enabled ?? !_isVoiceCoachEnabled;
    notifyListeners();
  }

  void toggleSoundEffects([bool? enabled]) {
    _isSoundEffectsEnabled = enabled ?? !_isSoundEffectsEnabled;
    notifyListeners();
  }

  void toggleAutoRest([bool? enabled]) {
    _isAutoRestEnabled = enabled ?? !_isAutoRestEnabled;
    notifyListeners();
  }

  void setDefaultRestDuration(int seconds) {
    _targetRestDuration = seconds;
    notifyListeners();
  }

  Future<void> speakFormCues(Exercise exercise) async {
    final cues = (exercise.instructions != null && exercise.instructions!.isNotEmpty)
        ? exercise.instructions!
        : 'Perform ${exercise.name} with controlled tempo, maintaining full range of motion.';
    await _voiceCoach.speak('${exercise.name}. $cues');
  }

  Future<void> testAudioAndVoice() async {
    if (_isSoundEffectsEnabled) {
      _audioService.playRestComplete();
    }
    if (_isVoiceCoachEnabled) {
      await _voiceCoach.speak('Voice coach connected. Audio cues are operational!');
    }
  }

  // -------------------------------------------------------------
  // WORKOUT COMPLETION & SUMMARY
  // -------------------------------------------------------------
  Future<ActiveWorkoutSession?> finishWorkout({String? customSummary}) async {
    if (_currentSession == null) return null;

    final sessionId = _currentSession!.session.id;
    final endedAt = DateTime.now();

    final summary = customSummary ??
        WorkoutMetricsEngine.generateWorkoutSummary(
          session: _currentSession!.session,
          exercises: _currentSession!.exercises,
          duration: _elapsedDuration,
          prs: _sessionPRs,
        );

    await _workoutRepo.completeSession(
      sessionId,
      dateEnded: endedAt,
      aiSummary: summary,
    );

    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _isRestTimerActive = false;

    if (_isVoiceCoachEnabled) {
      _voiceCoach.speak('Workout completed! Total volume ${currentVolume.toStringAsFixed(0)} kilograms across $completedSetsCount sets. Outstanding effort!');
    }

    final finishedSession = await _workoutRepo.getFullActiveSession(sessionId);
    _currentSession = null;
    _elapsedDuration = Duration.zero;
    notifyListeners();
    return finishedSession;
  }

  Future<void> discardWorkout() async {
    if (_currentSession == null) return;
    final sessionId = _currentSession!.session.id;
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _isRestTimerActive = false;
    _voiceCoach.stop();

    await _workoutRepo.deleteSession(sessionId);
    _currentSession = null;
    _elapsedDuration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _voiceCoach.stop();
    super.dispose();
  }
}
