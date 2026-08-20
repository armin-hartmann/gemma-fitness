import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemma_fitness/data/database/app_database.dart';
import 'package:gemma_fitness/data/repositories/exercise_repository.dart';
import 'package:gemma_fitness/data/repositories/workout_repository.dart';
import 'package:gemma_fitness/data/services/audio_feedback_service.dart';
import 'package:gemma_fitness/data/services/exercise_sync_service.dart';
import 'package:gemma_fitness/domain/models/active_workout_models.dart';
import 'package:gemma_fitness/domain/services/voice_coach_service.dart';
import 'package:gemma_fitness/ui/features/workout_tracker/view_models/active_workout_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioService implements AudioFeedbackService {
  final List<String> audioLogs = [];

  @override
  void playCountdownTick(int secondsRemaining) {
    audioLogs.add('tick:$secondsRemaining');
  }

  @override
  void playRestComplete() {
    audioLogs.add('restComplete');
  }

  @override
  void playPrFanfare() {
    audioLogs.add('prFanfare');
  }

  @override
  void playButtonClick() {
    audioLogs.add('buttonClick');
  }
}

class MockVoiceService implements VoiceCoachService {
  final List<String> speechLogs = [];
  bool _speaking = false;

  @override
  bool get isSpeaking => _speaking;

  @override
  Future<void> speak(String text, {double rate = 1.0, double pitch = 1.0}) async {
    _speaking = true;
    speechLogs.add(text);
    _speaking = false;
  }

  @override
  Future<void> stop() async {
    _speaking = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ExerciseRepository exerciseRepo;
  late WorkoutRepository workoutRepo;
  late ExerciseSyncService syncService;
  late MockAudioService mockAudio;
  late MockVoiceService mockVoice;
  late ActiveWorkoutViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    exerciseRepo = ExerciseRepository(db);
    workoutRepo = WorkoutRepository(db);
    syncService = ExerciseSyncService(exerciseRepository: exerciseRepo);
    mockAudio = MockAudioService();
    mockVoice = MockVoiceService();

    await syncService.seedInitialExercisesIfEmpty();

    viewModel = ActiveWorkoutViewModel(
      workoutRepository: workoutRepo,
      exerciseRepository: exerciseRepo,
      audioFeedbackService: mockAudio,
      voiceCoachService: mockVoice,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await db.close();
  });

  group('ActiveWorkoutViewModel & Audio Coaching Layer', () {
    test('Can start a workout from a preset and announce start via voice coach', () async {
      final presets = WorkoutPreset.getStandardPresets();
      final homePreset = presets.first;

      final success = await viewModel.startWorkoutFromPreset(homePreset);
      expect(success, isTrue);
      expect(viewModel.hasActiveWorkout, isTrue);
      expect(viewModel.currentSession, isNotNull);

      final session = viewModel.currentSession!;
      expect(session.warmupExercises.isNotEmpty, isTrue);
      expect(session.workingExercises.isNotEmpty, isTrue);
      expect(session.cooldownExercises.isNotEmpty, isTrue);
      expect(session.allSets.isNotEmpty, isTrue);

      // Voice Coach announced workout start
      expect(mockVoice.speechLogs.any((l) => l.contains('Workout started')), isTrue);
    });

    test('Can start a blank workout, add exercises and sets, and play audio on complete', () async {
      await viewModel.startBlankWorkout(title: 'Upper Body Blast');
      expect(viewModel.hasActiveWorkout, isTrue);
      expect(viewModel.currentSession!.exercises.isEmpty, isTrue);

      final exercises = await exerciseRepo.getAllExercises();
      final bench = exercises.firstWhere((e) => e.name.contains('Push-Up'));

      // Add exercise to session
      await viewModel.addExerciseToSession(bench, phase: 'working');
      expect(viewModel.currentSession!.exercises.length, 1);

      final activeBench = viewModel.currentSession!.exercises.first;
      expect(activeBench.sets.length, 1);

      // Add second set
      await viewModel.addSetToExercise(activeBench);
      expect(viewModel.currentSession!.exercises.first.sets.length, 2);

      // Update set weight, reps, and toggle completion
      final set1 = viewModel.currentSession!.exercises.first.sets.first;
      await viewModel.updateSet(
        set1,
        weight: 0.0,
        reps: 15,
        isCompleted: true,
      );

      expect(viewModel.completedSetsCount, 1);
      expect(viewModel.isRestTimerActive, isTrue); // Rest timer automatically triggered
      expect(mockAudio.audioLogs.contains('buttonClick'), isTrue);
    });

    test('Rest timer functions with pause/resume, add/subtract time, and skip', () {
      viewModel.startRestTimer(60);
      expect(viewModel.isRestTimerActive, isTrue);
      expect(viewModel.restSecondsRemaining, 60);

      viewModel.addRestTime(30);
      expect(viewModel.restSecondsRemaining, 90);

      viewModel.subtractRestTime(15);
      expect(viewModel.restSecondsRemaining, 75);

      viewModel.togglePauseRest();
      expect(viewModel.isRestPaused, isTrue);

      viewModel.togglePauseRest();
      expect(viewModel.isRestPaused, isFalse);

      viewModel.skipRestTimer();
      expect(viewModel.isRestTimerActive, isFalse);
      expect(viewModel.restSecondsRemaining, 0);
    });

    test('Can toggle audio settings and speak form cues', () async {
      viewModel.toggleVoiceCoach(false);
      expect(viewModel.isVoiceCoachEnabled, isFalse);

      viewModel.toggleSoundEffects(false);
      expect(viewModel.isSoundEffectsEnabled, isFalse);

      viewModel.setDefaultRestDuration(120);
      expect(viewModel.targetRestDuration, 120);

      final exercises = await exerciseRepo.getAllExercises();
      final ex = exercises.first;
      await viewModel.speakFormCues(ex);

      expect(mockVoice.speechLogs.any((l) => l.contains(ex.name)), isTrue);
    });

    test('Can finish a workout session and announce completion', () async {
      await viewModel.startBlankWorkout(title: 'Leg Day');
      final session = await viewModel.finishWorkout(customSummary: 'Crushed squats');

      expect(session, isNotNull);
      expect(viewModel.hasActiveWorkout, isFalse);

      final completed = await workoutRepo.getCompletedSessions();
      expect(completed.length, 1);
      expect(completed.first.aiSummary, 'Crushed squats');
      expect(mockVoice.speechLogs.any((l) => l.contains('Workout completed')), isTrue);
    });

    test('Can discard active workout', () async {
      await viewModel.startBlankWorkout(title: 'Discard Test');
      expect(viewModel.hasActiveWorkout, isTrue);

      await viewModel.discardWorkout();
      expect(viewModel.hasActiveWorkout, isFalse);

      final all = await workoutRepo.getAllSessions();
      expect(all.isEmpty, isTrue);
    });
  });
}
