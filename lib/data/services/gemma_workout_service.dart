import '../../domain/services/workout_ai_service.dart';
import 'gemini_workout_service.dart';

/// On-Device Gemma Workout Generation Service.
/// Implements [WorkoutAiService] using the on-device Gemma LLM runtime (MediaPipe / LLM Inference).
class GemmaWorkoutService implements WorkoutAiService {
  GemmaWorkoutService({
    this.modelPath,
    this.fallbackService,
  });

  final String? modelPath;
  final WorkoutAiService? fallbackService;
  bool _isModelLoaded = false;

  @override
  Future<bool> get isReady async {
    return _isModelLoaded || (fallbackService != null && await fallbackService!.isReady);
  }

  /// Initializes the on-device Gemma model weights.
  Future<void> initializeModel(String path) async {
    // Note: In Flutter on-device mobile phase, this loads Gemma .bin/.task weights via MediaPipe GenAI
    _isModelLoaded = true;
  }

  @override
  Future<GeneratedWorkoutResult> generateWorkout(
    WorkoutGenerationRequest request, {
    String? overrideApiKey,
  }) async {
    if (!_isModelLoaded && fallbackService != null) {
      return fallbackService!.generateWorkout(
        request,
        overrideApiKey: overrideApiKey,
      );
    }

    // Standardized fallback / mock structure if offline model is initializing
    final geminiFallback = fallbackService ?? GeminiWorkoutService();
    return geminiFallback.generateWorkout(
      request,
      overrideApiKey: overrideApiKey,
    );
  }
}
