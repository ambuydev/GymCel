import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';

class SyncService {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not initialized in current environment: $e');
      return null;
    }
  }

  // Backup all local routines and workout sessions to Cloud Firestore
  Future<void> backupLocalToCloud(String userId) async {
    final fs = _firestore;
    if (fs == null) throw Exception('Firebase Firestore no está configurado.');

    final db = await DBHelper.instance.database;

    // 1. Backup Routines
    final routineMaps = await db.query('routines');
    for (final r in routineMaps) {
      final routineId = r['id'] as String;

      final reMaps = await db.query('routine_exercises',
          where: 'routine_id = ?', whereArgs: [routineId]);

      await fs
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(routineId)
          .set({
        ...r,
        'exercises': reMaps,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 2. Backup Workout Sessions
    final sessionMaps = await db.query('workout_sessions');
    for (final s in sessionMaps) {
      final sessionId = s['id'] as String;

      final setMaps = await db.query('workout_sets',
          where: 'workout_session_id = ?', whereArgs: [sessionId]);

      await fs
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .doc(sessionId)
          .set({
        ...s,
        'sets': setMaps,
        'synced_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Update user profile metadata
    await fs.collection('users').doc(userId).set({
      'lastSync': FieldValue.serverTimestamp(),
      'isPremium': true,
    }, SetOptions(merge: true));
  }

  // Restore Cloud Firestore history into local SQLite
  Future<int> restoreCloudToLocal(String userId) async {
    final fs = _firestore;
    if (fs == null) throw Exception('Firebase Firestore no está configurado.');

    final db = await DBHelper.instance.database;
    int restoredCount = 0;

    // Fetch remote workout sessions
    final snapshot = await fs
        .collection('users')
        .doc(userId)
        .collection('workout_sessions')
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final sessionId = doc.id;

      // Check if session already exists locally
      final existing = await db.query('workout_sessions',
          where: 'id = ?', whereArgs: [sessionId]);

      if (existing.isEmpty) {
        // Insert session
        await db.insert('workout_sessions', {
          'id': sessionId,
          'routine_id': data['routine_id'],
          'routine_name': data['routine_name'] ?? 'Entrenamiento',
          'start_time': data['start_time'],
          'end_time': data['end_time'],
          'duration_seconds': data['duration_seconds'] ?? 0,
          'notes': data['notes'],
          'total_volume': data['total_volume'] ?? 0.0,
        });

        // Insert sets
        final List<dynamic> sets = data['sets'] ?? [];
        for (final set in sets) {
          if (set is Map<String, dynamic>) {
            await db.insert('workout_sets', {
              'id': set['id'],
              'workout_session_id': sessionId,
              'exercise_id': set['exercise_id'],
              'exercise_name': set['exercise_name'],
              'set_number': set['set_number'],
              'weight': set['weight'],
              'reps': set['reps'],
              'is_completed': set['is_completed'],
            });
          }
        }
        restoredCount++;
      }
    }

    return restoredCount;
  }
}
