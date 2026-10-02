import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/reminder_planner.dart';

/// Ish vaqti eslatmalarini qurilmaning o'zida rejalashtiradi.
///
/// Server yoki push xizmati ishlatilmaydi — bildirishnomalar telefonning
/// o'z tizimi orqali keladi, internet shart emas.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'work_reminders';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Ish vaqti eslatmalari',
      channelDescription:
          'Ish boshlanishi va tugashi haqida eslatmalar.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
    ),
  );

  Future<void>? _initialization;
  bool _permissionRequested = false;

  /// Oxirgi yozilgan reja — bir xil reja qayta yozilmasligi uchun.
  String? _lastSignature;

  Future<void> _ensureInitialized() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (error) {
      // Mintaqa aniqlanmasa — O'zbekiston vaqti (ilova shu yerga mo'ljallangan).
      debugPrint('Vaqt mintaqasi aniqlanmadi: $error');
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        // Oq "S" shaffof fonda — Android bildirishnoma ikonkasi
        // monoxrom bo'lishi kerak.
        android: AndroidInitializationSettings('@drawable/ic_launcher_foreground'),
        // Ruxsat ilova ochilishi bilan emas, eslatmalar yoqilganda so'raladi.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
  }

  /// Bildirishnoma ruxsatini so'raydi (iOS va Android 13+).
  ///
  /// Foydalanuvchi rad etsa ham eslatmalar rejalashtiriladi — ular
  /// shunchaki ko'rsatilmaydi; tizim sozlamalaridan keyin yoqish mumkin.
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    _permissionRequested = true;

    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// Qurilmadagi eslatmalarni [reminders] bilan to'liq almashtiradi.
  ///
  /// Bo'sh ro'yxat — hammasini bekor qilish (masalan, tizimdan chiqilganda
  /// yoki eslatmalar o'chirilganda).
  Future<void> sync(List<PlannedReminder> reminders) async {
    final String signature =
        reminders.map((PlannedReminder r) => r.signature).join('|');
    if (signature == _lastSignature) return;
    _lastSignature = signature;

    try {
      await _ensureInitialized();
      if (reminders.isNotEmpty && !_permissionRequested) {
        await requestPermission();
      }

      await _plugin.cancelAll();
      for (final PlannedReminder reminder in reminders) {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: tz.TZDateTime.from(reminder.at, tz.local),
          notificationDetails: _details,
          // Aniq alarm ruxsati so'ralmaydi — Android bir necha daqiqa
          // kechiktirishi mumkin, lekin qo'shimcha ruxsat kerak emas.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (error) {
      // Keyingi chaqiruvda qayta urinish uchun.
      _lastSignature = null;
      debugPrint('Eslatmalar rejalashtirilmadi: $error');
    }
  }
}
