import 'package:flutter/material.dart';
import '../../../../domain/models/exercise_dto.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/phase_badge.dart';
import '../view_models/exercise_admin_view_model.dart';

class GeminiIngestDialog extends StatefulWidget {
  const GeminiIngestDialog({
    super.key,
    required this.viewModel,
  });

  final ExerciseAdminViewModel viewModel;

  static Future<void> show(
    BuildContext context, {
    required ExerciseAdminViewModel viewModel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GeminiIngestDialog(viewModel: viewModel),
    );
  }

  @override
  State<GeminiIngestDialog> createState() => _GeminiIngestDialogState();
}

class _GeminiIngestDialogState extends State<GeminiIngestDialog> {
  final _textController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _showApiKeyInput = false;

  static const String _sampleText = '''
Dynamic Warm-up:
- Arm circles and band dislocations (shoulder warmup, resistance band)
- 90/90 hip switches (mobility, hips, bodyweight)

Push Workout:
1. Incline Dumbbell Bench Press - 4 sets of 8-10 reps. Setup bench to 30 degrees, tuck shoulder blades, drive through chest.
2. Overhead Cable Triceps Extension - 3 sets of 12-15 reps. Keep elbows high and stationary.
3. Leaning Lateral Raises - 4 sets with dumbbells for side delts.

Cool-down:
- Doorway pec stretch (hold 30s each side)
- Overhead triceps stretch
''';

  @override
  void dispose() {
    _textController.dispose();
    _apiKeyController.dispose();
    widget.viewModel.clearIngestionResults();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final results = vm.parsedIngestionResults;

        return Dialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppTheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Exercise Ingestion (Gemini)',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Extract structured exercises from raw text, programs, or notes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.cardBorder, height: 1),
                  const SizedBox(height: 16),

                  // Main Content Area
                  Expanded(
                    child: results.isEmpty
                        ? _buildInputSection(vm)
                        : _buildResultsSection(vm, results),
                  ),

                  // Bottom Action Footer
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.cardBorder, height: 1),
                  const SizedBox(height: 16),
                  _buildFooter(vm, results),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection(ExerciseAdminViewModel vm) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Paste Unstructured Workout Text:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _textController.text = _sampleText;
                },
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Load Sample Routine'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText:
                  'Paste raw workout notes, exercise lists, routines, or form cues here...\n\nExample:\n- Barbell bench press for 4 sets of 8 (Chest, barbell)\n- Cable woodchoppers for core\n- Hip flexor stretch (cooldown)',
            ),
          ),
          const SizedBox(height: 12),

          // API Key Status & Input
          if (vm.hasApiKey && !_showApiKeyInput) ...[
            InkWell(
              onTap: () => setState(() => _showApiKeyInput = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accent.withAlpha(60)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Gemini API Key configured and ready on this device',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 14),
                  ],
                ),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () => setState(() => _showApiKeyInput = !_showApiKeyInput),
              child: Row(
                children: [
                  Icon(
                    _showApiKeyInput
                        ? Icons.arrow_drop_down_rounded
                        : Icons.arrow_right_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  const Text(
                    'Gemini API Key (Enter once to save on this device)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_showApiKeyInput || !vm.hasApiKey) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key',
                        hintText: 'AIzaSy...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final key = _apiKeyController.text.trim();
                      if (key.isNotEmpty) {
                        await vm.saveApiKey(key);
                        setState(() => _showApiKeyInput = false);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ],

          if (vm.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withAlpha(100)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      vm.errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13),
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

  Widget _buildResultsSection(
    ExerciseAdminViewModel vm,
    List<ExerciseDto> results,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Extracted Exercises (${results.length})',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                vm.clearIngestionResults();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Parse New Text'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = results[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        PhaseBadge(phase: item.defaultPhase, compact: true),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 18),
                          onPressed: () => vm.removeIngestedItem(index),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildTag(Icons.category_rounded, item.category),
                        _buildTag(Icons.accessibility_new_rounded,
                            item.primaryMuscle),
                        _buildTag(Icons.fitness_center_rounded, item.equipment),
                      ],
                    ),
                    if (item.instructions != null &&
                        item.instructions!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.instructions!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFooter(
    ExerciseAdminViewModel vm,
    List<ExerciseDto> results,
  ) {
    if (results.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: vm.isIngesting
                ? null
                : () async {
                    final key = _apiKeyController.text.trim().isNotEmpty
                        ? _apiKeyController.text.trim()
                        : null;
                    await vm.parseRawWorkoutTextWithGemini(
                      _textController.text,
                      overrideApiKey: key,
                    );
                  },
            icon: vm.isIngesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0F172A),
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(vm.isIngesting ? 'Parsing with Gemini...' : 'Extract Exercises'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${results.length} items ready to save',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => vm.clearIngestionResults(),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      final count = await vm.saveParsedIngestionResults();
                      if (mounted && count > 0) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Successfully ingested $count exercises into the master library!',
                            ),
                            backgroundColor: AppTheme.accent,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text('Save ${results.length} to Master Database'),
            ),
          ],
        ),
      ],
    );
  }
}
