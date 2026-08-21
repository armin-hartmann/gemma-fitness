import 'package:flutter/material.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/repositories/exercise_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/phase_badge.dart';

class ExercisePickerResult {
  const ExercisePickerResult({
    required this.exercise,
    required this.phase,
  });

  final Exercise exercise;
  final String phase;
}

class ExercisePickerDialog extends StatefulWidget {
  const ExercisePickerDialog({
    super.key,
    required this.exerciseRepository,
    this.initialPhase = 'working',
  });

  final ExerciseRepository exerciseRepository;
  final String initialPhase;

  static Future<ExercisePickerResult?> show(
    BuildContext context, {
    required ExerciseRepository exerciseRepository,
    String initialPhase = 'working',
  }) {
    return showDialog<ExercisePickerResult>(
      context: context,
      builder: (ctx) => ExercisePickerDialog(
        exerciseRepository: exerciseRepository,
        initialPhase: initialPhase,
      ),
    );
  }

  @override
  State<ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<ExercisePickerDialog> {
  final _searchController = TextEditingController();
  List<Exercise> _allExercises = [];
  bool _isLoading = true;
  String? _selectedModality; // 'no_equipment', 'free_weights', 'machines'
  late String _selectedPhase;

  @override
  void initState() {
    super.initState();
    _selectedPhase = widget.initialPhase;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exercise> get _filteredExercises {
    final q = _searchController.text.trim().toLowerCase();
    return _allExercises.where((e) {
      if (q.isNotEmpty) {
        final matches = e.name.toLowerCase().contains(q) ||
            e.primaryMuscle.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.equipment.toLowerCase().contains(q);
        if (!matches) return false;
      }

      if (_selectedModality == 'no_equipment') {
        if (e.requiresEquipment && e.equipment.toLowerCase() != 'bodyweight') {
          return false;
        }
      } else if (_selectedModality == 'free_weights') {
        final eq = e.equipment.toLowerCase();
        if (!eq.contains('barbell') &&
            !eq.contains('dumbbell') &&
            !eq.contains('kettlebell')) {
          return false;
        }
      } else if (_selectedModality == 'machines') {
        final eq = e.equipment.toLowerCase();
        if (!eq.contains('machine') && !eq.contains('cable')) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Add Exercise to Workout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

              // Phase assignment dropdown/toggle
              Row(
                children: [
                  const Text(
                    'Assign to Phase: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedPhase,
                    dropdownColor: AppTheme.surfaceElevated,
                    items: const [
                      DropdownMenuItem(value: 'warmup', child: Text('🔥 Warm-up')),
                      DropdownMenuItem(value: 'working', child: Text('🏋️ Working Sets')),
                      DropdownMenuItem(value: 'cooldown', child: Text('🧘 Cool-down')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPhase = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search field
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by exercise name, muscle, or equipment...',
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              // Modality filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    const SizedBox(width: 6),
                    _buildFilterChip('🏠 No Equipment (Home)', 'no_equipment'),
                    const SizedBox(width: 6),
                    _buildFilterChip('🏋️ Free Weights', 'free_weights'),
                    const SizedBox(width: 6),
                    _buildFilterChip('⚙️ Machines', 'machines'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Exercise List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      )
                    : _filteredExercises.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching exercises found.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _filteredExercises.length,
                            separatorBuilder: (ctx, index) => const Divider(
                              color: AppTheme.cardBorder,
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final ex = _filteredExercises[index];
                              final isHomeBw = !ex.requiresEquipment ||
                                  ex.equipment.toLowerCase() == 'bodyweight';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                title: Text(
                                  ex.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      '${ex.primaryMuscle} • ${ex.equipment}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isHomeBw)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent.withAlpha(30),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Home',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PhaseBadge(
                                      phase: ex.defaultPhase,
                                      compact: true,
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: AppTheme.primary,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).pop(
                                    ExercisePickerResult(
                                      exercise: ex,
                                      phase: _selectedPhase,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? modality) {
    final isSelected = _selectedModality == modality;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedModality = modality),
    );
  }
}
