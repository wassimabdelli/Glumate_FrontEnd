import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class HydrationNotificationService {
  static final HydrationNotificationService _instance = HydrationNotificationService._internal();
  factory HydrationNotificationService() => _instance;
  HydrationNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    // Set local timezone - using UTC as default for simplicity
    // The package will use system timezone automatically
    tz.setLocalLocation(tz.local);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'hydration_channel',
      'Rappels Hydratation',
      description: 'Notifications pour rappels d\'hydratation',
      importance: Importance.high,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
    }

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }

    return true;
  }

  Future<void> scheduleNotifications(int totalGlasses) async {
    await cancelAllNotifications();

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'hydration_count_${today.year}-${today.month}-${today.day}';

    // Reset counter if it's a new day
    if (!prefs.containsKey(key)) {
      await prefs.setInt(key, 0);
    }

    final currentCount = prefs.getInt(key) ?? 0;

    // If already reached target, don't schedule
    if (currentCount >= totalGlasses) {
      return;
    }

    // Schedule notifications between 7h and 22h
    final startHour = 18;
    final endHour = 19;
    final totalHours = endHour - startHour;
    final glassesRemaining = totalGlasses - currentCount;
    final interval = totalHours / glassesRemaining;

    for (int i = 0; i < glassesRemaining; i++) {
      final hour = startHour + (i * interval).floor();
      final minute = ((i * interval) % 1 * 60).toInt();

      var scheduledTime = tz.TZDateTime(
        tz.local,
        today.year,
        today.month,
        today.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledTime.isBefore(DateTime.now())) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        i,
        'Rappel Hydratation',
        'Pense à boire un verre d\'eau 💧 (0.35L)',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel',
            'Rappels Hydratation',
            channelDescription: 'Notifications pour rappels d\'hydratation',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            badgeNumber: 1,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> incrementGlassCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'hydration_count_${today.year}-${today.month}-${today.day}';

    final currentCount = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, currentCount + 1);

    // Check if target reached and cancel remaining notifications
    final targetKey = 'hydration_target_${today.year}-${today.month}-${today.day}';
    final targetGlasses = prefs.getInt(targetKey) ?? 0;

    if (currentCount + 1 >= targetGlasses) {
      await cancelAllNotifications();
    }
  }

  Future<int> getGlassCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'hydration_count_${today.year}-${today.month}-${today.day}';
    return prefs.getInt(key) ?? 0;
  }

  Future<void> saveTargetGlasses(int targetGlasses) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final key = 'hydration_target_${today.year}-${today.month}-${today.day}';
    await prefs.setInt(key, targetGlasses);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap if needed
    debugPrint('Notification tapped: ${response.payload}');
  }

  // TEST METHODS - TO REMOVE AFTER VALIDATION
  Future<void> scheduleTestRepeatingNotification() async {
    debugPrint('scheduleTestRepeatingNotification: début');
    try {
      // Show immediate notification for testing
      await _notificationsPlugin.show(
        888,
        'Test Hydratation (immédiat)',
        'Pense à boire un verre d\'eau 💧 - notification de test immédiate',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'hydration_channel',
            'Rappels Hydratation',
            channelDescription: 'Notifications pour rappels d\'hydratation',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(badgeNumber: 1),
        ),
      );
      debugPrint('scheduleTestRepeatingNotification: notification immédiate affichée');
    } catch (e) {
      debugPrint('scheduleTestRepeatingNotification: erreur - $e');
    }
  }

  Future<void> cancelTestRepeatingNotification() async {
    await _notificationsPlugin.cancel(888);
  }
}
