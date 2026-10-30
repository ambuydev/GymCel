import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/db_helper.dart';
import '../../workout/models/workout_session.dart';
import '../../workout/models/workout_set.dart';

final historyListProvider =
    StateNotifierProvider<HistoryNotifier, List<WorkoutSession>>((ref) {
  return HistoryNotifier()..loadHistory();
});

class HistoryNotifier extends StateNotifier<List<WorkoutSession>> {
  HistoryNotifier() : super([]);

  Future<void> loadHistory() async {
    // Make sure we apply history retention limit before displaying history
    await DBHelper.instance.enforceHistoryRetentionLimit();

    final db = await DBHelper.instance.database;
    final sessionMaps = await db.query(
      'workout_sessions',
      orderBy: 'start_time DESC',
    );

    List<WorkoutSession> sessions = [];

    for (final sMap in sessionMaps) {
      final sessionId = sMap['id'] as String;
      final setMaps = await db.query(
        'workout_sets',
        where: 'workout_session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'set_number ASC',
      );

      final sets = setMaps.map((map) => WorkoutSet.fromMap(map)).toList();
      sessions.add(WorkoutSession.fromMap(sMap, sets: sets));
    }

    state = sessions;
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await DBHelper.instance.database;
    await db.delete('workout_sets', where: 'workout_session_id = ?', whereArgs: [sessionId]);
    await db.delete('workout_sessions', where: 'id = ?', whereArgs: [sessionId]);
    await loadHistory();
  }
}

// Exercise Personal Record & History Provider for charts
final exerciseHistoryProvider =
    FutureProvider.family<List<WorkoutSet>, String>((ref, exerciseId) async {
  final db = await DBHelper.instance.database;
  final setMaps = await db.rawQuery('''
    SELECT ws.* FROM workout_sets ws
    JOIN workout_sessions s ON ws.workout_session_id = s.id
    WHERE ws.exercise_id = ? AND ws.is_completed = 1
    ORDER BY s.start_time ASC
  ''', [exerciseId]);

  return setMaps.map((m) => WorkoutSet.fromMap(m)).toList();
});
