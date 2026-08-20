import 'package:flutter/material.dart';
import '../../../../domain/engine/workout_metrics_engine.dart';
import '../../../../domain/models/active_workout_models.dart';
import '../../../core/theme/app_theme.dart';

class WorkoutSummaryDialog extends StatelessWidget {
  const WorkoutSummaryDialog({
    super.key,
    required this.session,
    required this.duration,
    required this.personalRecords,
  });

  final ActiveWorkoutSession session;
  final Duration duration;
  final List<PersonalRecord> personalRecords;

  static Future<void> show(
    BuildContext context, {
    required ActiveWorkoutSession session,
    required Duration duration,
    required List<PersonalRecord> personalRecords,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WorkoutSummaryDialog(
        session: session,
        duration: duration,
        personalRecords: personalRecords,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalVol = session.totalVolume;
    final completedSets = session.totalCompletedSets;
    final totalSets = session.totalSets;
    final muscleStats =
        WorkoutMetricsEngine.calculateMuscleDistribution(session.exercises);

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppTheme.accent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Workout Complete!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  session.session.notes ?? 'Great job crushing your session!',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Stat Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: WorkoutMetricsEngine.formatDuration(duration),
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetric(
                        icon: Icons.fitness_center_rounded,
                        label: 'Total Volume',
                        value: totalVol > 0
                            ? '${totalVol.toStringAsFixed(0)} kg'
                            : 'Bodyweight',
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryMetric(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Sets Done',
                        value: '$completedSets / $totalSets',
                        color: AppTheme.phaseWarmup,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Personal Records Banner if any
                if (personalRecords.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withAlpha(90)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.workspace_premium_rounded,
                                color: Colors.amber, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Personal Records Smashed!',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...personalRecords.map((pr) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '${pr.exerciseName}: ${pr.formattedMessage}',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Muscle breakdown
                if (muscleStats.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Muscles Targeted',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: muscleStats.values.map((stat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Text(
                          '${stat.muscleName} • ${stat.completedSets} sets',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
