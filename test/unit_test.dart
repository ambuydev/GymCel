import 'package:flutter_test/flutter_test.dart';
import 'package:gymcel/src/features/exercises/models/exercise.dart';
import 'package:gymcel/src/features/routines/models/routine.dart';
import 'package:gymcel/src/features/workout/models/workout_set.dart';

void main() {
  group('Domain Models Unit Tests', () {
    test('Exercise model correctly serializes to and from Map', () {
      final ex = Exercise(
        id: 'test-123',
        name: 'Press de Banca',
        category: 'Pecho',
        equipment: 'Barra',
        isCustom: true,
      );

      final map = ex.toMap();
      expect(map['id'], 'test-123');
      expect(map['is_custom'], 1);

      final restored = Exercise.fromMap(map);
      expect(restored.name, 'Press de Banca');
      expect(restored.isCustom, isTrue);
    });

    test('WorkoutSet total volume calculation', () {
      final set = WorkoutSet(
        id: 'set-1',
        workoutSessionId: 'session-1',
        exerciseId: 'ex-1',
        exerciseName: 'Sentadilla',
        setNumber: 1,
        weight: 100.0,
        reps: 10,
        isCompleted: true,
      );

      expect(set.weight * set.reps, 1000.0);
    });

    test('RoutineExercise copyWith updates target reps', () {
      final re = RoutineExercise(
        id: 're-1',
        routineId: 'r-1',
        exerciseId: 'ex-1',
        targetSets: 3,
        targetReps: 10,
      );

      final updated = re.copyWith(targetReps: 12);
      expect(updated.targetReps, 12);
      expect(updated.targetSets, 3);
    });
  });
}
