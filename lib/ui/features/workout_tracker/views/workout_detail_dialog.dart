import 'package:flutter/material.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/exercise_repository.dart';
import '../../../../domain/models/active_workout_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/phase_badge.dart';
import '../../exercise_admin/views/exercise_edit_dialog.dart';
import '../view_models/workout_templates_view_model.dart';
import 'workout_routine_editor_dialog.dart';

class WorkoutDetailDialog extends StatefulWidget {
  const WorkoutDetailDialog({
    super.key,
    required this.preset,
    required this.exerciseRepository,
    required this.templatesViewModel,
    required this.onStartWorkout,
  });

  final WorkoutPreset preset;
  final ExerciseRepository exerciseRepository;
  final WorkoutTemplatesViewModel templatesViewModel;
  final void Function(WorkoutPreset preset) onStartWorkout;

  static Future<void> show(
    BuildContext context, {
    required WorkoutPreset preset,
    required ExerciseRepository exerciseRepository,
    required WorkoutTemplatesViewModel templatesViewModel,
    required void Function(WorkoutPreset preset) onStartWorkout,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => WorkoutDetailDialog(
        preset: preset,
        exerciseRepository: exerciseRepository,
        templatesViewModel: templatesViewModel,
        onStartWorkout: onStartWorkout,
      ),
    );
  }

  @override
  State<WorkoutDetailDialog> createState() => _WorkoutDetailDialogState();
}

class _WorkoutDetailDialogState extends State<WorkoutDetailDialog> {
  late WorkoutPreset _preset;
  List<Exercise> _allExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preset = widget.preset;
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final exercises = await widget.exerciseRepository.getAllExercises();
    if (mounted) {
      setState(() {
        _allExercises = exercises;
        _isLoading = false;
      });
    }
  }

  Exercise? _findExerciseByName(String name) {
    return _allExercises.cast<Exercise?>().firstWhere(
          (e) => e?.name.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
  }

  Future<void> _updateItemSets(int exerciseIndex, int newSets) async {
    final updatedList = List<PresetExerciseItem>.from(_preset.exercisePhases);
    updatedList[exerciseIndex] =
        updatedList[exerciseIndex].copyWith(targetSets: newSets);
    final updatedPreset = _preset.copyWith(exercisePhases: updatedList);

    setState(() => _preset = updatedPreset);
    await widget.templatesViewModel.saveTemplate(updatedPreset);
  }

  Future<void> _updateItemReps(int exerciseIndex, int newReps) async {
    final updatedList = List<PresetExerciseItem>.from(_preset.exercisePhases);
    updatedList[exerciseIndex] =
        updatedList[exerciseIndex].copyWith(targetReps: newReps);
    final updatedPreset = _preset.copyWith(exercisePhases: updatedList);

    setState(() => _preset = updatedPreset);
    await widget.templatesViewModel.saveTemplate(updatedPreset);
  }

  Future<void> _updateItemWeight(int exerciseIndex, double? newWeight) async {
    final updatedList = List<PresetExerciseItem>.from(_preset.exercisePhases);
    updatedList[exerciseIndex] =
        updatedList[exerciseIndex].copyWith(targetWeight: newWeight);
    final updatedPreset = _preset.copyWith(exercisePhases: updatedList);

    setState(() => _preset = updatedPreset);
    await widget.templatesViewModel.saveTemplate(updatedPreset);
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _preset.modality == 'bodyweight';

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isHome
                          ? AppTheme.accent.withAlpha(30)
                          : AppTheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isHome ? Icons.home_rounded : Icons.fitness_center_rounded,
                      color: isHome ? AppTheme.accent : AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _preset.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _preset.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
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

              // Badges row
              Wrap(
                spacing: 8,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHome
                          ? AppTheme.accent.withAlpha(25)
                          : AppTheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHome
                            ? AppTheme.accent.withAlpha(80)
                            : AppTheme.primary.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      isHome
                          ? '🏠 No Equipment Required'
                          : '🏋️ Free Weights / Equipment',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isHome ? AppTheme.accent : AppTheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Text(
                      '${_preset.exercisePhases.length} Exercises (Editable below)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.cardBorder),

              // Exercise List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      )
                    : ListView.builder(
                        itemCount: _preset.exercisePhases.length,
                        itemBuilder: (context, index) {
                          final item = _preset.exercisePhases[index];
                          final isFirstOfPhase = index == 0 ||
                              _preset.exercisePhases[index - 1].phase !=
                                  item.phase;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isFirstOfPhase)
                                _buildPhaseSectionHeader(item.phase),
                              _buildInteractiveExerciseCard(index, item),
                            ],
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: _openRoutineEditor,
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Routine Structure'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onStartWorkout(_preset);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text(
                      'Start Workout',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseSectionHeader(String phase) {
    String title;
    Color color;
    switch (phase) {
      case 'warmup':
        title = '🔥 Warm-up Routine';
        color = AppTheme.phaseWarmup;
        break;
      case 'cooldown':
        title = '🧘 Cool-down Routine';
        color = AppTheme.phaseCooldown;
        break;
      default:
        title = '🏋️ Working Sets';
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

  Widget _buildInteractiveExerciseCard(int index, PresetExerciseItem item) {
    final masterEx = _findExerciseByName(item.exerciseName);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      PhaseBadge(
                        phase: item.phase,
                        compact: true,
                        onPhaseChanged: (newPhase) =>
                            _updateExercisePhase(index, newPhase),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.exerciseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit Master Exercise Button
                if (masterEx != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: AppTheme.textSecondary),
                    tooltip: 'Edit exercise details (name, instructions, equipment)',
                    onPressed: () => _editMasterExercise(masterEx),
                  ),
              ],
            ),
            if (masterEx != null) ...[
              const SizedBox(height: 2),
              Text(
                '${masterEx.primaryMuscle} • ${masterEx.equipment}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 10),

            // INTERACTIVE SETS & REPS CONTROLS
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Sets Stepper
                _buildStepper(
                  label: 'sets',
                  value: item.targetSets,
                  min: 1,
                  max: 20,
                  onChanged: (newVal) => _updateItemSets(index, newVal),
                ),

                // Reps Stepper
                _buildStepper(
                  label: 'reps',
                  value: item.targetReps,
                  min: 1,
                  max: 100,
                  onChanged: (newVal) => _updateItemReps(index, newVal),
                ),

                // Weight Tag / Stepper
                _buildWeightButton(
                  weight: item.targetWeight,
                  onChanged: (newWeight) =>
                      _updateItemWeight(index, newWeight),
                ),
              ],
            ),

            if (masterEx?.instructions != null &&
                masterEx!.instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                masterEx.instructions!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
          InkWell(
            onTap: () => _promptNumberInput(
              title: 'Edit Target $label',
              currentValue: value,
              onSave: onChanged,
            ),
            child: Padding(
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

    return InkWell(
      onTap: () => _promptWeightInput(
        currentWeight: weight,
        onSave: onChanged,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
            const SizedBox(width: 4),
            const Icon(Icons.edit_rounded,
                size: 12, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  void _promptNumberInput({
    required String title,
    required int currentValue,
    required void Function(int val) onSave,
  }) {
    final controller = TextEditingController(text: '$currentValue');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Value'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              if (n != null && n > 0) {
                onSave(n);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _promptWeightInput({
    required double? currentWeight,
    required void Function(double? val) onSave,
  }) {
    final controller = TextEditingController(
        text: currentWeight != null && currentWeight > 0
            ? '$currentWeight'
            : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Edit Target Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Target Weight (kg)',
                hintText: 'Leave empty for Bodyweight',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                onSave(null);
              } else {
                final d = double.tryParse(text);
                onSave(d);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editMasterExercise(Exercise exercise) async {
    final updatedDto = await ExerciseEditDialog.show(
      context,
      initialExercise: exercise,
    );

    if (updatedDto != null) {
      await widget.exerciseRepository.updateExercise(
        updatedDto.toCompanion(fallbackId: exercise.id),
      );
      await _loadExercises();
    }
  }

  Future<void> _updateExercisePhase(int index, String newPhase) async {
    final updatedList = List<PresetExerciseItem>.from(_preset.exercisePhases);
    updatedList[index] = updatedList[index].copyWith(phase: newPhase);

    // Re-sort list by phase order (warmup -> working -> cooldown)
    const order = {'warmup': 0, 'working': 1, 'cooldown': 2};
    updatedList.sort(
        (a, b) => (order[a.phase] ?? 1).compareTo(order[b.phase] ?? 1));

    final updatedPreset = _preset.copyWith(exercisePhases: updatedList);
    setState(() => _preset = updatedPreset);
    await widget.templatesViewModel.saveTemplate(updatedPreset);
  }

  Future<void> _openRoutineEditor() async {
    final updated = await WorkoutRoutineEditorDialog.show(
      context,
      initialPreset: _preset,
      exerciseRepository: widget.exerciseRepository,
    );

    if (updated != null) {
      await widget.templatesViewModel.saveTemplate(updated);
      setState(() => _preset = updated);
    }
  }
}
