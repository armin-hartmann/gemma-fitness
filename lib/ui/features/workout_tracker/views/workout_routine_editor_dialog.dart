import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/repositories/exercise_repository.dart';
import '../../../../domain/models/active_workout_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/phase_badge.dart';
import 'exercise_picker_dialog.dart';

class WorkoutRoutineEditorDialog extends StatefulWidget {
  const WorkoutRoutineEditorDialog({
    super.key,
    this.initialPreset,
    required this.exerciseRepository,
  });

  final WorkoutPreset? initialPreset;
  final ExerciseRepository exerciseRepository;

  static Future<WorkoutPreset?> show(
    BuildContext context, {
    WorkoutPreset? initialPreset,
    required ExerciseRepository exerciseRepository,
  }) {
    return showDialog<WorkoutPreset>(
      context: context,
      builder: (ctx) => WorkoutRoutineEditorDialog(
        initialPreset: initialPreset,
        exerciseRepository: exerciseRepository,
      ),
    );
  }

  @override
  State<WorkoutRoutineEditorDialog> createState() =>
      _WorkoutRoutineEditorDialogState();
}

class _WorkoutRoutineEditorDialogState extends State<WorkoutRoutineEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedModality;
  late List<PresetExerciseItem> _exercises;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPreset;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _selectedModality = p?.modality ?? 'free_weights';
    _exercises = p != null ? List.from(p.exercisePhases) : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPreset != null;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Workout Routine' : 'New Custom Routine',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
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
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Routine Title *',
                    hintText: 'e.g. Full-Body Strength & Core',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Target muscle focus, pacing, or goals...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedModality,
                        decoration: const InputDecoration(labelText: 'Modality'),
                        dropdownColor: AppTheme.surfaceElevated,
                        items: const [
                          DropdownMenuItem(
                            value: 'bodyweight',
                            child: Text('🏠 No Equipment'),
                          ),
                          DropdownMenuItem(
                            value: 'free_weights',
                            child: Text('🏋️ Free Weights'),
                          ),
                          DropdownMenuItem(
                            value: 'machines',
                            child: Text('⚙️ Machines'),
                          ),
                          DropdownMenuItem(
                            value: 'hybrid',
                            child: Text('⚡ Hybrid / Mixed'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedModality = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercises (${_exercises.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      onPressed: _pickExerciseToAdd,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Exercise'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _exercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.fitness_center_rounded,
                                  size: 40, color: AppTheme.textMuted),
                              const SizedBox(height: 10),
                              const Text(
                                'No exercises in this routine yet.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: _pickExerciseToAdd,
                                child: const Text('+ Add First Exercise'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _exercises.length,
                          itemBuilder: (context, index) {
                            final item = _exercises[index];
                            return _buildExerciseEditorTile(index, item);
                          },
                        ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: _saveRoutine,
                      child: const Text(
                        'Save Routine',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseEditorTile(int index, PresetExerciseItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.surfaceElevated,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                PhaseBadge(phase: item.phase, compact: true),
                const SizedBox(width: 10),
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
                // Phase selector dropdown
                DropdownButton<String>(
                  value: item.phase,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppTheme.surface,
                  items: const [
                    DropdownMenuItem(value: 'warmup', child: Text('Warm-up')),
                    DropdownMenuItem(value: 'working', child: Text('Working')),
                    DropdownMenuItem(value: 'cooldown', child: Text('Cool-down')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _exercises[index] = item.copyWith(phase: val);
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Colors.redAccent),
                  tooltip: 'Remove',
                  onPressed: () {
                    setState(() => _exercises.removeAt(index));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Target sets
                Expanded(
                  child: TextFormField(
                    initialValue: '${item.targetSets}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      if (n != null && n > 0) {
                        _exercises[index] = item.copyWith(targetSets: n);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Target reps
                Expanded(
                  child: TextFormField(
                    initialValue: '${item.targetReps}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      if (n != null && n > 0) {
                        _exercises[index] = item.copyWith(targetReps: n);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Target weight (optional)
                Expanded(
                  child: TextFormField(
                    initialValue:
                        item.targetWeight != null ? '${item.targetWeight}' : '',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      isDense: true,
                      hintText: 'BW',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) {
                      final d = double.tryParse(v.trim());
                      _exercises[index] = item.copyWith(targetWeight: d);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Target RPE (optional)
                Expanded(
                  child: TextFormField(
                    initialValue: item.targetRpe != null ? '${item.targetRpe}' : '',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'RPE',
                      isDense: true,
                      hintText: '1-10',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) {
                      final d = double.tryParse(v.trim());
                      _exercises[index] = item.copyWith(targetRpe: d);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExerciseToAdd() async {
    final result = await ExercisePickerDialog.show(
      context,
      exerciseRepository: widget.exerciseRepository,
    );

    if (result != null) {
      setState(() {
        _exercises.add(
          PresetExerciseItem(
            exerciseName: result.exercise.name,
            phase: result.phase,
            targetSets: result.phase == 'warmup' ? 2 : 3,
            targetReps: 10,
            targetWeight:
                result.exercise.requiresEquipment ? 20.0 : null,
            targetRpe: result.phase == 'working' ? 8.0 : null,
          ),
        );
      });
    }
  }

  void _saveRoutine() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one exercise to the routine.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final preset = WorkoutPreset(
        id: widget.initialPreset?.id ?? _uuid.v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        modality: _selectedModality,
        exercisePhases: _exercises,
        iconName: _selectedModality == 'bodyweight' ? 'home' : 'fitness_center',
        isCustom: true,
      );

      Navigator.of(context).pop(preset);
    }
  }
}
