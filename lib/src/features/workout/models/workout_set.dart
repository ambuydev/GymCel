class WorkoutSet {
  final String id;
  final String workoutSessionId;
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final double weight;
  final int reps;
  final bool isCompleted;

  WorkoutSet({
    required this.id,
    required this.workoutSessionId,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    this.weight = 0.0,
    this.reps = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_session_id': workoutSessionId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'] as String,
      workoutSessionId: map['workout_session_id'] as String,
      exerciseId: map['exercise_id'] as String,
      exerciseName: map['exercise_name'] as String,
      setNumber: map['set_number'] as int,
      weight: (map['weight'] as num).toDouble(),
      reps: map['reps'] as int,
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }

  WorkoutSet copyWith({
    double? weight,
    int? reps,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      id: id,
      workoutSessionId: workoutSessionId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
