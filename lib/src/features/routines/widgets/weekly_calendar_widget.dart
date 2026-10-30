import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../history/providers/history_provider.dart';
import '../providers/routine_provider.dart';
import '../screens/day_routines_detail_screen.dart';

class WeeklyCalendarWidget extends ConsumerWidget {
  const WeeklyCalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routineListProvider);
    final historyList = ref.watch(historyListProvider);

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    final weekDays = List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });

    final mondayFormatted = '${monday.day} ${DateFormatter.months[monday.month - 1]}';
    final sundayDate = weekDays.last;
    final sundayFormatted = '${sundayDate.day} ${DateFormatter.months[sundayDate.month - 1]}';

    return Card(
      color: const Color(0xFF1E1E24),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month, color: Color(0xFF00E676)),
                    SizedBox(width: 8),
                    Text(
                      'Almanaque Semanal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$mondayFormatted - $sundayFormatted',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7 Days Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = weekDays[index];
                final dayName = DateFormatter.getShortDayName(date);
                final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;

                // Check if any workout session was completed on this date
                final completedSessions = historyList.where((s) {
                  return s.startTime.year == date.year &&
                      s.startTime.month == date.month &&
                      s.startTime.day == date.day;
                }).toList();

                final isCompleted = completedSessions.isNotEmpty;

                // Check if any routine is scheduled for this day name
                final scheduledRoutines = routines.where((r) {
                  return r.targetDays.any((d) =>
                      d.toLowerCase().startsWith(dayName.toLowerCase().substring(0, 2)));
                }).toList();

                final isScheduled = scheduledRoutines.isNotEmpty;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DayRoutinesDetailScreen(
                              date: date,
                              dayName: dayName,
                              isToday: isToday,
                              isCompleted: isCompleted,
                              isScheduled: isScheduled,
                              initialScheduledRoutines: scheduledRoutines,
                              completedSessions: completedSessions,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 1),
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF00E676).withValues(alpha: 0.15)
                              : const Color(0xFF282830),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isToday
                                ? const Color(0xFF00E676)
                                : (isCompleted
                                    ? const Color(0xFF00E676).withValues(alpha: 0.5)
                                    : Colors.transparent),
                            width: isToday ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isToday ? const Color(0xFF00E676) : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status Icon Indicator
                            if (isCompleted)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF00E676),
                                size: 18,
                              )
                            else if (isScheduled)
                              Icon(
                                Icons.radio_button_unchecked,
                                color: isToday ? Colors.orangeAccent : Colors.white38,
                                size: 16,
                              )
                            else
                              const Icon(
                                Icons.remove,
                                color: Colors.white12,
                                size: 14,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Legend Footer
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF00E676), size: 14),
                    SizedBox(width: 4),
                    Text('Cumplido', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.radio_button_unchecked, color: Colors.orangeAccent, size: 14),
                    SizedBox(width: 4),
                    Text('Programado', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.remove, color: Colors.white24, size: 14),
                    SizedBox(width: 4),
                    Text('Descanso', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
