import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PhaseBadge extends StatelessWidget {
  const PhaseBadge({
    super.key,
    required this.phase,
    this.compact = false,
    this.onPhaseChanged,
  });

  final String phase;
  final bool compact;
  final ValueChanged<String>? onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (phase.toLowerCase()) {
      'warmup' => (AppTheme.phaseWarmup, 'Warm-up', Icons.whatshot_rounded),
      'cooldown' => (AppTheme.phaseCooldown, 'Cool-down', Icons.spa_rounded),
      'versatile' || 'multi' || 'any' => (
          AppTheme.primary,
          'Versatile',
          Icons.swap_horiz_rounded
        ),
      _ => (AppTheme.phaseWorking, 'Working', Icons.fitness_center_rounded),
    };

    final badgeContent = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: onPhaseChanged != null
              ? color.withAlpha(180)
              : color.withAlpha(100),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          if (onPhaseChanged != null) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: compact ? 14 : 16,
              color: color,
            ),
          ],
        ],
      ),
    );

    if (onPhaseChanged == null) {
      return badgeContent;
    }

    return PopupMenuButton<String>(
      tooltip: 'Switch exercise phase',
      padding: EdgeInsets.zero,
      color: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onPhaseChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'warmup',
          child: Row(
            children: [
              Icon(Icons.whatshot_rounded, color: AppTheme.phaseWarmup, size: 16),
              SizedBox(width: 8),
              Text('🔥 Warm-up Phase'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'working',
          child: Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: AppTheme.phaseWorking, size: 16),
              SizedBox(width: 8),
              Text('🏋️ Working Sets Phase'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'cooldown',
          child: Row(
            children: [
              Icon(Icons.spa_rounded, color: AppTheme.phaseCooldown, size: 16),
              SizedBox(width: 8),
              Text('🧘 Cool-down Phase'),
            ],
          ),
        ),
      ],
      child: badgeContent,
    );
  }
}
