import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../workout/models/workout_session.dart';
import '../../workout/providers/active_workout_provider.dart';
import '../../workout/screens/active_workout_screen.dart';
import '../models/routine.dart';
import '../providers/routine_provider.dart';
import 'routine_editor_screen.dart';

class DayRoutinesDetailScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final String dayName;
  final bool isToday;
  final bool isCompleted;
  final bool isScheduled;
  final List<Routine> initialScheduledRoutines;
  final List<WorkoutSession> completedSessions;

  const DayRoutinesDetailScreen({
    super.key,
    required this.date,
    required this.dayName,
    required this.isToday,
    required this.isCompleted,
    required this.isScheduled,
    required this.initialScheduledRoutines,
    required this.completedSessions,
  });

  @override
  ConsumerState<DayRoutinesDetailScreen> createState() => _DayRoutinesDetailScreenState();
}

class _DayRoutinesDetailScreenState extends ConsumerState<DayRoutinesDetailScreen> {
  late List<Routine> orderedRoutines;

  @override
  void initState() {
    super.initState();
    orderedRoutines = List.from(widget.initialScheduledRoutines);
  }

  @override
  Widget build(BuildContext context) {
    // Keep orderedRoutines synchronized with live Riverpod provider
    final allRoutines = ref.watch(routineListProvider);
    final dayShort = widget.dayName.toLowerCase().substring(0, 2);

    final currentScheduled = allRoutines.where((r) {
      return r.targetDays.any((d) => d.toLowerCase().startsWith(dayShort));
    }).toList();

    // Preserve local drag order while picking up edits
    List<Routine> displayRoutines = [];
    for (final o in orderedRoutines) {
      try {
        final updated = currentScheduled.firstWhere((r) => r.id == o.id);
        displayRoutines.add(updated);
      } catch (_) {}
    }
    for (final c in currentScheduled) {
      if (!displayRoutines.any((r) => r.id == c.id)) {
        displayRoutines.add(c);
      }
    }

    final fullDayName = DateFormatter.getFullDayName(widget.date);
    final monthName = DateFormatter.months[widget.date.month - 1];

    return Scaffold(
      appBar: AppBar(
        title: Text('$fullDayName ${widget.date.day} $monthName'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Day Badge & Status Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isCompleted
                      ? const Color(0xFF00E676).withValues(alpha: 0.15)
                      : (widget.isScheduled ? Colors.orangeAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isCompleted
                        ? const Color(0xFF00E676)
                        : (widget.isScheduled ? Colors.orangeAccent : Colors.white10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isCompleted
                          ? Icons.check_circle
                          : (widget.isScheduled ? Icons.pending_actions : Icons.bedtime),
                      color: widget.isCompleted
                          ? const Color(0xFF00E676)
                          : (widget.isScheduled ? Colors.orangeAccent : Colors.grey),
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isCompleted
                                ? '¡Entrenamiento de la jornada completado!'
                                : (widget.isScheduled ? 'Rutinas pendientes de realizar' : 'Día libre de descanso programado'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: widget.isCompleted
                                  ? const Color(0xFF00E676)
                                  : (widget.isScheduled ? Colors.orangeAccent : Colors.grey),
                            ),
                          ),
                          if (widget.isToday)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                'Jornada de Hoy',
                                style: TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Rutinas Programadas para este Día:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: displayRoutines.isEmpty
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.fitness_center_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                const Text(
                                  'No hay rutinas agendadas para este día.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Diseña una nueva rutina o asigna un día de entrenamiento.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: displayRoutines.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = displayRoutines.removeAt(oldIndex);
                            displayRoutines.insert(newIndex, item);
                            orderedRoutines = List.from(displayRoutines);
                          });
                        },
                        itemBuilder: (context, index) {
                          final routine = displayRoutines[index];

                          return Card(
                            key: ValueKey(routine.id),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                    ],
                                  ),
                                  if (routine.description != null && routine.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        routine.description!,
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${routine.exercises.length} Ejercicios incluidos:',
                                    style: const TextStyle(
                                      color: Color(0xFF00E676),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
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
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00E676),
                                        foregroundColor: Colors.black,
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
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text(
                                        'Iniciar Esta Rutina',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
