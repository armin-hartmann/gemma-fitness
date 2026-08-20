import 'package:flutter/material.dart';
import '../../../../domain/models/active_workout_models.dart';
import '../../../core/theme/app_theme.dart';

class WorkoutPresetCard extends StatefulWidget {
  const WorkoutPresetCard({
    super.key,
    required this.preset,
    required this.onInspect,
    required this.onStart,
    required this.onDelete,
  });

  final WorkoutPreset preset;
  final VoidCallback onInspect;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  @override
  State<WorkoutPresetCard> createState() => _WorkoutPresetCardState();
}

class _WorkoutPresetCardState extends State<WorkoutPresetCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final isHome = preset.modality == 'bodyweight';
    final accentColor = isHome ? AppTheme.accent : AppTheme.primary;
    final totalExercises = preset.exercisePhases.length;
    final previewExercises = preset.exercisePhases.take(3).toList();
    final remainingCount = totalExercises - previewExercises.length;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.surfaceElevated : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? accentColor.withAlpha(180)
                : AppTheme.cardBorder,
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: accentColor.withAlpha(45),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onInspect,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header: Title & Modality Tag
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          preset.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? accentColor.withAlpha(40)
                              : accentColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isHovered
                                ? accentColor.withAlpha(120)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isHome
                                  ? Icons.home_rounded
                                  : Icons.fitness_center_rounded,
                              size: 11,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isHome ? 'No Equipment' : 'Free Weights',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (preset.isCustom) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.redAccent),
                          tooltip: 'Delete custom routine',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    preset.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Exercise Content Preview List
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withAlpha(140),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.cardBorder.withAlpha(60),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...previewExercises.map((ex) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getPhaseDotColor(ex.phase),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      ex.exerciseName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${ex.targetSets}×${ex.targetReps}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (remainingCount > 0) ...[
                            const SizedBox(height: 3),
                            Text(
                              '+ $remainingCount more exercises',
                              style: TextStyle(
                                fontSize: 10,
                                color: accentColor.withAlpha(220),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Bottom Action Button: Start Workout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: _isHovered ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: widget.onStart,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text(
                        'Start Workout',
                        style: TextStyle(
                          fontSize: 12,
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
      ),
    );
  }

  Color _getPhaseDotColor(String phase) {
    switch (phase) {
      case 'warmup':
        return AppTheme.phaseWarmup;
      case 'cooldown':
        return AppTheme.phaseCooldown;
      default:
        return AppTheme.phaseWorking;
    }
  }
}
