import 'package:flutter/material.dart';
import '../../../../domain/engine/workout_metrics_engine.dart';
import '../../../../domain/models/active_workout_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/phase_badge.dart';
import '../view_models/workout_history_view_model.dart';

class WorkoutHistoryView extends StatefulWidget {
  const WorkoutHistoryView({
    super.key,
    required this.viewModel,
  });

  final WorkoutHistoryViewModel viewModel;

  @override
  State<WorkoutHistoryView> createState() => _WorkoutHistoryViewState();
}

class _WorkoutHistoryViewState extends State<WorkoutHistoryView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadHistory();
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

        final sessions = vm.completedSessions;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            automaticallyImplyLeading: false,
            title: const Row(
              children: [
                Icon(Icons.history_rounded, color: AppTheme.primary, size: 22),
                SizedBox(width: 10),
                Text(
                  'Workout History & Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppTheme.textSecondary),
                tooltip: 'Refresh History',
                onPressed: () => vm.loadHistory(),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: sessions.isEmpty
              ? _buildEmptyHistory()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Lifetime Summary Banner
                      _buildLifetimeStats(vm),
                      const SizedBox(height: 20),
                      const Text(
                        'Past Sessions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...sessions.map((s) => _buildSessionHistoryCard(vm, s)),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_rounded,
              size: 64, color: AppTheme.textMuted.withAlpha(80)),
          const SizedBox(height: 16),
          const Text(
            'No completed workouts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete your first workout in the Active Tracker tab to see logs here!',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLifetimeStats(WorkoutHistoryViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workouts Completed',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vm.totalWorkoutsCount}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.cardBorder),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lifetime Volume',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.allTimeVolume > 0
                      ? '${(vm.allTimeVolume / 1000).toStringAsFixed(1)}k kg'
                      : '0 kg',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistoryCard(
    WorkoutHistoryViewModel vm,
    ActiveWorkoutSession s,
  ) {
    final session = s.session;
    final dateStr =
        '${session.dateStarted.year}-${session.dateStarted.month.toString().padLeft(2, '0')}-${session.dateStarted.day.toString().padLeft(2, '0')}';
    final duration = session.dateEnded != null
        ? session.dateEnded!.difference(session.dateStarted)
        : Duration.zero;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fitness_center_rounded,
              color: AppTheme.primary, size: 20),
        ),
        title: Text(
          session.notes ?? 'Workout Session',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(dateStr,
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              const Text('•',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              Text(
                WorkoutMetricsEngine.formatDuration(duration),
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Text('•',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(width: 8),
              Text(
                s.totalVolume > 0
                    ? '${s.totalVolume.toStringAsFixed(0)} kg'
                    : 'Bodyweight',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: Colors.redAccent, size: 18),
          tooltip: 'Delete Log',
          onPressed: () => vm.deleteWorkout(session.id),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AppTheme.cardBorder),
                const SizedBox(height: 6),
                ...s.exercises.map((se) => _buildLoggedExerciseDetails(se)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedExerciseDetails(ActiveSessionExercise activeEx) {
    final completedSets = activeEx.sets.where((s) => s.isCompleted).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activeEx.exercise.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              PhaseBadge(phase: activeEx.sessionExercise.phase, compact: true),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: completedSets.map((s) {
              final wStr = s.weight > 0 ? '${s.weight}kg x ' : '';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  'Set ${s.setNumber}: $wStr${s.reps} reps${s.rpe != null ? " @RPE ${s.rpe}" : ""}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
