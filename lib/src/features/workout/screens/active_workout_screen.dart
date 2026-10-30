import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exercises/providers/exercise_provider.dart';
import '../../routines/models/routine.dart';
import '../../routines/providers/routine_provider.dart';
import '../models/workout_set.dart';
import '../providers/active_workout_provider.dart';
import '../widgets/guided_workout_timer_widget.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  WorkoutSet? activeTimerSet;

  @override
  Widget build(BuildContext context) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final routines = ref.watch(routineListProvider);
    final allExercises = ref.watch(exerciseListProvider);

    Routine? activeRoutine;
    if (activeWorkout != null) {
      try {
        activeRoutine = routines.firstWhere((r) => r.id == activeWorkout.routineId);
      } catch (_) {
        activeRoutine = null;
      }
    }

    if (activeWorkout == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Entrenamiento Activo'),
        ),
        body: const Center(
          child: Text('No hay ningún entrenamiento activo.'),
        ),
      );
    }

    // Group sets by exercise
    final Map<String, List<WorkoutSet>> exerciseSetsMap = {};
    for (final set in activeWorkout.sets) {
      exerciseSetsMap.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeWorkout.routineName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tiempo: ${_formatDuration(DateTime.now().difference(activeWorkout.startTime))}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF00E676)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              _showCancelWorkoutDialog(context, ref);
            },
          ),
          ElevatedButton(
            onPressed: () => _showFinishWorkoutDialog(context, ref),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Finalizar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Prominent Circular Timer Card when a set timer is active
            if (activeTimerSet != null) ...[
              Builder(
                builder: (context) {
                  final currentSet = activeTimerSet!;
                  final exerciseId = currentSet.exerciseId;

                  // Lookup custom execution & rest seconds for this exercise
                  int execSeconds = 45;
                  int restSeconds = 90;

                  if (activeRoutine != null) {
                    try {
                      final re = activeRoutine.exercises.firstWhere((e) => e.exerciseId == exerciseId);
                      execSeconds = re.executionSeconds;
                      restSeconds = re.restSeconds ?? 90;
                    } catch (_) {}
                  }

                  return GuidedWorkoutTimerWidget(
                    key: ValueKey(currentSet.id),
                    executionSeconds: execSeconds,
                    restSeconds: restSeconds,
                    exerciseName: currentSet.exerciseName,
                    setLabel: currentSet.setNumber == 0 ? 'W (Calentamiento)' : '${currentSet.setNumber}',
                    onClose: () {
                      setState(() {
                        activeTimerSet = null;
                      });
                    },
                    onSetCompleted: () {
                      // 1. Mark current set completed
                      ref.read(activeWorkoutProvider.notifier).toggleSetCompleted(currentSet.id);

                      // 2. Find next uncompleted set for hands-free auto progression
                      final currentWorkout = ref.read(activeWorkoutProvider);
                      WorkoutSet? nextSet;
                      if (currentWorkout != null) {
                        try {
                          nextSet = currentWorkout.sets.firstWhere(
                            (s) => !s.isCompleted && s.id != currentSet.id,
                          );
                        } catch (_) {
                          nextSet = null;
                        }
                      }

                      setState(() {
                        activeTimerSet = nextSet;
                      });

                      if (nextSet == null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Excelente! Has completado todas las series'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Workout Sets Table
            ...exerciseSetsMap.entries.map((entry) {
              final exerciseId = entry.key;
              final sets = entry.value;
              final exerciseName = sets.first.exerciseName;

              // Find exercise object to check if time based
              final exerciseObj = allExercises.firstWhere(
                (e) => e.id == exerciseId,
                orElse: () => allExercises.first,
              );
              final isTimeBased = exerciseObj.isTimeBased;
              final isCardio = exerciseObj.isCardio;
              final repsHeader = isCardio
                  ? 'Tiempo (min)'
                  : (isTimeBased ? 'Tiempo (s)' : 'Reps');
              final weightHeader = isCardio ? 'Carga / Inc.' : 'Peso';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            exerciseName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00E676),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dynamic Table Header: Serie | Peso / Inclinación | Reps / Tiempo | Timer | Listo
                      Row(
                        children: [
                          const SizedBox(
                              width: 36,
                              child: Text('Serie',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text(weightHeader,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Text(repsHeader,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(
                              width: 44,
                              child: Text('Timer',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))),
                          const SizedBox(
                              width: 36,
                              child: Text('Listo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const Divider(color: Colors.white10),

                      ...sets.map((set) {
                        final weightController = TextEditingController(text: '${set.weight}');
                        final repsController = TextEditingController(text: '${set.reps}');
                        final isTimerActive = activeTimerSet?.id == set.id;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Text(
                                  set.setNumber == 0 ? 'W' : '${set.setNumber}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: set.setNumber == 0 ? Colors.orangeAccent : Colors.white,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: TextField(
                                    controller: weightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onChanged: (val) {
                                      final w = double.tryParse(val) ?? 0.0;
                                      ref
                                          .read(activeWorkoutProvider.notifier)
                                          .updateSet(set.id, weight: w);
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: TextField(
                                    controller: repsController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onChanged: (val) {
                                      final r = int.tryParse(val) ?? 0;
                                      ref
                                          .read(activeWorkoutProvider.notifier)
                                          .updateSet(set.id, reps: r);
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 44,
                                child: IconButton(
                                  icon: Icon(
                                    isTimerActive ? Icons.timer : Icons.play_circle_outline,
                                    color: isTimerActive ? const Color(0xFF00B0FF) : const Color(0xFF00E676),
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isTimerActive) {
                                        activeTimerSet = null;
                                      } else {
                                        activeTimerSet = set;
                                      }
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: IconButton(
                                  icon: Icon(
                                    set.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: set.isCompleted ? const Color(0xFF00E676) : Colors.grey,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(activeWorkoutProvider.notifier)
                                        .toggleSetCompleted(set.id);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .addSetToExercise(exerciseId, exerciseName);
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Agregar Serie'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Color(0xFF00E676)),
                foregroundColor: const Color(0xFF00E676),
              ),
              onPressed: () => _showAddExerciseSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Ejercicio a la Sesión'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context, WidgetRef ref) {
    final allExercises = ref.watch(exerciseListProvider);
    String selectedCategoryFilter = 'Todos';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filteredList = selectedCategoryFilter == 'Todos'
                ? allExercises
                : allExercises.where((e) => e.category == selectedCategoryFilter).toList();

            final categories = ['Todos', 'Pecho', 'Espalda', 'Piernas', 'Hombros', 'Brazos', 'Core', 'Cardio', 'TRX'];

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccionar Ejercicio por Grupo Muscular',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        final isSel = cat == selectedCategoryFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            selectedColor: Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.black : Colors.white,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setStateSheet(() {
                                selectedCategoryFilter = cat;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text('No hay ejercicios en este grupo', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final ex = filteredList[index];
                              return ListTile(
                                title: Text(ex.name),
                                subtitle: Text(
                                    '${ex.category} • ${ex.equipment ?? "General"} • ${ex.isCardio ? "Cardio" : (ex.isTimeBased ? "Por Tiempo (s)" : "Por Reps")}'),
                                trailing: const Icon(Icons.add_circle_outline),
                                onTap: () {
                                  ref
                                      .read(activeWorkoutProvider.notifier)
                                      .addExerciseToSession(ex);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCancelWorkoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('¿Cancelar Entrenamiento?'),
        content: const Text('Se descartará todo el progreso de esta sesión activa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar Entrenando'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(activeWorkoutProvider.notifier).cancelWorkout();
              Navigator.pop(context);
            },
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showFinishWorkoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('¿Finalizar Entrenamiento?'),
        content: const Text('Se guardará la sesión en tu historial y se sincronizará en la nube.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Seguir Entrenando'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(activeWorkoutProvider.notifier).finishWorkout();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Entrenamiento Guardado con Éxito!')),
                );
              }
            },
            child: const Text('Guardar y Finalizar'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
