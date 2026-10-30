import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/db_helper.dart';
import '../../exercises/models/exercise.dart';
import '../models/routine.dart';

final routineListProvider = StateNotifierProvider<RoutineNotifier, List<Routine>>((ref) {
  return RoutineNotifier()..loadRoutines();
});

class RoutineNotifier extends StateNotifier<List<Routine>> {
  RoutineNotifier() : super([]);

  Future<void> loadRoutines() async {
    final db = await DBHelper.instance.database;
    final routineMaps = await db.query('routines', orderBy: 'created_at DESC');

    List<Routine> routinesList = [];

    for (final rMap in routineMaps) {
      final routineId = rMap['id'] as String;

      final reMaps = await db.query(
        'routine_exercises',
        where: 'routine_id = ?',
        whereArgs: [routineId],
        orderBy: 'order_index ASC',
      );

      List<RoutineExercise> exercises = [];
      for (final reMap in reMaps) {
        final exId = reMap['exercise_id'] as String;
        final exMaps = await db.query('exercises', where: 'id = ?', whereArgs: [exId]);
        Exercise? exercise;
        if (exMaps.isNotEmpty) {
          exercise = Exercise.fromMap(exMaps.first);
        }
        exercises.add(RoutineExercise.fromMap(reMap, exercise: exercise));
      }

      routinesList.add(Routine.fromMap(rMap, exercises: exercises));
    }

    state = routinesList;
  }

  Future<void> createRoutine({
    required String name,
    String? description,
    required List<String> targetDays,
    required List<Map<String, dynamic>> exercisesInput,
  }) async {
    final db = await DBHelper.instance.database;
    const uuid = Uuid();
    final routineId = uuid.v4();

    await db.insert('routines', {
      'id': routineId,
      'name': name,
      'description': description,
      'target_days': targetDays.join(','),
      'created_at': DateTime.now().toIso8601String(),
    });

    for (int i = 0; i < exercisesInput.length; i++) {
      final item = exercisesInput[i];
      await db.insert('routine_exercises', {
        'id': uuid.v4(),
        'routine_id': routineId,
        'exercise_id': item['exerciseId'],
        'target_sets': item['targetSets'] ?? 3,
        'target_reps': item['targetReps'] ?? 10,
        'target_weight': item['targetWeight'] ?? 0.0,
        'execution_seconds': item['executionSeconds'] ?? 45,
        'rest_seconds': item['restSeconds'],
        'has_warmup_set': (item['hasWarmupSet'] as bool? ?? false) ? 1 : 0,
        'warmup_reps': item['warmupReps'] ?? 10,
        'warmup_weight': item['warmupWeight'] ?? 10.0,
        'warmup_execution_seconds': item['warmupExecutionSeconds'] ?? 30,
        'warmup_rest_seconds': item['warmupRestSeconds'] ?? 60,
        'order_index': i,
      });
    }

    await loadRoutines();
  }

  Future<void> updateRoutine({
    required String routineId,
    required String name,
    String? description,
    required List<String> targetDays,
    required List<Map<String, dynamic>> exercisesInput,
  }) async {
    final db = await DBHelper.instance.database;
    const uuid = Uuid();

    await db.update(
      'routines',
      {
        'name': name,
        'description': description,
        'target_days': targetDays.join(','),
      },
      where: 'id = ?',
      whereArgs: [routineId],
    );

    await db.delete('routine_exercises', where: 'routine_id = ?', whereArgs: [routineId]);

    for (int i = 0; i < exercisesInput.length; i++) {
      final item = exercisesInput[i];
      await db.insert('routine_exercises', {
        'id': uuid.v4(),
        'routine_id': routineId,
        'exercise_id': item['exerciseId'],
        'target_sets': item['targetSets'] ?? 3,
        'target_reps': item['targetReps'] ?? 10,
        'target_weight': item['targetWeight'] ?? 0.0,
        'execution_seconds': item['executionSeconds'] ?? 45,
        'rest_seconds': item['restSeconds'],
        'has_warmup_set': (item['hasWarmupSet'] as bool? ?? false) ? 1 : 0,
        'warmup_reps': item['warmupReps'] ?? 10,
        'warmup_weight': item['warmupWeight'] ?? 10.0,
        'warmup_execution_seconds': item['warmupExecutionSeconds'] ?? 30,
        'warmup_rest_seconds': item['warmupRestSeconds'] ?? 60,
        'order_index': i,
      });
    }

    await loadRoutines();
  }

  Future<void> deleteRoutine(String id) async {
    final db = await DBHelper.instance.database;
    await db.delete('routine_exercises', where: 'routine_id = ?', whereArgs: [id]);
    await db.delete('routines', where: 'id = ?', whereArgs: [id]);
    await loadRoutines();
  }
}
