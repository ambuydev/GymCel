import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/workout_notification_service.dart';
import '../exercises/screens/exercise_list_screen.dart';
import '../history/screens/history_screen.dart';
import '../paywall/settings_paywall_screen.dart';
import '../routines/screens/routine_list_screen.dart';
import '../routines/widgets/smartwatch_guide_dialog.dart';
import '../workout/providers/active_workout_provider.dart';
import '../workout/screens/active_workout_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int currentIndex = 0;

  final pages = const [
    RoutineListScreen(),
    ExerciseListScreen(),
    HistoryScreen(),
    SettingsPaywallScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initAppPermissionsAndGuide();
  }

  Future<void> _initAppPermissionsAndGuide() async {
    // 1. Initialize notification service and request Android 13+ runtime permissions
    await WorkoutNotificationService.instance.initNotifications();

    // 2. Check if Smartwatch Onboarding Guide has been displayed
    final prefs = await SharedPreferences.getInstance();
    final guideShown = prefs.getBool('smartwatch_guide_shown') ?? false;

    if (!guideShown && mounted) {
      prefs.setBool('smartwatch_guide_shown', true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SmartwatchGuideDialog.show(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini Active Workout Floating Bar if session is running
            if (activeWorkout != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActiveWorkoutScreen(),
                    ),
                  );
                },
                child: Container(
                  color: const Color(0xFF00E676),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.black),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeWorkout.routineName,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'En progreso (${activeWorkout.sets.where((s) => s.isCompleted).length}/${activeWorkout.sets.length} series)',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Tocar para abrir',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black),
                    ],
                  ),
                ),
              ),

            BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() => currentIndex = index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center),
                  label: 'Rutinas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.format_list_bulleted),
                  label: 'Ejercicios',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Historial',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
