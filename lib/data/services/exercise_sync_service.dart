import 'dart:convert';
import '../../domain/models/exercise_dto.dart';
import '../repositories/exercise_repository.dart';

class ExerciseSyncService {
  ExerciseSyncService({required ExerciseRepository exerciseRepository})
      : _exerciseRepo = exerciseRepository;

  final ExerciseRepository _exerciseRepo;

  /// Checks if the exercises table is empty, and if so, seeds it with foundational master exercises.
  Future<int> seedInitialExercisesIfEmpty() async {
    final existing = await _exerciseRepo.getAllExercises();
    if (existing.isNotEmpty) {
      return 0;
    }

    final seeds = getCuratedMasterLibrary();
    final companions = seeds.map((dto) => dto.toCompanion()).toList();
    await _exerciseRepo.bulkUpsertExercises(companions);
    return companions.length;
  }

  /// Exports current exercises in the database to a formatted JSON string.
  Future<String> exportExercisesToJson() async {
    final exercises = await _exerciseRepo.getAllExercises();
    final dtos = exercises.map(ExerciseDto.fromExercise).toList();
    final jsonList = dtos.map((d) => d.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  /// Imports and bulk-upserts exercises from a JSON string.
  Future<int> importExercisesFromJson(String jsonString) async {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON array of exercises.');
    }

    final dtos = decoded
        .whereType<Map<String, dynamic>>()
        .map((m) => ExerciseDto.fromJson(m))
        .toList();

    final companions = dtos.map((dto) => dto.toCompanion()).toList();
    await _exerciseRepo.bulkUpsertExercises(companions);
    return companions.length;
  }

  /// Comprehensive, structured starter catalog spanning all phases, muscle groups, and modalities.
  static List<ExerciseDto> getCuratedMasterLibrary() {
    return [
      // WARM-UP PHASE
      ExerciseDto(
        id: 'seed-warmup-01',
        name: 'World\'s Greatest Stretch',
        category: 'Mobility',
        primaryMuscle: 'Hips & Thoracic',
        equipment: 'Bodyweight',
        instructions:
            'Step into a deep lunge with both hands inside front foot. Rotate torso reaching front-side arm to the ceiling. Hold for 2 seconds and switch sides.',
        defaultPhase: 'warmup',
      ),
      ExerciseDto(
        id: 'seed-warmup-02',
        name: 'Cat-Cow Stretch',
        category: 'Mobility',
        primaryMuscle: 'Spine & Core',
        equipment: 'Bodyweight',
        instructions:
            'Start on all fours. Inhale and arch back downward while lifting chest (Cow). Exhale and round spine toward ceiling while tucking chin (Cat).',
        defaultPhase: 'warmup',
      ),
      ExerciseDto(
        id: 'seed-warmup-03',
        name: 'Band Pull-Aparts',
        category: 'Activation',
        primaryMuscle: 'Rear Delts & Upper Back',
        equipment: 'Resistance Band',
        instructions:
            'Hold a resistance band at shoulder height with straight arms. Pull band across chest by squeezing shoulder blades together.',
        defaultPhase: 'warmup',
      ),
      ExerciseDto(
        id: 'seed-warmup-04',
        name: 'Bodyweight Squats',
        category: 'Activation',
        primaryMuscle: 'Quads & Glutes',
        equipment: 'Bodyweight',
        instructions:
            'Stand shoulder-width apart. Lower hips down and back with chest proud. Drive through whole foot to stand tall.',
        defaultPhase: 'warmup',
      ),
      ExerciseDto(
        id: 'seed-warmup-05',
        name: 'Thoracic Foam Rolling',
        category: 'Mobility',
        primaryMuscle: 'Upper Back',
        equipment: 'Foam Roller',
        instructions:
            'Lie with foam roller across upper back, hands supporting head. Gently roll from mid-back to shoulder blades, pausing on tight spots.',
        defaultPhase: 'warmup',
      ),

      // WORKING PHASE - CHEST & PUSH
      ExerciseDto(
        id: 'seed-working-01',
        name: 'Barbell Bench Press',
        category: 'Strength',
        primaryMuscle: 'Chest',
        equipment: 'Barbell',
        instructions:
            'Grip barbell slightly wider than shoulder width. Retract scapulae, unrack, lower under control to mid-chest, then press explosively.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-02',
        name: 'Incline Dumbbell Press',
        category: 'Hypertrophy',
        primaryMuscle: 'Upper Chest',
        equipment: 'Dumbbell',
        instructions:
            'Set bench at 30-45 degrees. Press dumbbells up over upper chest with palms facing forward or semi-neutral, lowering with 3-second tempo.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-03',
        name: 'Standing Overhead Barbell Press',
        category: 'Strength',
        primaryMuscle: 'Shoulders',
        equipment: 'Barbell',
        instructions:
            'Start with bar resting on front delts. Brace core and glutes, press bar overhead in a vertical path, finishing with head pushed slightly through.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-04',
        name: 'Cable Chest Fly',
        category: 'Hypertrophy',
        primaryMuscle: 'Chest',
        equipment: 'Cable',
        instructions:
            'Set pulleys at shoulder level. Bring handles together in front with slight elbow bend. Emphasize a deep stretch and peak contraction.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-05',
        name: 'Parallel Bar Dips',
        category: 'Strength',
        primaryMuscle: 'Triceps & Chest',
        equipment: 'Bodyweight',
        instructions:
            'Support body on dip bars. Lean torso forward for chest emphasis or stay upright for triceps. Lower until elbows reach 90 degrees.',
        defaultPhase: 'working',
      ),

      // WORKING PHASE - BACK & PULL
      ExerciseDto(
        id: 'seed-working-06',
        name: 'Conventional Barbell Deadlift',
        category: 'Strength',
        primaryMuscle: 'Posterior Chain',
        equipment: 'Barbell',
        instructions:
            'Stand with mid-foot under bar. Hinge hips back to grip bar, set lats tight, drive floor away, extending hips and knees simultaneously.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-07',
        name: 'Barbell Bent-Over Row',
        category: 'Strength',
        primaryMuscle: 'Upper Back & Lats',
        equipment: 'Barbell',
        instructions:
            'Hinge forward at 45 degrees with neutral spine. Pull bar toward lower ribcage by driving elbows toward the ceiling.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-08',
        name: 'Lat Pulldown',
        category: 'Hypertrophy',
        primaryMuscle: 'Lats',
        equipment: 'Cable',
        instructions:
            'Sit with thighs anchored. Grip wide and pull bar down to upper chest while depressing shoulder blades and keeping chest lifted.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-09',
        name: 'Seated Cable Row',
        category: 'Hypertrophy',
        primaryMuscle: 'Mid Back',
        equipment: 'Cable',
        instructions:
            'Sit upright with knees slightly bent. Pull handle into stomach, pinching shoulder blades together at peak contraction.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-10',
        name: 'Dumbbell Incline Bicep Curl',
        category: 'Hypertrophy',
        primaryMuscle: 'Biceps',
        equipment: 'Dumbbell',
        instructions:
            'Lie back on 45-degree incline. Let arms hang vertically to stretch long head of bicep, then curl dumbbells up without swinging shoulders.',
        defaultPhase: 'working',
      ),

      // WORKING PHASE - LEGS & LOWER BODY
      ExerciseDto(
        id: 'seed-working-11',
        name: 'Barbell Back Squat',
        category: 'Strength',
        primaryMuscle: 'Quads & Glutes',
        equipment: 'Barbell',
        instructions:
            'Position bar on upper traps. Descend with hips back and knees tracking toes until hip crease is below knee level. Drive up powerfully.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-12',
        name: 'Romanian Deadlift (RDL)',
        category: 'Hypertrophy',
        primaryMuscle: 'Hamstrings & Glutes',
        equipment: 'Barbell',
        instructions:
            'Hold bar at hips with slight knee bend. Push hips back horizontally while lowering bar along shins until hamstrings are fully stretched.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-13',
        name: 'Bulgarian Split Squat',
        category: 'Hypertrophy',
        primaryMuscle: 'Quads & Glutes',
        equipment: 'Dumbbell',
        instructions:
            'Place rear foot on bench behind you. Lower front thigh until parallel to ground, keeping weight in front heel.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-14',
        name: 'Leg Press',
        category: 'Hypertrophy',
        primaryMuscle: 'Quads',
        equipment: 'Machine',
        instructions:
            'Sit securely with back flat on pad. Place feet hip-width on sled. Lower sled under control until knees reach 90 degrees, then press away.',
        defaultPhase: 'working',
      ),
      ExerciseDto(
        id: 'seed-working-15',
        name: 'Standing Calf Raise',
        category: 'Hypertrophy',
        primaryMuscle: 'Calves',
        equipment: 'Machine',
        instructions:
            'Position balls of feet on block with heels dropped into full stretch. Explode onto toes, hold peak contraction for 1 second.',
        defaultPhase: 'working',
      ),

      // COOL-DOWN PHASE
      ExerciseDto(
        id: 'seed-cooldown-01',
        name: 'Pigeon Pose / Glute Stretch',
        category: 'Flexibility',
        primaryMuscle: 'Glutes & Hip Rotators',
        equipment: 'Bodyweight',
        instructions:
            'Bring one knee forward and angle shin across mat. Extend rear leg straight back. Fold torso forward over front shin and breathe deeply.',
        defaultPhase: 'cooldown',
      ),
      ExerciseDto(
        id: 'seed-cooldown-02',
        name: 'Standing Quad & Hip Flexor Stretch',
        category: 'Flexibility',
        primaryMuscle: 'Quads & Hip Flexors',
        equipment: 'Bodyweight',
        instructions:
            'Stand on one leg, grab opposite ankle behind you. Tuck pelvis under and gently pull heel toward glute until quad stretches.',
        defaultPhase: 'cooldown',
      ),
      ExerciseDto(
        id: 'seed-cooldown-03',
        name: 'Doorway Chest & Bicep Stretch',
        category: 'Flexibility',
        primaryMuscle: 'Chest & Anterior Delts',
        equipment: 'Bodyweight',
        instructions:
            'Place forearm against door frame at 90-degree angle. Step forward and turn body away until comfortable stretch is felt across chest.',
        defaultPhase: 'cooldown',
      ),
      ExerciseDto(
        id: 'seed-cooldown-04',
        name: 'Child\'s Pose with Lat Reach',
        category: 'Flexibility',
        primaryMuscle: 'Lats & Spine',
        equipment: 'Bodyweight',
        instructions:
            'Kneel with big toes touching and knees wide. Sit hips back onto heels, reach arms forward, and walk hands diagonally to stretch each lat.',
        defaultPhase: 'cooldown',
      ),
    ];
  }
}
