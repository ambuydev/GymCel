import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/db_helper.dart';
import '../../exercises/models/exercise.dart';
import '../../routines/models/routine.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';

// Rest Timer Provider
final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;

  RestTimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.isRunning,
  });

  RestTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
  }) {
    return RestTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier()
      : super(RestTimerState(remainingSeconds: 0, totalSeconds: 90, isRunning: false));

  void startTimer({int durationSeconds = 90}) {
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: durationSeconds,
      totalSeconds: durationSeconds,
      isRunning: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        timer.cancel();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
  }

  void addSeconds(int seconds) {
    if (state.isRunning) {
      state = state.copyWith(remainingSeconds: state.remainingSeconds + seconds);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Active Workout Session Provider
final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, WorkoutSession?>((ref) {
  return ActiveWorkoutNotifier(ref);
});

class ActiveWorkoutNotifier extends StateNotifier<WorkoutSession?> {
  final Ref ref;
  Timer? _workoutTimer;

  // Store custom rest timer per exercise ID for the active session
  final Map<String, int?> _customRestMap = {};

  ActiveWorkoutNotifier(this.ref) : super(null);

  Future<void> startWorkoutFromRoutine(Routine routine) async {
    final constUuid = const Uuid();
    final sessionId = constUuid.v4();
    final startTime = DateTime.now();

    List<WorkoutSet> sets = [];
    _customRestMap.clear();

    final db = await DBHelper.instance.database;

    for (final re in routine.exercises) {
      _customRestMap[re.exerciseId] = re.restSeconds;

      // Find last weight/reps used for this exercise in history
      final lastSetMaps = await db.rawQuery('''
        SELECT weight, reps FROM workout_sets 
        WHERE exercise_id = ? AND is_completed = 1
        ORDER BY id DESC LIMIT 1
      ''', [re.exerciseId]);

      double defaultWeight = re.targetWeight > 0 ? re.targetWeight : 20.0;
      int defaultReps = re.targetReps;

      if (lastSetMaps.isNotEmpty) {
        final lastW = (lastSetMaps.first['weight'] as num).toDouble();
        if (lastW > 0) defaultWeight = lastW;
        defaultReps = lastSetMaps.first['reps'] as int;
      }

      // Add Warmup Set if enabled for this exercise (setNumber: 0 = Warmup W)
      if (re.hasWarmupSet) {
        sets.add(WorkoutSet(
          id: constUuid.v4(),
          workoutSessionId: sessionId,
          exerciseId: re.exerciseId,
          exerciseName: '${re.exercise?.name ?? "Ejercicio"} (Warm-up W)',
          setNumber: 0, // 0 indicates Warmup
          weight: re.warmupWeight > 0 ? re.warmupWeight : (defaultWeight * 0.5),
          reps: re.warmupReps > 0 ? re.warmupReps : defaultReps,
          isCompleted: false,
        ));
      }

      for (int s = 1; s <= re.targetSets; s++) {
        sets.add(WorkoutSet(
          id: constUuid.v4(),
          workoutSessionId: sessionId,
          exerciseId: re.exerciseId,
          exerciseName: re.exercise?.name ?? 'Ejercicio',
          setNumber: s,
          weight: defaultWeight,
          reps: defaultReps,
          isCompleted: false,
        ));
      }
    }

    state = WorkoutSession(
      id: sessionId,
      routineId: routine.id,
      routineName: routine.name,
      startTime: startTime,
      sets: sets,
    );

    _startDurationTimer();
  }

  Future<void> startBlankWorkout() async {
    final constUuid = const Uuid();
    final sessionId = constUuid.v4();
    final startTime = DateTime.now();
    _customRestMap.clear();

    state = WorkoutSession(
      id: sessionId,
      routineName: 'Entrenamiento Libre',
      startTime: startTime,
      sets: [],
    );

    _startDurationTimer();
  }

  void _startDurationTimer() {
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state != null) {
        final elapsed = DateTime.now().difference(state!.startTime).inSeconds;
        state = state!.copyWith(durationSeconds: elapsed);
      }
    });
  }

  Future<void> addExerciseToSession(Exercise exercise) async {
    if (state == null) return;
    final constUuid = const Uuid();

    final db = await DBHelper.instance.database;
    final lastSetMaps = await db.rawQuery('''
      SELECT weight, reps FROM workout_sets 
      WHERE exercise_id = ? AND is_completed = 1
      ORDER BY id DESC LIMIT 1
    ''', [exercise.id]);

    double defaultWeight = 20.0;
    int defaultReps = exercise.isTimeBased ? 60 : 10;

    if (lastSetMaps.isNotEmpty) {
      defaultWeight = (lastSetMaps.first['weight'] as num).toDouble();
      defaultReps = lastSetMaps.first['reps'] as int;
    }

    List<WorkoutSet> newSets = List.from(state!.sets);
    for (int s = 1; s <= 3; s++) {
      newSets.add(WorkoutSet(
        id: constUuid.v4(),
        workoutSessionId: state!.id,
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        setNumber: s,
        weight: defaultWeight,
        reps: defaultReps,
        isCompleted: false,
      ));
    }

    state = state!.copyWith(sets: newSets);
  }

  void addSetToExercise(String exerciseId, String exerciseName) {
    if (state == null) return;
    final constUuid = const Uuid();

    final exSets = state!.sets.where((s) => s.exerciseId == exerciseId).toList();
    final nextSetNumber = exSets.length + 1;
    final lastSet = exSets.isNotEmpty ? exSets.last : null;

    final newSet = WorkoutSet(
      id: constUuid.v4(),
      workoutSessionId: state!.id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: nextSetNumber,
      weight: lastSet?.weight ?? 20.0,
      reps: lastSet?.reps ?? 10,
      isCompleted: false,
    );

    state = state!.copyWith(sets: [...state!.sets, newSet]);
  }

  void removeSet(String setId) {
    if (state == null) return;
    final updatedSets = state!.sets.where((s) => s.id != setId).toList();
    state = state!.copyWith(sets: updatedSets);
  }

  void updateSet(String setId, {double? weight, int? reps}) {
    if (state == null) return;

    final updatedSets = state!.sets.map((s) {
      if (s.id == setId) {
        return s.copyWith(weight: weight ?? s.weight, reps: reps ?? s.reps);
      }
      return s;
    }).toList();

    state = state!.copyWith(sets: updatedSets);
  }

  Future<void> toggleSetCompleted(String setId) async {
    if (state == null) return;

    bool newlyCompleted = false;
    String targetExerciseId = '';

    final updatedSets = state!.sets.map((s) {
      if (s.id == setId) {
        final nextState = !s.isCompleted;
        if (nextState) {
          newlyCompleted = true;
          targetExerciseId = s.exerciseId;
        }
        return s.copyWith(isCompleted: nextState);
      }
      return s;
    }).toList();

    state = state!.copyWith(sets: updatedSets);

    if (newlyCompleted) {
      int duration = 90;
      final customRest = _customRestMap[targetExerciseId];
      if (customRest != null && customRest > 0) {
        duration = customRest;
      } else {
        final globalSetting = await DBHelper.instance.getSetting('rest_timer_seconds', defaultValue: '90');
        duration = int.tryParse(globalSetting) ?? 90;
      }

      ref.read(restTimerProvider.notifier).startTimer(durationSeconds: duration);
    }
  }

  Future<void> finishWorkout({String? notes}) async {
    if (state == null) return;

    _workoutTimer?.cancel();
    final endTime = DateTime.now();
    final durationSeconds = endTime.difference(state!.startTime).inSeconds;

    double totalVolume = 0.0;
    for (final s in state!.sets) {
      if (s.isCompleted) {
        totalVolume += (s.weight * s.reps);
      }
    }

    final finishedSession = state!.copyWith(
      endTime: endTime,
      durationSeconds: durationSeconds,
      notes: notes,
      totalVolume: totalVolume,
    );

    final db = await DBHelper.instance.database;

    await db.insert('workout_sessions', finishedSession.toMap());

    for (final set in finishedSession.sets) {
      await db.insert('workout_sets', set.toMap());
    }

    await DBHelper.instance.enforceHistoryRetentionLimit();

    _customRestMap.clear();
    state = null;
  }

  void cancelWorkout() {
    _workoutTimer?.cancel();
    _customRestMap.clear();
    state = null;
  }
}
