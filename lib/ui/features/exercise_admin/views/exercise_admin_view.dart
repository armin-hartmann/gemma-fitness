import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/phase_badge.dart';
import '../../../core/widgets/stat_chip.dart';
import '../view_models/exercise_admin_view_model.dart';
import 'exercise_edit_dialog.dart';
import 'gemini_ingest_dialog.dart';

class ExerciseAdminView extends StatefulWidget {
  const ExerciseAdminView({
    super.key,
    required this.viewModel,
  });

  final ExerciseAdminViewModel viewModel;

  @override
  State<ExerciseAdminView> createState() => _ExerciseAdminViewState();
}

class _ExerciseAdminViewState extends State<ExerciseAdminView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final exercises = vm.filteredExercises;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(vm),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(vm),
                      const SizedBox(height: 20),
                      _buildSearchAndFilters(vm),
                      const SizedBox(height: 16),
                      if (vm.statusMessage != null) _buildStatusBanner(vm),
                    ],
                  ),
                ),
              ),
              _buildExerciseGrid(vm, exercises),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(ExerciseAdminViewModel vm) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 70,
      backgroundColor: AppTheme.background,
      title: Row(
        children: [
          Container(
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
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gemma Fitness',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Master Exercise Library & Cloud Ingestion',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // AI Ingestion Action Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () => GeminiIngestDialog.show(context, viewModel: vm),
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('AI Ingest (Gemini)'),
        ),
        const SizedBox(width: 10),
        // Add New Exercise Button
        OutlinedButton.icon(
          onPressed: () async {
            final dto = await ExerciseEditDialog.show(context);
            if (dto != null) {
              await vm.saveExercise(dto);
            }
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New Exercise'),
        ),
        const SizedBox(width: 10),
        // Sync / Export / Import Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
          color: AppTheme.surfaceElevated,
          onSelected: (value) async {
            if (value == 'export') {
              final json = await vm.exportToJson();
              await Clipboard.setData(ClipboardData(text: json));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exercise library JSON copied to clipboard!'),
                    backgroundColor: AppTheme.accent,
                  ),
                );
              }
            } else if (value == 'reseed') {
              await vm.initialize();
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.copy_all_rounded, size: 18, color: AppTheme.textSecondary),
                  SizedBox(width: 10),
                  Text('Export JSON to Clipboard'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reseed',
              child: Row(
                children: [
                  Icon(Icons.restart_alt_rounded, size: 18, color: AppTheme.textSecondary),
                  SizedBox(width: 10),
                  Text('Re-seed Default Library'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildStatsRow(ExerciseAdminViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          StatChip(
            label: 'All Exercises',
            count: vm.totalCount,
            icon: Icons.list_alt_rounded,
            color: AppTheme.primary,
            isSelected: vm.selectedPhase == null,
            onTap: () => vm.setPhase(null),
          ),
          const SizedBox(width: 10),
          StatChip(
            label: 'Warm-up',
            count: vm.warmupCount,
            icon: Icons.whatshot_rounded,
            color: AppTheme.phaseWarmup,
            isSelected: vm.selectedPhase == 'warmup',
            onTap: () => vm.setPhase('warmup'),
          ),
          const SizedBox(width: 10),
          StatChip(
            label: 'Working Sets',
            count: vm.workingCount,
            icon: Icons.fitness_center_rounded,
            color: AppTheme.phaseWorking,
            isSelected: vm.selectedPhase == 'working',
            onTap: () => vm.setPhase('working'),
          ),
          const SizedBox(width: 10),
          StatChip(
            label: 'Cool-down',
            count: vm.cooldownCount,
            icon: Icons.spa_rounded,
            color: AppTheme.phaseCooldown,
            isSelected: vm.selectedPhase == 'cooldown',
            onTap: () => vm.setPhase('cooldown'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ExerciseAdminViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: vm.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search by exercise name, muscle, category, or equipment...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            vm.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (vm.selectedCategory != null ||
                vm.selectedMuscle != null ||
                vm.selectedPhase != null ||
                vm.searchQuery.isNotEmpty) ...[
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  vm.resetFilters();
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Reset'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Filter pills for Categories & Muscles
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text(
                'Muscles: ',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ...vm.availableMuscles.map((muscle) {
                final isSelected = vm.selectedMuscle == muscle;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(muscle),
                    selected: isSelected,
                    onSelected: (_) => vm.setMuscle(muscle),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(ExerciseAdminViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vm.statusMessage!,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseGrid(
    ExerciseAdminViewModel vm,
    List<Exercise> exercises,
  ) {
    if (vm.isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (exercises.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 64, color: AppTheme.textMuted.withAlpha(100)),
              const SizedBox(height: 16),
              const Text(
                'No exercises found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try adjusting search terms or filters, or ingest new exercises with Gemini AI.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 210,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final exercise = exercises[index];
            return _buildExerciseCard(vm, exercise);
          },
          childCount: exercises.length,
        ),
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseAdminViewModel vm, Exercise exercise) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                PhaseBadge(phase: exercise.defaultPhase, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildCardTag(Icons.category_outlined, exercise.category),
                _buildCardTag(
                    Icons.accessibility_new_outlined, exercise.primaryMuscle),
                _buildCardTag(Icons.fitness_center_outlined, exercise.equipment),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: (exercise.instructions != null &&
                      exercise.instructions!.isNotEmpty)
                  ? Text(
                      exercise.instructions!,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: AppTheme.textSecondary),
                  tooltip: 'Edit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final updatedDto = await ExerciseEditDialog.show(
                      context,
                      initialExercise: exercise,
                    );
                    if (updatedDto != null) {
                      await vm.updateExercise(updatedDto);
                    }
                  },
                ),
                const SizedBox(width: 14),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Colors.redAccent),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => vm.deleteExercise(exercise.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
