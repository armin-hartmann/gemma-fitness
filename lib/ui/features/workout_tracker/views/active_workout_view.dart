import 'package:flutter/material.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/exercise_repository.dart';
import '../../../../domain/models/active_workout_models.dart';
import '../../../../domain/services/workout_ai_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/phase_badge.dart';
import '../../exercise_admin/views/exercise_edit_dialog.dart';
import '../view_models/active_workout_view_model.dart';
import '../view_models/workout_templates_view_model.dart';
import 'ai_workout_generator_dialog.dart';
import 'exercise_picker_dialog.dart';
import 'workout_detail_dialog.dart';
import 'workout_preset_card.dart';
import 'workout_routine_editor_dialog.dart';
import 'workout_summary_dialog.dart';

class ActiveWorkoutView extends StatefulWidget {
  const ActiveWorkoutView({
    super.key,
    required this.viewModel,
    required this.exerciseRepository,
    required this.templatesViewModel,
    required this.aiService,
  });

  final ActiveWorkoutViewModel viewModel;
  final ExerciseRepository exerciseRepository;
  final WorkoutTemplatesViewModel templatesViewModel;
  final WorkoutAiService aiService;

  @override
  State<ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends State<ActiveWorkoutView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.initialize();
    widget.templatesViewModel.loadTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (!vm.hasActiveWorkout) {
          return _buildStartWorkoutScreen(vm);
        }

        return _buildActiveWorkoutTracker(vm);
      },
    );
  }

  // -------------------------------------------------------------
  // START WORKOUT SCREEN (PRESETS & BLANK SESSION)
  // -------------------------------------------------------------
  Widget _buildStartWorkoutScreen(ActiveWorkoutViewModel vm) {
    return ListenableBuilder(
      listenable: widget.templatesViewModel,
      builder: (context, _) {
        final templates = widget.templatesViewModel.templates;

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideHeader = constraints.maxWidth > 850;

                    final titleCol = const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to Train?',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Select a routine to inspect exercises, customize reps, or start immediately.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    );

                    final actionButtons = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _openAiGenerator,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: const Text(
                            'AI Routine Generator',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _createNewRoutine,
                          icon: const Icon(Icons.playlist_add_rounded, size: 18),
                          label: const Text('New Routine'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => vm.startBlankWorkout(),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'Empty Session',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );

                    if (isWideHeader) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleCol),
                          const SizedBox(width: 12),
                          actionButtons,
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleCol,
                        const SizedBox(height: 14),
                        actionButtons,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workout Routines',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => widget.templatesViewModel.resetToDefaults(),
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('Reset Defaults'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: templates.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final preset = templates[index];
                          return SizedBox(
                            height: 275,
                            child: WorkoutPresetCard(
                              preset: preset,
                              onInspect: () => _openWorkoutDetail(preset),
                              onStart: () => vm.startWorkoutFromPreset(preset),
                              onDelete: () =>
                                  widget.templatesViewModel.deleteTemplate(preset.id),
                            ),
                          );
                        },
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 330,
                        mainAxisExtent: 295,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                      ),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final preset = templates[index];
                        return WorkoutPresetCard(
                          preset: preset,
                          onInspect: () => _openWorkoutDetail(preset),
                          onStart: () => vm.startWorkoutFromPreset(preset),
                          onDelete: () =>
                              widget.templatesViewModel.deleteTemplate(preset.id),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openWorkoutDetail(WorkoutPreset preset) {
    WorkoutDetailDialog.show(
      context,
      preset: preset,
      exerciseRepository: widget.exerciseRepository,
      templatesViewModel: widget.templatesViewModel,
      onStartWorkout: (selectedPreset) {
        widget.viewModel.startWorkoutFromPreset(selectedPreset);
      },
    );
  }

  Future<void> _createNewRoutine() async {
    final newPreset = await WorkoutRoutineEditorDialog.show(
      context,
      exerciseRepository: widget.exerciseRepository,
    );

    if (newPreset != null) {
      await widget.templatesViewModel.saveTemplate(newPreset);
    }
  }

  void _openAiGenerator() {
    AiWorkoutGeneratorDialog.show(
      context,
      aiService: widget.aiService,
      exerciseRepository: widget.exerciseRepository,
      templatesViewModel: widget.templatesViewModel,
      onStartWorkout: (selectedPreset) {
        widget.viewModel.startWorkoutFromPreset(selectedPreset);
      },
    );
  }

  // -------------------------------------------------------------
  // ACTIVE WORKOUT TRACKER VIEW
  // -------------------------------------------------------------
  Widget _buildActiveWorkoutTracker(ActiveWorkoutViewModel vm) {
    final session = vm.currentSession!;
    final warmup = session.warmupExercises;
    final working = session.workingExercises;
    final cooldown = session.cooldownExercises;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withAlpha(90)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    vm.formattedElapsed,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                session.session.notes ?? 'Active Workout',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Volume chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.fitness_center_rounded,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  vm.currentVolume > 0
                      ? '${vm.currentVolume.toStringAsFixed(0)} kg'
                      : 'BW Sets',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Discard menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppTheme.textSecondary),
            color: AppTheme.surfaceElevated,
            onSelected: (val) {
              if (val == 'discard') {
                _confirmDiscard(vm);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'discard',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded,
                        color: Colors.redAccent, size: 18),
                    SizedBox(width: 8),
                    Text('Discard Workout',
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Finish Workout Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              final finished = await vm.finishWorkout();
              if (finished != null && mounted) {
                WorkoutSummaryDialog.show(
                  context,
                  session: finished,
                  duration: vm.elapsedDuration,
                  personalRecords: vm.sessionPRs,
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Finish'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: 100,
            ),
            children: [
              // PR Announcements if any
              if (vm.sessionPRs.isNotEmpty) ...[
                _buildPRBanner(vm.sessionPRs.last),
                const SizedBox(height: 14),
              ],

              // Voice Coach & Audio Settings Toolbar
              _buildAudioCoachBar(vm),
              const SizedBox(height: 14),

              // Warmup section
              if (warmup.isNotEmpty) ...[
                _buildPhaseHeader('🔥 Warm-up Phase', AppTheme.phaseWarmup),
                ...warmup.map((se) => _buildExerciseCard(vm, se)),
                const SizedBox(height: 18),
              ],

              // Working section
              _buildPhaseHeader('🏋️ Working Sets', AppTheme.phaseWorking),
              if (working.isEmpty)
                _buildEmptyPhaseCard('No working exercises yet.'),
              ...working.map((se) => _buildExerciseCard(vm, se)),
              const SizedBox(height: 18),

              // Cooldown section
              if (cooldown.isNotEmpty) ...[
                _buildPhaseHeader('🧘 Cool-down Phase', AppTheme.phaseCooldown),
                ...cooldown.map((se) => _buildExerciseCard(vm, se)),
                const SizedBox(height: 18),
              ],

              // Add Exercise Button
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final res = await ExercisePickerDialog.show(
                      context,
                      exerciseRepository: widget.exerciseRepository,
                    );
                    if (res != null) {
                      await vm.addExerciseToSession(
                        res.exercise,
                        phase: res.phase,
                      );
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Add Exercise to Workout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),

          // Sticky Rest Timer Bar
          if (vm.isRestTimerActive)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: _buildRestTimerBar(vm),
            ),
        ],
      ),
    );
  }

  Widget _buildPRBanner(PersonalRecord pr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Colors.amber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${pr.exerciseName}: ${pr.formattedMessage}',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPhaseCard(String message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    ActiveWorkoutViewModel vm,
    ActiveSessionExercise activeEx,
  ) {
    final ex = activeEx.exercise;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final updatedDto = await ExerciseEditDialog.show(
                        context,
                        initialExercise: ex,
                      );
                      if (updatedDto != null) {
                        await widget.exerciseRepository.updateExercise(
                          updatedDto.toCompanion(fallbackId: ex.id),
                        );
                        await vm.initialize();
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ex.primaryMuscle} • ${ex.equipment}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PhaseBadge(
                  phase: activeEx.sessionExercise.phase,
                  compact: true,
                  onPhaseChanged: (newPhase) => vm.updateExercisePhase(
                      activeEx.sessionExercise.id, newPhase),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded,
                      size: 18, color: AppTheme.primaryLight),
                  tooltip: 'Listen to form cues',
                  onPressed: () => vm.speakFormCues(ex),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppTheme.textMuted),
                  tooltip: 'Remove exercise',
                  onPressed: () =>
                      vm.removeExerciseFromSession(activeEx.sessionExercise.id),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sets Table Header
            const Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    'SET',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'KG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'REPS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'RPE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Center(
                    child: Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.cardBorder, height: 16),

            // Sets Rows
            ...activeEx.sets.map((set) => _buildSetRow(vm, set)),
            const SizedBox(height: 8),

            // Add Set Button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => vm.addSetToExercise(activeEx),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('+ Add Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(ActiveWorkoutViewModel vm, WorkoutSet set) {
    final isDone = set.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDone
                    ? AppTheme.accent.withAlpha(30)
                    : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${set.setNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDone ? AppTheme.accent : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Weight input
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: set.weight > 0 ? '${set.weight}' : '',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDone ? AppTheme.accent : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                fillColor: isDone
                    ? AppTheme.accent.withAlpha(15)
                    : AppTheme.surfaceElevated,
              ),
              onChanged: (val) {
                final d = double.tryParse(val.trim());
                vm.updateSet(set, weight: d);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Reps input
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: set.reps > 0 ? '${set.reps}' : '',
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDone ? AppTheme.accent : AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                fillColor: isDone
                    ? AppTheme.accent.withAlpha(15)
                    : AppTheme.surfaceElevated,
              ),
              onChanged: (val) {
                final r = int.tryParse(val.trim());
                vm.updateSet(set, reps: r);
              },
            ),
          ),
          const SizedBox(width: 8),

          // RPE input
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: set.rpe != null ? '${set.rpe}' : '',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'RPE',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                fillColor: isDone
                    ? AppTheme.accent.withAlpha(15)
                    : AppTheme.surfaceElevated,
              ),
              onChanged: (val) {
                final rpe = double.tryParse(val.trim());
                vm.updateSet(set, rpe: rpe);
              },
            ),
          ),
          const SizedBox(width: 8),

          // Checkbox toggle
          SizedBox(
            width: 44,
            child: IconButton(
              icon: Icon(
                isDone
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: isDone ? AppTheme.accent : AppTheme.textMuted,
                size: 24,
              ),
              onPressed: () {
                vm.updateSet(set, isCompleted: !isDone);
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // AUDIO & VOICE COACH TOOLBAR
  // -------------------------------------------------------------
  Widget _buildAudioCoachBar(ActiveWorkoutViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Voice Coach Toggle
            InkWell(
              onTap: () => vm.toggleVoiceCoach(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: vm.isVoiceCoachEnabled
                      ? AppTheme.primary.withAlpha(35)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: vm.isVoiceCoachEnabled
                        ? AppTheme.primary
                        : AppTheme.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vm.isVoiceCoachEnabled
                          ? Icons.record_voice_over_rounded
                          : Icons.voice_over_off_rounded,
                      size: 16,
                      color: vm.isVoiceCoachEnabled
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Voice Coach',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: vm.isVoiceCoachEnabled
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Sound Effects Chimes Toggle
            InkWell(
              onTap: () => vm.toggleSoundEffects(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: vm.isSoundEffectsEnabled
                      ? AppTheme.accent.withAlpha(30)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: vm.isSoundEffectsEnabled
                        ? AppTheme.accent
                        : AppTheme.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vm.isSoundEffectsEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      size: 16,
                      color: vm.isSoundEffectsEnabled
                          ? AppTheme.accent
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Chimes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: vm.isSoundEffectsEnabled
                            ? AppTheme.accent
                            : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Auto-Rest Duration Selector
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                DropdownButton<int>(
                  value: vm.targetRestDuration,
                  dropdownColor: AppTheme.surfaceElevated,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  items: const [
                    DropdownMenuItem(value: 45, child: Text('45s Rest')),
                    DropdownMenuItem(value: 60, child: Text('60s Rest')),
                    DropdownMenuItem(value: 90, child: Text('90s Rest')),
                    DropdownMenuItem(value: 120, child: Text('120s Rest')),
                    DropdownMenuItem(value: 180, child: Text('180s Rest')),
                  ],
                  onChanged: (val) {
                    if (val != null) vm.setDefaultRestDuration(val);
                  },
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Test Button
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 18, color: AppTheme.textSecondary),
              tooltip: 'Test Audio & Voice Coach',
              onPressed: () => vm.testAudioAndVoice(),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // REST TIMER FLOATING BAR
  // -------------------------------------------------------------
  Widget _buildRestTimerBar(ActiveWorkoutViewModel vm) {
    final (nextEx, nextSet) = vm.nextUpcomingExerciseAndSet;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: vm.restSecondsRemaining <= 5 ? Colors.amber : AppTheme.primary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (vm.restSecondsRemaining <= 5 ? Colors.amber : AppTheme.primary)
                .withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Circular countdown ring
              SizedBox(
                width: 46,
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: vm.restProgress,
                      backgroundColor: AppTheme.surfaceElevated,
                      color: vm.restSecondsRemaining <= 5
                          ? Colors.amber
                          : AppTheme.primary,
                      strokeWidth: 4,
                    ),
                    Icon(
                      vm.isRestPaused
                          ? Icons.pause_rounded
                          : (vm.restSecondsRemaining <= 5
                              ? Icons.whatshot_rounded
                              : Icons.timer_rounded),
                      size: 20,
                      color: vm.restSecondsRemaining <= 5
                          ? Colors.amber
                          : AppTheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Title and Big formatted timer text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          vm.isRestPaused ? 'REST PAUSED' : 'REST INTERVAL',
                          style: TextStyle(
                            fontSize: 10,
                            color: vm.isRestPaused
                                ? Colors.amber
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (vm.isVoiceCoachEnabled) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.record_voice_over_rounded,
                              size: 11, color: AppTheme.primaryLight),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vm.formattedRestRemaining,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: vm.restSecondsRemaining <= 5
                            ? Colors.amber
                            : AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick adjustments and controls
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: const BorderSide(color: AppTheme.cardBorder),
                ),
                onPressed: () => vm.subtractRestTime(15),
                child: const Text('-15s', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => vm.addRestTime(30),
                child: const Text('+30s',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: Icon(
                  vm.isRestPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: AppTheme.textPrimary,
                  size: 22,
                ),
                tooltip: vm.isRestPaused ? 'Resume Rest' : 'Pause Rest',
                onPressed: () => vm.togglePauseRest(),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded,
                    color: AppTheme.textSecondary, size: 22),
                tooltip: 'Skip Rest',
                onPressed: () => vm.skipRestTimer(),
              ),
            ],
          ),

          // Next up preview snippet
          if (nextEx != null && nextSet != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withAlpha(140),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward_rounded,
                      size: 13, color: AppTheme.primaryLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Next: ${nextEx.exercise.name} (Set ${nextSet.setNumber} · ${nextSet.reps} reps${nextSet.weight > 0 ? ' @ ${nextSet.weight == nextSet.weight.roundToDouble() ? nextSet.weight.toInt() : nextSet.weight}kg' : ''})',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDiscard(ActiveWorkoutViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Discard Workout?'),
        content: const Text(
            'Are you sure you want to discard this workout session? All logged sets will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await vm.discardWorkout();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}
