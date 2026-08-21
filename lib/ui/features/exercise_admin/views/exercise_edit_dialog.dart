import 'package:flutter/material.dart';
import '../../../../data/database/app_database.dart';
import '../../../../domain/models/exercise_dto.dart';
import '../../../core/theme/app_theme.dart';

class ExerciseEditDialog extends StatefulWidget {
  const ExerciseEditDialog({
    super.key,
    this.initialExercise,
  });

  final Exercise? initialExercise;

  static Future<ExerciseDto?> show(
    BuildContext context, {
    Exercise? initialExercise,
  }) {
    return showDialog<ExerciseDto>(
      context: context,
      builder: (ctx) => ExerciseEditDialog(initialExercise: initialExercise),
    );
  }

  @override
  State<ExerciseEditDialog> createState() => _ExerciseEditDialogState();
}

class _ExerciseEditDialogState extends State<ExerciseEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _muscleController;
  late TextEditingController _equipmentController;
  late TextEditingController _instructionsController;
  late String _selectedPhase;
  late bool _requiresEquipment;

  @override
  void initState() {
    super.initState();
    final init = widget.initialExercise;
    _nameController = TextEditingController(text: init?.name ?? '');
    _categoryController =
        TextEditingController(text: init?.category ?? 'Strength');
    _muscleController =
        TextEditingController(text: init?.primaryMuscle ?? 'Chest');
    _equipmentController =
        TextEditingController(text: init?.equipment ?? 'Barbell');
    _instructionsController =
        TextEditingController(text: init?.instructions ?? '');
    _selectedPhase = init?.defaultPhase ?? 'working';
    _requiresEquipment = init?.requiresEquipment ??
        (_equipmentController.text.trim().toLowerCase() != 'bodyweight');

    _equipmentController.addListener(() {
      final isBw = _equipmentController.text.trim().toLowerCase() == 'bodyweight';
      if (isBw && _requiresEquipment) {
        setState(() => _requiresEquipment = false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _muscleController.dispose();
    _equipmentController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialExercise != null;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: AppTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight: screenHeight * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Exercise' : 'New Master Exercise',
                      style: const TextStyle(
                        fontSize: 19,
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
              const Divider(color: AppTheme.cardBorder, height: 1),
              const SizedBox(height: 12),

              // Scrollable Form Fields
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 420;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Exercise Name *',
                                hintText: 'e.g. Incline Dumbbell Press',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // Category & Muscle
                            if (isNarrow) ...[
                              TextFormField(
                                controller: _categoryController,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  hintText: 'e.g. Strength',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Category required'
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _muscleController,
                                decoration: const InputDecoration(
                                  labelText: 'Primary Muscle *',
                                  hintText: 'e.g. Chest',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Muscle required'
                                        : null,
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _categoryController,
                                      decoration: const InputDecoration(
                                        labelText: 'Category *',
                                        hintText: 'e.g. Strength',
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Category required'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _muscleController,
                                      decoration: const InputDecoration(
                                        labelText: 'Primary Muscle *',
                                        hintText: 'e.g. Chest',
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Muscle required'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Equipment & Phase
                            if (isNarrow) ...[
                              TextFormField(
                                controller: _equipmentController,
                                decoration: const InputDecoration(
                                  labelText: 'Equipment *',
                                  hintText: 'e.g. Barbell',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Equipment required'
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedPhase,
                                decoration: const InputDecoration(
                                  labelText: 'Default Phase',
                                ),
                                dropdownColor: AppTheme.surfaceElevated,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'warmup',
                                    child: Text('🔥 Warm-up',
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'working',
                                    child: Text('🏋️ Working Sets',
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cooldown',
                                    child: Text('🧘 Cool-down',
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'versatile',
                                    child: Text('⚡ Versatile',
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedPhase = val);
                                  }
                                },
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _equipmentController,
                                      decoration: const InputDecoration(
                                        labelText: 'Equipment *',
                                        hintText: 'e.g. Barbell',
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Equipment required'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _selectedPhase,
                                      decoration: const InputDecoration(
                                        labelText: 'Default Phase',
                                      ),
                                      dropdownColor: AppTheme.surfaceElevated,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'warmup',
                                          child: Text('🔥 Warm-up',
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ),
                                        DropdownMenuItem(
                                          value: 'working',
                                          child: Text('🏋️ Working',
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ),
                                        DropdownMenuItem(
                                          value: 'cooldown',
                                          child: Text('🧘 Cool-down',
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ),
                                        DropdownMenuItem(
                                          value: 'versatile',
                                          child: Text('⚡ Versatile',
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedPhase = val);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Equipment Requirement Toggle
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _requiresEquipment
                                        ? Icons.fitness_center_rounded
                                        : Icons.home_rounded,
                                    size: 18,
                                    color: _requiresEquipment
                                        ? AppTheme.primary
                                        : AppTheme.accent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _requiresEquipment
                                              ? 'Requires Equipment'
                                              : 'Zero Equipment (Home)',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          _requiresEquipment
                                              ? 'Gym gear, weights, or machines needed'
                                              : 'Bodyweight routine',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Switch(
                                    value: _requiresEquipment,
                                    activeTrackColor: AppTheme.primary,
                                    onChanged: (val) {
                                      setState(
                                          () => _requiresEquipment = val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _instructionsController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Instructions & Form Cues',
                                hintText:
                                    'Setup, posture cues, range of motion, and breathing instructions...',
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: AppTheme.cardBorder, height: 1),
              const SizedBox(height: 12),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: _submit,
                    child: Text(
                      isEditing ? 'Save Changes' : 'Create Exercise',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final dto = ExerciseDto(
        id: widget.initialExercise?.id,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        primaryMuscle: _muscleController.text.trim(),
        equipment: _equipmentController.text.trim(),
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        defaultPhase: _selectedPhase,
        requiresEquipment: _requiresEquipment,
      );
      Navigator.of(context).pop(dto);
    }
  }
}
