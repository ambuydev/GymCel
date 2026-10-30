import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyList = ref.watch(historyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Entrenamientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(historyListProvider.notifier).loadHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Freemium History Retention Info Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF22222E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: Color(0xFF00E676)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan Gratuito (Almacenamiento Local)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF00E676),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Se conservan automáticamente tus últimos 30 días de historial.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: historyList.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Aún no has completado ningún entrenamiento',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Completa una sesión para ver tu historial aquí',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      final session = historyList[index];
                      final dateFormatted =
                          DateFormat('EEEE, d MMMM yyyy • HH:mm', 'es')
                              .format(session.startTime);

                      // Group sets count by exercise
                      final exercisesMap = <String, int>{};
                      for (final s in session.sets) {
                        if (s.isCompleted) {
                          exercisesMap[s.exerciseName] =
                              (exercisesMap[s.exerciseName] ?? 0) + 1;
                        }
                      }

                      return Card(
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
                                      session.routineName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.grey, size: 20),
                                    onPressed: () {
                                      ref
                                          .read(historyListProvider.notifier)
                                          .deleteSession(session.id);
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                dateFormatted,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _infoTile(
                                    icon: Icons.timer_outlined,
                                    label: 'Duración',
                                    value: _formatDuration(session.durationSeconds),
                                  ),
                                  const SizedBox(width: 24),
                                  _infoTile(
                                    icon: Icons.fitness_center_outlined,
                                    label: 'Volumen Total',
                                    value: '${session.totalVolume.toStringAsFixed(1)} kg',
                                  ),
                                ],
                              ),
                              if (exercisesMap.isNotEmpty) ...[
                                const Divider(height: 20, color: Colors.white10),
                                const Text(
                                  'Resumen de Ejercicios:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF00E676),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...exercisesMap.entries.map((e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        '• ${e.key}: ${e.value} series completadas',
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 13),
                                      ),
                                    )),
                              ],
                              if (session.notes != null && session.notes!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Nota: ${session.notes}',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00E676)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final hrs = mins ~/ 60;
    final remMins = mins % 60;

    if (hrs > 0) {
      return '$hrs h $remMins m';
    }
    return '$mins min';
  }
}
