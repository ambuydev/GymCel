import 'workout_set.dart';

class WorkoutSession {
  final String id;
  final String? routineId;
  final String routineName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final String? notes;
  final double totalVolume;
  final List<WorkoutSet> sets;

  WorkoutSession({
    required this.id,
    this.routineId,
    required this.routineName,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.notes,
    this.totalVolume = 0.0,
    this.sets = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routine_id': routineId,
      'routine_name': routineName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'notes': notes,
      'total_volume': totalVolume,
    };
  }

  factory WorkoutSession.fromMap(
    Map<String, dynamic> map, {
    List<WorkoutSet> sets = const [],
  }) {
    return WorkoutSession(
      id: map['id'] as String,
      routineId: map['routine_id'] as String?,
      routineName: map['routine_name'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      notes: map['notes'] as String?,
      totalVolume: (map['total_volume'] as num?)?.toDouble() ?? 0.0,
      sets: sets,
    );
  }

  WorkoutSession copyWith({
    DateTime? endTime,
    int? durationSeconds,
    String? notes,
    double? totalVolume,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutSession(
      id: id,
      routineId: routineId,
      routineName: routineName,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
      totalVolume: totalVolume ?? this.totalVolume,
      sets: sets ?? this.sets,
    );
  }
}
