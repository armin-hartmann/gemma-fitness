import 'package:flutter/material.dart';
import '../../../../data/repositories/exercise_repository.dart';
import '../../../../domain/models/active_workout_models.dart';
import '../../../../domain/services/workout_ai_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/phase_badge.dart';
import '../view_models/ai_workout_generator_view_model.dart';
import '../view_models/workout_templates_view_model.dart';

class AiWorkoutGeneratorDialog extends StatefulWidget {
  const AiWorkoutGeneratorDialog({
    super.key,
    required this.aiService,
    required this.exerciseRepository,
    required this.templatesViewModel,
    required this.onStartWorkout,
  });

  final WorkoutAiService aiService;
  final ExerciseRepository exerciseRepository;
  final WorkoutTemplatesViewModel templatesViewModel;
  final void Function(WorkoutPreset preset) onStartWorkout;

  static Future<void> show(
    BuildContext context, {
    required WorkoutAiService aiService,
    required ExerciseRepository exerciseRepository,
    required WorkoutTemplatesViewModel templatesViewModel,
    required void Function(WorkoutPreset preset) onStartWorkout,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AiWorkoutGeneratorDialog(
        aiService: aiService,
        exerciseRepository: exerciseRepository,
        templatesViewModel: templatesViewModel,
        onStartWorkout: onStartWorkout,
      ),
    );
  }

  @override
  State<AiWorkoutGeneratorDialog> createState() =>
      _AiWorkoutGeneratorDialogState();
}

class _AiWorkoutGeneratorDialogState extends State<AiWorkoutGeneratorDialog> {
  late final AiWorkoutGeneratorViewModel _viewModel;
  final TextEditingController _customPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = AiWorkoutGeneratorViewModel(
      aiService: widget.aiService,
      exerciseRepository: widget.exerciseRepository,
      templatesViewModel: widget.templatesViewModel,
    );
  }

  @override
  void dispose() {
    _customPromptController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _savePresetAndClose() async {
    final saved = await _viewModel.saveGeneratedPreset();
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${saved.title}" to routines!'),
          backgroundColor: AppTheme.accent,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _savePresetAndStart() async {
    final saved = await _viewModel.saveGeneratedPreset();
    if (saved != null && mounted) {
      Navigator.of(context).pop();
      widget.onStartWorkout(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.isGenerating) {
                return _buildGeneratingView();
              }

              if (_viewModel.generatedResult != null) {
                return _buildResultView();
              }

              return _buildQuestionnaireView();
            },
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // QUESTIONNAIRE VIEW
  // -------------------------------------------------------------
  Widget _buildQuestionnaireView() {
    final goals = [
      'Hypertrophy',
      'Strength',
      'Fat Loss',
      'Mobility & Recovery',
      'Endurance',
      'HIIT',
    ];
    final modalities = [
      {'id': 'bodyweight', 'label': '🏠 Zero Equipment'},
      {'id': 'free_weights', 'label': '🏋️ Free Weights'},
      {'id': 'machines', 'label': '⚙️ Gym Machines'},
      {'id': 'hybrid', 'label': '⚡ Hybrid / Mixed'},
    ];
    final durations = [15, 30, 45, 60];
    final muscles = [
      'Full Body',
      'Chest',
      'Back',
      'Shoulders',
      'Arms',
      'Quads & Hamstrings',
      'Glutes',
      'Core / Abs',
    ];
    final levels = [
      {'id': 'beginner', 'label': 'Beginner'},
      {'id': 'intermediate', 'label': 'Intermediate'},
      {'id': 'advanced', 'label': 'Advanced'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Workout Generator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Designed by Gemini / Gemma for your goals',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: AppTheme.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.cardBorder),

        // Scrollable Questionnaire Content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            children: [
              // Error banner if any
              if (_viewModel.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withAlpha(90)),
                  ),
                  child: Text(
                    _viewModel.errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 1. Training Goal
              _buildSectionTitle('1. Training Goal'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: goals.map((goal) {
                  final isSelected = _viewModel.selectedGoal == goal;
                  return ChoiceChip(
                    label: Text(goal),
                    selected: isSelected,
                    selectedColor: AppTheme.primary.withAlpha(50),
                    onSelected: (_) => _viewModel.setGoal(goal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // 2. Equipment Modality
              _buildSectionTitle('2. Available Equipment'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: modalities.map((m) {
                  final id = m['id']!;
                  final label = m['label']!;
                  final isSelected = _viewModel.selectedModality == id;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AppTheme.accent.withAlpha(50),
                    onSelected: (_) => _viewModel.setModality(id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // 3. Target Muscles
              _buildSectionTitle('3. Target Muscle Groups'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: muscles.map((muscle) {
                  final isSelected =
                      _viewModel.selectedMuscles.contains(muscle);
                  return FilterChip(
                    label: Text(muscle),
                    selected: isSelected,
                    selectedColor: AppTheme.primary.withAlpha(50),
                    onSelected: (_) => _viewModel.toggleMuscle(muscle),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // 4. Duration & Level
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('4. Time Available'),
                        Wrap(
                          spacing: 8,
                          children: durations.map((dur) {
                            final isSelected =
                                _viewModel.selectedDuration == dur;
                            return ChoiceChip(
                              label: Text('$dur min'),
                              selected: isSelected,
                              selectedColor: AppTheme.primary.withAlpha(50),
                              onSelected: (_) => _viewModel.setDuration(dur),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('5. Fitness Level'),
                        Wrap(
                          spacing: 8,
                          children: levels.map((lvl) {
                            final id = lvl['id']!;
                            final label = lvl['label']!;
                            final isSelected =
                                _viewModel.selectedFitnessLevel == id;
                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: AppTheme.accent.withAlpha(50),
                              onSelected: (_) => _viewModel.setFitnessLevel(id),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 6. Custom Instructions / Notes
              _buildSectionTitle('6. Special Focus / Injuries / Cues (Optional)'),
              TextField(
                controller: _customPromptController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. "I only have a pair of 15kg dumbbells", "Knee-friendly, no jumping", "Focus on upper chest"...',
                ),
                onChanged: (val) => _viewModel.setCustomInstructions(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bottom Generate Button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF0F172A),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _viewModel.generateWorkout(),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text(
                  'Generate Routine',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // GENERATING VIEW (ANIMATED LOADING)
  // -------------------------------------------------------------
  Widget _buildGeneratingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(80),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF0F172A),
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Designing Your Custom Routine...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Balancing warm-up mobility, target muscle volume, and recovery cool-down.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surfaceElevated,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // RESULT & REVIEW VIEW
  // -------------------------------------------------------------
  Widget _buildResultView() {
    final result = _viewModel.generatedResult!;
    final isHome = result.modality == 'bodyweight';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isHome
                              ? AppTheme.accent.withAlpha(30)
                              : AppTheme.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isHome ? '🏠 No Equipment' : '🏋️ Free Weights',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                isHome ? AppTheme.accent : AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '✨ AI Generated Routine',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: AppTheme.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // AI Reasoning Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withAlpha(60)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.psychology_alt_rounded,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.reasoning,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Exercises List
        Expanded(
          child: ListView.builder(
            itemCount: result.exercises.length,
            itemBuilder: (context, index) {
              final item = result.exercises[index];
              final isFirstOfPhase = index == 0 ||
                  result.exercises[index - 1].presetItem.phase !=
                      item.presetItem.phase;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isFirstOfPhase)
                    _buildPhaseSectionHeader(item.presetItem.phase),
                  _buildExerciseItemCard(index, item),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Actions
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _savePresetAndStart,
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text(
                      'Start Workout Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewModel.generateWorkout(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Regenerate'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _savePresetAndClose,
                          icon: const Icon(Icons.bookmark_add_rounded,
                              size: 16),
                          label: const Text(
                            'Save Routine',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _viewModel.generateWorkout(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Regenerate'),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _savePresetAndClose,
                      icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                      label: const Text('Save to My Routines'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _savePresetAndStart,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text(
                        'Start Workout Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhaseSectionHeader(String phase) {
    String title;
    Color color;
    switch (phase) {
      case 'warmup':
        title = '🔥 Warm-up Mobility & Prep';
        color = AppTheme.phaseWarmup;
        break;
      case 'cooldown':
        title = '🧘 Cool-down Restorative Stretches';
        color = AppTheme.phaseCooldown;
        break;
      default:
        title = '🏋️ Main Working Sets';
        color = AppTheme.phaseWorking;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildExerciseItemCard(int index, GeneratedExerciseItem item) {
    final p = item.presetItem;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhaseBadge(
                  phase: p.phase,
                  compact: true,
                  onPhaseChanged: (newPhase) =>
                      _viewModel.updateExercisePhase(index, newPhase),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.exerciseName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (item.newExerciseDefinition != null)
                  Text(
                    '${item.newExerciseDefinition!.primaryMuscle} • ${item.newExerciseDefinition!.equipment}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Inline Steppers
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Sets Stepper
                _buildStepper(
                  label: 'sets',
                  value: p.targetSets,
                  min: 1,
                  max: 20,
                  onChanged: (val) => _viewModel.updateExerciseSets(index, val),
                ),

                // Reps Stepper
                _buildStepper(
                  label: 'reps',
                  value: p.targetReps,
                  min: 1,
                  max: 100,
                  onChanged: (val) => _viewModel.updateExerciseReps(index, val),
                ),

                // Weight Button
                _buildWeightButton(
                  weight: p.targetWeight,
                  onChanged: (val) =>
                      _viewModel.updateExerciseWeight(index, val),
                ),
              ],
            ),

            if (item.coachingCue != null && item.coachingCue!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      size: 14, color: AppTheme.primaryLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.coachingCue!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required void Function(int val) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 14),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            constraints: const BoxConstraints(),
            color: value > min ? AppTheme.primary : AppTheme.textMuted,
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              '$value $label',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 14),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            constraints: const BoxConstraints(),
            color: value < max ? AppTheme.primary : AppTheme.textMuted,
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildWeightButton({
    required double? weight,
    required void Function(double? val) onChanged,
  }) {
    final hasWeight = weight != null && weight > 0;
    final displayStr = hasWeight
        ? '${weight == weight.roundToDouble() ? weight.toInt() : weight} kg'
        : 'Bodyweight';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasWeight
            ? AppTheme.accent.withAlpha(20)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasWeight
              ? AppTheme.accent.withAlpha(80)
              : AppTheme.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasWeight ? Icons.fitness_center_rounded : Icons.person_rounded,
            size: 13,
            color: hasWeight ? AppTheme.accent : AppTheme.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            displayStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: hasWeight ? AppTheme.accent : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
