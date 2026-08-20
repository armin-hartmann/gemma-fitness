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

  @override
  Widget build(BuildContext context) {
    final warmupItems =
        _preset.exercisePhases.where((e) => e.phase == 'warmup').toList();
    final workingItems =
        _preset.exercisePhases.where((e) => e.phase == 'working').toList();
    final cooldownItems =
        _preset.exercisePhases.where((e) => e.phase == 'cooldown').toList();
    final isHome = _preset.modality == 'bodyweight';

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
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
                      '${_preset.exercisePhases.length} Exercises',
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
                    : ListView(
                        children: [
                          if (warmupItems.isNotEmpty) ...[
                            _buildPhaseSectionHeader(
                                '🔥 Warm-up Routine', AppTheme.phaseWarmup),
                            ...warmupItems.map(_buildExerciseItemCard),
                            const SizedBox(height: 14),
                          ],
                          if (workingItems.isNotEmpty) ...[
                            _buildPhaseSectionHeader(
                                '🏋️ Working Sets', AppTheme.phaseWorking),
                            ...workingItems.map(_buildExerciseItemCard),
                            const SizedBox(height: 14),
                          ],
                          if (cooldownItems.isNotEmpty) ...[
                            _buildPhaseSectionHeader(
                                '🧘 Cool-down Routine', AppTheme.phaseCooldown),
                            ...cooldownItems.map(_buildExerciseItemCard),
                            const SizedBox(height: 14),
                          ],
                        ],
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
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Edit Routine'),
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

  Widget _buildPhaseSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildExerciseItemCard(PresetExerciseItem item) {
    final masterEx = _findExerciseByName(item.exerciseName);
    final targetWeightStr = item.targetWeight != null && item.targetWeight! > 0
        ? ' @ ${item.targetWeight} kg'
        : '';
    final targetRpeStr =
        item.targetRpe != null ? ' • RPE ${item.targetRpe}' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                      PhaseBadge(phase: item.phase, compact: true),
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
                    tooltip: 'Edit exercise definition',
                    onPressed: () => _editMasterExercise(masterEx),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.targetSets} sets × ${item.targetReps} reps$targetWeightStr$targetRpeStr',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                if (masterEx != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${masterEx.primaryMuscle} • ${masterEx.equipment}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
            if (masterEx?.instructions != null &&
                masterEx!.instructions!.isNotEmpty) ...[
              const SizedBox(height: 6),
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
