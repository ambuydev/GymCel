import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/db_helper.dart';
import '../models/exercise.dart';

final exerciseListProvider = StateNotifierProvider<ExerciseNotifier, List<Exercise>>((ref) {
  return ExerciseNotifier()..loadExercises();
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'Todos');

final filteredExerciseListProvider = Provider<List<Exercise>>((ref) {
  final exercises = ref.watch(exerciseListProvider);
  final category = ref.watch(selectedCategoryProvider);

  if (category == 'Todos') {
    return exercises;
  }
  return exercises.where((ex) => ex.category == category).toList();
});

class ExerciseNotifier extends StateNotifier<List<Exercise>> {
  ExerciseNotifier() : super([]);

  Future<void> loadExercises() async {
    final db = await DBHelper.instance.database;
    final maps = await db.query('exercises', orderBy: 'category ASC, name ASC');
    state = maps.map((map) => Exercise.fromMap(map)).toList();
  }

  Future<void> addCustomExercise({
    required String name,
    required String category,
    String? equipment,
    String? notes,
  }) async {
    final db = await DBHelper.instance.database;
    final newExercise = Exercise(
      id: const Uuid().v4(),
      name: name,
      category: category,
      equipment: equipment,
      isCustom: true,
      notes: notes,
    );

    await db.insert('exercises', newExercise.toMap());
    await loadExercises();
  }

  Future<void> deleteCustomExercise(String id) async {
    final db = await DBHelper.instance.database;
    await db.delete('exercises', where: 'id = ? AND is_custom = 1', whereArgs: [id]);
    await loadExercises();
  }
}
