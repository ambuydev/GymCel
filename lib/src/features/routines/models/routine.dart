import '../../exercises/models/exercise.dart';

class RoutineExercise {
  final String id;
  final String routineId;
  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int executionSeconds; // Time Under Tension execution time per set
  final int? restSeconds; // Custom rest seconds or null for global default
  final bool hasWarmupSet; // Optional warm-up set before effective sets
  final int warmupReps;
  final double warmupWeight;
  final int warmupExecutionSeconds;
  final int warmupRestSeconds;
  final int orderIndex;
  final Exercise? exercise;

  RoutineExercise({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight = 0.0,
    this.executionSeconds = 45,
    this.restSeconds,
    this.hasWarmupSet = false,
    this.warmupReps = 10,
    this.warmupWeight = 10.0,
    this.warmupExecutionSeconds = 30,
    this.warmupRestSeconds = 60,
    this.orderIndex = 0,
    this.exercise,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routine_id': routineId,
      'exercise_id': exerciseId,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'execution_seconds': executionSeconds,
      'rest_seconds': restSeconds,
      'has_warmup_set': hasWarmupSet ? 1 : 0,
      'warmup_reps': warmupReps,
      'warmup_weight': warmupWeight,
      'warmup_execution_seconds': warmupExecutionSeconds,
      'warmup_rest_seconds': warmupRestSeconds,
      'order_index': orderIndex,
    };
  }

  factory RoutineExercise.fromMap(Map<String, dynamic> map, {Exercise? exercise}) {
    return RoutineExercise(
      id: map['id'] as String,
      routineId: map['routine_id'] as String,
      exerciseId: map['exercise_id'] as String,
      targetSets: map['target_sets'] as int? ?? 3,
      targetReps: map['target_reps'] as int? ?? 10,
      targetWeight: (map['target_weight'] as num?)?.toDouble() ?? 0.0,
      executionSeconds: map['execution_seconds'] as int? ?? 45,
      restSeconds: map['rest_seconds'] as int?,
      hasWarmupSet: (map['has_warmup_set'] as int?) == 1,
      warmupReps: map['warmup_reps'] as int? ?? 10,
      warmupWeight: (map['warmup_weight'] as num?)?.toDouble() ?? 10.0,
      warmupExecutionSeconds: map['warmup_execution_seconds'] as int? ?? 30,
      warmupRestSeconds: map['warmup_rest_seconds'] as int? ?? 60,
      orderIndex: map['order_index'] as int? ?? 0,
      exercise: exercise,
    );
  }

  RoutineExercise copyWith({
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    int? executionSeconds,
    int? restSeconds,
    bool? hasWarmupSet,
    int? warmupReps,
    double? warmupWeight,
    int? warmupExecutionSeconds,
    int? warmupRestSeconds,
    int? orderIndex,
    Exercise? exercise,
  }) {
    return RoutineExercise(
      id: id,
      routineId: routineId,
      exerciseId: exerciseId,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      executionSeconds: executionSeconds ?? this.executionSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      hasWarmupSet: hasWarmupSet ?? this.hasWarmupSet,
      warmupReps: warmupReps ?? this.warmupReps,
      warmupWeight: warmupWeight ?? this.warmupWeight,
      warmupExecutionSeconds: warmupExecutionSeconds ?? this.warmupExecutionSeconds,
      warmupRestSeconds: warmupRestSeconds ?? this.warmupRestSeconds,
      orderIndex: orderIndex ?? this.orderIndex,
      exercise: exercise ?? this.exercise,
    );
  }
}

class Routine {
  final String id;
  final String name;
  final String? description;
  final List<String> targetDays; // e.g. ['Lun', 'Mié', 'Vie']
  final DateTime createdAt;
  final List<RoutineExercise> exercises;

  Routine({
    required this.id,
    required this.name,
    this.description,
    this.targetDays = const [],
    required this.createdAt,
    this.exercises = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'target_days': targetDays.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map, {List<RoutineExercise> exercises = const []}) {
    final daysString = map['target_days'] as String? ?? '';
    final daysList = daysString.isNotEmpty ? daysString.split(',') : <String>[];

    return Routine(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      targetDays: daysList,
      createdAt: DateTime.parse(map['created_at'] as String),
      exercises: exercises,
    );
  }
}
