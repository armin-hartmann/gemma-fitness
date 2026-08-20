import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PhaseBadge extends StatelessWidget {
  const PhaseBadge({
    super.key,
    required this.phase,
    this.compact = false,
  });

  final String phase;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (phase.toLowerCase()) {
      'warmup' => (AppTheme.phaseWarmup, 'Warm-up', Icons.whatshot_rounded),
      'cooldown' => (AppTheme.phaseCooldown, 'Cool-down', Icons.spa_rounded),
      _ => (AppTheme.phaseWorking, 'Working', Icons.fitness_center_rounded),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100), width: 1),
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
        ],
      ),
    );
  }
}
