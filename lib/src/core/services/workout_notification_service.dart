import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Background action intent handler for smartwatch notification buttons
}

class WorkoutNotificationService {
  static final WorkoutNotificationService instance = WorkoutNotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  WorkoutNotificationService._init();

  Future<void> initNotifications({
    void Function(String action)? onNotificationAction,
  }) async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.actionId != null && onNotificationAction != null) {
            onNotificationAction(response.actionId!);
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();

        const channel = AndroidNotificationChannel(
          'gymcel_watch_alert_channel',
          'Alertas de Reloj Gymcel',
          description: 'Alertas discretas de cambio de serie para Xiaomi Watch y Smartwatches',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );
        await androidImplementation.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (_) {
      // Safe catch for test environment where native plugins are uninitialized
    }
  }

  Future<void> sendDiscreteWatchAlert({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initNotifications();

    const androidDetails = AndroidNotificationDetails(
      'gymcel_watch_alert_channel',
      'Alertas de Reloj Gymcel',
      channelDescription: 'Alertas discretas de cambio de serie para Xiaomi Watch y Smartwatches',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.workout,
      visibility: NotificationVisibility.public,
      ongoing: false, // CRITICAL FOR MI FITNESS & XIAOMI WATCH 3: ongoing: false forces instant Bluetooth notification forwarding
      enableVibration: true,
      playSound: false,
      actions: [
        AndroidNotificationAction(
          'action_pause_resume',
          'Pausar / Reanudar',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'action_skip_next',
          'Siguiente Serie',
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: false,
      presentAlert: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1002, // Unique ID for discrete event alerts
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> showWorkoutProgress({
    required String exerciseName,
    required String setLabel,
    required String phaseText,
    required int remainingSeconds,
    required bool isPaused,
  }) async {
    if (!_isInitialized) await initNotifications();

    const androidDetails = AndroidNotificationDetails(
      'gymcel_workout_channel_v3',
      'Entrenamiento Activo Gymcel',
      channelDescription: 'Notificación de control activo y sincronización para Smartwatch',
      importance: Importance.low,
      priority: Priority.low,
      category: AndroidNotificationCategory.workout,
      visibility: NotificationVisibility.public,
      ongoing: true,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showWhen: false,
      actions: [
        AndroidNotificationAction(
          'action_pause_resume',
          'Pausar / Reanudar',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'action_skip_next',
          'Siguiente Serie',
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: false,
      presentAlert: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = 'Gymcel: $exerciseName ($setLabel)';
    final body = '$phaseText: ${remainingSeconds}s ${isPaused ? "(Pausado)" : ""}';

    await _notificationsPlugin.show(
      1001,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> triggerWristVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 500, 200, 500]);
      }
    } catch (_) {}
  }

  Future<void> cancelWorkoutNotification() async {
    if (_isInitialized) {
      await _notificationsPlugin.cancel(1001);
      await _notificationsPlugin.cancel(1002);
    }
  }
}
