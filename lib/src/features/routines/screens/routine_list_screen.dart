import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../workout/providers/active_workout_provider.dart';
import '../../workout/screens/active_workout_screen.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import '../widgets/weekly_calendar_widget.dart';
import 'routine_editor_screen.dart';

final selectedDayFilterProvider = StateProvider<String>((ref) => 'Todos');

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routineListProvider);
    final selectedFilter = ref.watch(selectedDayFilterProvider);

    final formattedToday = DateFormatter.getShortDayName(DateTime.now());

    final dayFilters = [
      'Todos',
      'Hoy',
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ];

    // Filter routines based on selected filter chip
    List<Routine> filteredRoutines = [];
    if (selectedFilter == 'Todos') {
      filteredRoutines = routines;
    } else if (selectedFilter == 'Hoy') {
      filteredRoutines = routines.where((r) {
        return r.targetDays.any((d) =>
            d.toLowerCase().startsWith(formattedToday.toLowerCase().substring(0, 2)));
      }).toList();
    } else {
      filteredRoutines = routines.where((r) {
        return r.targetDays.any((d) =>
            d.toLowerCase().startsWith(selectedFilter.toLowerCase().substring(0, 2)));
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28, color: Color(0xFF00E676)),
            tooltip: 'Nueva Rutina',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoutineEditorScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Calendar Almanac Widget
            const WeeklyCalendarWidget(),

            // Quick Start Workout Card
            Card(
              color: const Color(0xFF1E2822),
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: Color(0xFF00E676)),
                        SizedBox(width: 8),
                        Text(
                          'Inicio Rápido',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Comienza a registrar tu entrenamiento sobre la marcha sin plantilla.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(activeWorkoutProvider.notifier).startBlankWorkout();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ActiveWorkoutScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Comenzar Entrenamiento Libre'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section Header & Day Filter Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Tus Rutinas Creadas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hoy: $formattedToday',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Day Group Filter Chips
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dayFilters.length,
                itemBuilder: (context, idx) {
                  final filter = dayFilters[idx];
                  final isSelected = filter == selectedFilter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        ref.read(selectedDayFilterProvider.notifier).state = filter;
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            if (filteredRoutines.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.fitness_center_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          selectedFilter == 'Todos'
                              ? 'No tienes ninguna rutina creada'
                              : 'No hay rutinas programadas para $selectedFilter',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Toca el botón + en la esquina superior para diseñar una rutina.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RoutineEditorScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Crear Nueva Rutina'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              _buildGroupedRoutineList(
                context: context,
                ref: ref,
                routines: filteredRoutines,
                formattedToday: formattedToday,
                selectedFilter: selectedFilter,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedRoutineList({
    required BuildContext context,
    required WidgetRef ref,
    required List<Routine> routines,
    required String formattedToday,
    required String selectedFilter,
  }) {
    // Group routines by day if 'Todos' is selected
    if (selectedFilter != 'Todos') {
      return Column(
        children: routines
            .map((r) => _buildRoutineCard(context, ref, r, formattedToday))
            .toList(),
      );
    }

    // Grouping by scheduled day
    final daysOrder = ['Hoy', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom', 'Sin Día'];
    final Map<String, List<Routine>> groupedMap = {};

    for (final r in routines) {
      final isToday = r.targetDays.any(
        (d) => d.toLowerCase().startsWith(formattedToday.toLowerCase().substring(0, 2)),
      );

      if (isToday) {
        groupedMap.putIfAbsent('Hoy', () => []).add(r);
      } else if (r.targetDays.isEmpty) {
        groupedMap.putIfAbsent('Sin Día', () => []).add(r);
      } else {
        for (final day in r.targetDays) {
          groupedMap.putIfAbsent(day, () => []).add(r);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: daysOrder.map((groupKey) {
        final list = groupedMap[groupKey];
        if (list == null || list.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    groupKey == 'Hoy' ? Icons.bolt : Icons.calendar_today,
                    size: 16,
                    color: groupKey == 'Hoy' ? const Color(0xFF00E676) : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    groupKey == 'Hoy' ? 'PROGRAMADAS PARA HOY' : 'PROGRAMADAS PARA ${groupKey.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: groupKey == 'Hoy' ? const Color(0xFF00E676) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ...list.map((r) => _buildRoutineCard(context, ref, r, formattedToday)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRoutineCard(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
    String formattedToday,
  ) {
    final isScheduledToday = routine.targetDays.any(
      (d) => d.toLowerCase().startsWith(formattedToday.toLowerCase().substring(0, 2)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isScheduledToday ? const Color(0xFF222B26) : null,
      shape: isScheduledToday
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF00E676), width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isScheduledToday) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Programada para Hoy',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    routine.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF00E676)),
                      tooltip: 'Editar Rutina',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoutineEditorScreen(initialRoutine: routine),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      tooltip: 'Eliminar Rutina',
                      onPressed: () {
                        ref
                            .read(routineListProvider.notifier)
                            .deleteRoutine(routine.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (routine.description != null && routine.description!.isNotEmpty)
              Text(
                routine.description!,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            const SizedBox(height: 8),

            // Target Days Chips
            if (routine.targetDays.isNotEmpty)
              Wrap(
                spacing: 6,
                children: routine.targetDays.map((day) {
                  return Chip(
                    label: Text(day),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: const Color(0xFF2A2A32),
                  );
                }).toList(),
              ),

            const SizedBox(height: 6),
            Text(
              '${routine.exercises.length} Ejercicios incluidos:',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            ...routine.exercises.map((re) {
              final exName = re.exercise?.name ?? 'Ejercicio';
              final isTime = re.exercise?.isTimeBased ?? false;
              final isCardio = re.exercise?.isCardio ?? false;
              final repsText = isCardio
                  ? '${re.targetReps} min'
                  : (isTime ? '${re.targetReps}s' : '${re.targetReps} reps');
              final weightText = re.targetWeight > 0
                  ? (isCardio ? ' @ Inc/Carga ${re.targetWeight}' : ' @ ${re.targetWeight} kg')
                  : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $exName: ${re.targetSets}x$repsText$weightText',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00E676)),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .startWorkoutFromRoutine(routine);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActiveWorkoutScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow, color: Color(0xFF00E676)),
                label: const Text('Iniciar Esta Rutina'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
