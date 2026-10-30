import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exercises/models/exercise.dart';
import '../../exercises/providers/exercise_provider.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final Routine? initialRoutine;

  const RoutineEditorScreen({super.key, this.initialRoutine});

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  late TextEditingController nameController;
  late TextEditingController descController;

  final weekDays = const [
    {'short': 'L', 'full': 'Lun'},
    {'short': 'M', 'full': 'Mar'},
    {'short': 'M', 'full': 'Mié'},
    {'short': 'J', 'full': 'Jue'},
    {'short': 'V', 'full': 'Vie'},
    {'short': 'S', 'full': 'Sáb'},
    {'short': 'D', 'full': 'Dom'},
  ];

  List<String> selectedDays = [];
  List<Map<String, dynamic>> selectedExercises = [];

  @override
  void initState() {
    super.initState();
    final r = widget.initialRoutine;
    nameController = TextEditingController(text: r?.name ?? '');
    descController = TextEditingController(text: r?.description ?? '');

    if (r != null) {
      selectedDays = List.from(r.targetDays);
      selectedExercises = r.exercises.map((re) {
        return {
          'exercise': re.exercise,
          'exerciseId': re.exerciseId,
          'targetSets': re.targetSets,
          'targetReps': re.targetReps,
          'targetWeight': re.targetWeight,
          'executionSeconds': re.executionSeconds,
          'restSeconds': re.restSeconds,
          'hasWarmupSet': re.hasWarmupSet,
          'warmupReps': re.warmupReps,
          'warmupWeight': re.warmupWeight,
          'warmupExecutionSeconds': re.warmupExecutionSeconds,
          'warmupRestSeconds': re.warmupRestSeconds,
        };
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exerciseListProvider);
    final isEditing = widget.initialRoutine != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Rutina' : 'Crear Nueva Rutina'),
        actions: [
          TextButton(
            onPressed: () => _saveRoutine(),
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Rutina',
                hintText: 'Ej. Pierna Intensivo / Push A',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Descripción (Opcional)',
                hintText: 'Ej. Enfoque en Cuádriceps e Isquios',
              ),
            ),
            const SizedBox(height: 16),

            // Days of Week Selector
            const Text(
              'Días de Entrenamiento Programados',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: weekDays.map((dayMap) {
                final dayFull = dayMap['full']!;
                final dayShort = dayMap['short']!;
                final isSelected = selectedDays.contains(dayFull);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FilterChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          dayShort,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            selectedDays.add(dayFull);
                          } else {
                            selectedDays.remove(dayFull);
                          }
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ejercicios de la Rutina',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showSelectExerciseSheet(allExercises),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (selectedExercises.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.fitness_center_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No has agregado ejercicios a esta rutina',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedExercises.length,
                itemBuilder: (context, index) {
                  final item = selectedExercises[index];
                  final Exercise? ex = item['exercise'];
                  final exName = ex?.name ?? 'Ejercicio';
                  final isTimeBased = ex?.isTimeBased ?? false;
                  final isCardio = ex?.isCardio ?? false;
                  final weightController = TextEditingController(text: '${item['targetWeight']}');
                  final warmupWeightController = TextEditingController(text: '${item['warmupWeight']}');
                  final hasWarmup = item['hasWarmupSet'] as bool? ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                exName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  setState(() {
                                    selectedExercises.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 12, color: Colors.white10),

                          if (isCardio) ...[
                            // CARDIO EXERCISE SPECIFIC FIELDS
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF00E676)),
                                const SizedBox(width: 6),
                                const Text('Duración Objetivo: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                DropdownButton<int>(
                                  value: (item['targetReps'] as int?) != null && [5, 10, 15, 20, 25, 30, 45, 60, 90].contains(item['targetReps'])
                                      ? item['targetReps']
                                      : 20,
                                  dropdownColor: Theme.of(context).cardColor,
                                  items: [5, 10, 15, 20, 25, 30, 45, 60, 90].map((m) {
                                    return DropdownMenuItem<int>(
                                      value: m,
                                      child: Text('$m min'),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => item['targetReps'] = v);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.tune, size: 16, color: Color(0xFF00B0FF)),
                                const SizedBox(width: 6),
                                const Text('Inclinación / Nivel Carga: ', style: TextStyle(fontSize: 13)),
                                SizedBox(
                                  width: 80,
                                  height: 36,
                                  child: TextField(
                                    controller: weightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (val) {
                                      final w = double.tryParse(val) ?? 0.0;
                                      item['targetWeight'] = w;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // STRENGTH EXERCISE FIELDS
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Text('Series: '),
                                      DropdownButton<int>(
                                        value: item['targetSets'],
                                        dropdownColor: Theme.of(context).cardColor,
                                        items: List.generate(10, (i) => i + 1)
                                            .map((v) => DropdownMenuItem(
                                                  value: v,
                                                  child: Text('$v'),
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) {
                                            setState(() => item['targetSets'] = v);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(isTimeBased ? 'Tiempo (s): ' : 'Reps: '),
                                      DropdownButton<int>(
                                        value: item['targetReps'],
                                        dropdownColor: Theme.of(context).cardColor,
                                        items: (isTimeBased
                                                ? [15, 30, 45, 60, 90, 120, 180]
                                                : List.generate(30, (i) => i + 1))
                                            .map((v) => DropdownMenuItem(
                                                  value: v,
                                                  child: Text('$v'),
                                                ))
                                            .toList(),
                                        onChanged: (v) {
                                          if (v != null) {
                                            setState(() => item['targetReps'] = v);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Target Weight (Hidden for Core and Bodyweight Exercises)
                            if (ex?.isBodyweight == false) ...[
                              Row(
                                children: [
                                  const Icon(Icons.fitness_center, size: 16, color: Color(0xFF00E676)),
                                  const SizedBox(width: 6),
                                  const Text('Peso Obj (kg): ', style: TextStyle(fontSize: 13)),
                                  SizedBox(
                                    width: 90,
                                    height: 36,
                                    child: TextField(
                                      controller: weightController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      onChanged: (val) {
                                        final w = double.tryParse(val) ?? 0.0;
                                        item['targetWeight'] = w;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Execution Time
                            Row(
                              children: [
                                const Icon(Icons.speed, size: 16, color: Color(0xFF00B0FF)),
                                const SizedBox(width: 6),
                                const Text('Tiempo de Serie: ', style: TextStyle(fontSize: 13)),
                                DropdownButton<int>(
                                  value: item['executionSeconds'],
                                  dropdownColor: Theme.of(context).cardColor,
                                  items: [15, 30, 45, 60, 90, 120].map((s) {
                                    return DropdownMenuItem<int>(
                                      value: s,
                                      child: Text('${s}s trabajo'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => item['executionSeconds'] = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Custom Rest Timer
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                const Text('Descanso: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                DropdownButton<int?>(
                                  value: item['restSeconds'],
                                  hint: const Text('Por defecto (Ajustes)', style: TextStyle(color: Color(0xFF00E676), fontSize: 13)),
                                  dropdownColor: Theme.of(context).cardColor,
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Por defecto (Ajustes)'),
                                    ),
                                    ...[30, 45, 60, 90, 120, 180, 240, 300].map((s) => DropdownMenuItem<int?>(
                                          value: s,
                                          child: Text('${s}s descanso'),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      item['restSeconds'] = val;
                                    });
                                  },
                                ),
                              ],
                            ),

                            // Optional Warmup Set Switch & Expanded Custom Configuration Panel
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Incluir Serie de Calentamiento (W)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.orangeAccent)),
                              value: hasWarmup,
                              activeThumbColor: Colors.orangeAccent,
                              onChanged: (val) {
                                setState(() {
                                  item['hasWarmupSet'] = val;
                                });
                              },
                            ),

                            if (hasWarmup)
                              Container(
                                margin: const EdgeInsets.only(top: 4, bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Configuración de Calentamiento (Serie W):', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 6,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Peso W (kg): ', style: TextStyle(fontSize: 12)),
                                            SizedBox(
                                              width: 60,
                                              height: 32,
                                              child: TextField(
                                                controller: warmupWeightController,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                decoration: const InputDecoration(
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                                ),
                                                onChanged: (val) {
                                                  final w = double.tryParse(val) ?? 10.0;
                                                  item['warmupWeight'] = w;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(isTimeBased ? 'Tiempo W (s): ' : 'Reps W: ', style: const TextStyle(fontSize: 12)),
                                            DropdownButton<int>(
                                              value: item['warmupReps'],
                                              dropdownColor: Theme.of(context).cardColor,
                                              items: (isTimeBased
                                                      ? [15, 30, 45, 60]
                                                      : List.generate(20, (i) => i + 1))
                                                  .map((v) => DropdownMenuItem(
                                                        value: v,
                                                        child: Text('$v'),
                                                      ))
                                                  .toList(),
                                              onChanged: (v) {
                                                if (v != null) {
                                                  setState(() => item['warmupReps'] = v);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Trabajo W: ', style: TextStyle(fontSize: 12)),
                                            DropdownButton<int>(
                                              value: item['warmupExecutionSeconds'],
                                              dropdownColor: Theme.of(context).cardColor,
                                              items: [15, 30, 45, 60].map((s) => DropdownMenuItem(value: s, child: Text('${s}s'))).toList(),
                                              onChanged: (v) {
                                                if (v != null) setState(() => item['warmupExecutionSeconds'] = v);
                                              },
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Descanso W: ', style: TextStyle(fontSize: 12)),
                                            DropdownButton<int>(
                                              value: item['warmupRestSeconds'],
                                              dropdownColor: Theme.of(context).cardColor,
                                              items: [30, 45, 60, 90, 120].map((s) => DropdownMenuItem(value: s, child: Text('${s}s'))).toList(),
                                              onChanged: (v) {
                                                if (v != null) setState(() => item['warmupRestSeconds'] = v);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSelectExerciseSheet(List<Exercise> allExercises) {
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
                                  setState(() {
                                    selectedExercises.add({
                                      'exercise': ex,
                                      'exerciseId': ex.id,
                                      'targetSets': ex.isCardio ? 1 : 3,
                                      'targetReps': ex.isCardio ? 20 : (ex.isTimeBased ? 60 : 10),
                                      'targetWeight': ex.isCardio ? 0.0 : 20.0,
                                      'executionSeconds': 45,
                                      'restSeconds': null,
                                      'hasWarmupSet': false,
                                      'warmupReps': ex.isTimeBased ? 30 : 10,
                                      'warmupWeight': 10.0,
                                      'warmupExecutionSeconds': 30,
                                      'warmupRestSeconds': 60,
                                    });
                                  });
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

  void _saveRoutine() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre para la rutina')),
      );
      return;
    }

    if (selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ejercicio a la rutina')),
      );
      return;
    }

    final isEditing = widget.initialRoutine != null;

    if (isEditing) {
      ref.read(routineListProvider.notifier).updateRoutine(
            routineId: widget.initialRoutine!.id,
            name: name,
            description: descController.text.trim().isEmpty ? null : descController.text.trim(),
            targetDays: selectedDays,
            exercisesInput: selectedExercises,
          );
    } else {
      ref.read(routineListProvider.notifier).createRoutine(
            name: name,
            description: descController.text.trim().isEmpty ? null : descController.text.trim(),
            targetDays: selectedDays,
            exercisesInput: selectedExercises,
          );
    }

    Navigator.pop(context);
  }
}
