import 'package:flutter/material.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../features/exercise_admin/view_models/exercise_admin_view_model.dart';
import '../../features/exercise_admin/views/exercise_admin_view.dart';
import '../../features/workout_tracker/view_models/active_workout_view_model.dart';
import '../../features/workout_tracker/view_models/workout_history_view_model.dart';
import '../../features/workout_tracker/views/active_workout_view.dart';
import '../../features/workout_tracker/views/workout_history_view.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.exerciseAdminViewModel,
    required this.activeWorkoutViewModel,
    required this.workoutHistoryViewModel,
    required this.exerciseRepository,
  });

  final ExerciseAdminViewModel exerciseAdminViewModel;
  final ActiveWorkoutViewModel activeWorkoutViewModel;
  final WorkoutHistoryViewModel workoutHistoryViewModel;
  final ExerciseRepository exerciseRepository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        final screens = [
          ActiveWorkoutView(
            viewModel: widget.activeWorkoutViewModel,
            exerciseRepository: widget.exerciseRepository,
          ),
          ExerciseAdminView(
            viewModel: widget.exerciseAdminViewModel,
          ),
          WorkoutHistoryView(
            viewModel: widget.workoutHistoryViewModel,
          ),
        ];

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppTheme.surface,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Color(0xFF0F172A),
                        size: 24,
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.play_circle_outline_rounded),
                      selectedIcon: Icon(Icons.play_circle_fill_rounded,
                          color: AppTheme.primary),
                      label: Text('Workout'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon:
                          Icon(Icons.menu_book_rounded, color: AppTheme.primary),
                      label: Text('Library'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon:
                          Icon(Icons.history_rounded, color: AppTheme.primary),
                      label: Text('History'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: AppTheme.cardBorder),
                Expanded(child: screens[_currentIndex]),
              ],
            ),
          );
        }

        // Mobile / Small Screen Layout
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: AppTheme.surface,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.play_circle_outline_rounded),
                selectedIcon: Icon(Icons.play_circle_fill_rounded,
                    color: AppTheme.primary),
                label: 'Workout',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon:
                    Icon(Icons.menu_book_rounded, color: AppTheme.primary),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon:
                    Icon(Icons.history_rounded, color: AppTheme.primary),
                label: 'History',
              ),
            ],
          ),
        );
      },
    );
  }
}
