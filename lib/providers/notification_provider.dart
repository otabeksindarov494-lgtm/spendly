import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_model.dart';
import '../models/user_profile_model.dart';
import '../services/notification_service.dart';
import '../utils/reminder_planner.dart';
import 'attendance_provider.dart';
import 'core_providers.dart';
import 'profile_provider.dart';

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((Ref ref) => NotificationService());

/// Ish vaqti eslatmalari yoqilganmi — qurilmada saqlanadi, sukut: yoqiq.
class NotificationsEnabledNotifier extends Notifier<bool> {
  static const String storageKey = 'workRemindersEnabled';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(storageKey) ?? true;

  Future<void> setEnabled(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(storageKey, enabled);
    if (enabled) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
  }
}

final NotifierProvider<NotificationsEnabledNotifier, bool>
    notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
  NotificationsEnabledNotifier.new,
);

/// Qurilmada turishi kerak bo'lgan eslatmalar.
///
/// `null` — ma'lumot hali yuklanmagan, mavjud eslatmalarga tegilmaydi.
/// Bo'sh ro'yxat — hammasi bekor qilinadi (tizimdan chiqilgan, eslatmalar
/// o'chirilgan yoki onboarding tugallanmagan).
final Provider<List<PlannedReminder>?> reminderPlanProvider =
    Provider<List<PlannedReminder>?>((Ref ref) {
  if (ref.watch(currentUserIdProvider) == null) {
    return const <PlannedReminder>[];
  }
  if (!ref.watch(notificationsEnabledProvider)) {
    return const <PlannedReminder>[];
  }

  final AsyncValue<UserProfile?> profile = ref.watch(profileProvider);
  final AsyncValue<Attendance?> today = ref.watch(todayAttendanceProvider);
  if (!profile.hasValue || !today.hasValue) return null;

  final UserProfile? data = profile.value;
  if (data == null || !data.onboardingCompleted) {
    return const <PlannedReminder>[];
  }

  final Attendance? record = today.value;
  return ReminderPlanner.plan(
    now: DateTime.now(),
    workStartTime: data.workStartTime,
    workEndTime: data.workEndTime,
    workDays: data.workDays,
    checkedInToday: record?.checkInTime != null,
    checkedOutToday: record?.checkOutTime != null,
  );
});

/// [reminderPlanProvider] o'zgarganda qurilmadagi eslatmalarni yangilaydi.
///
/// Uni doim ekranda turadigan widget (`AuthGate`) kuzatib turishi kerak —
/// shunda tizimdan chiqilganda ham eslatmalar bekor qilinadi.
final Provider<void> reminderSyncProvider = Provider<void>((Ref ref) {
  ref.listen<List<PlannedReminder>?>(
    reminderPlanProvider,
    (List<PlannedReminder>? _, List<PlannedReminder>? plan) {
      if (plan != null) ref.read(notificationServiceProvider).sync(plan);
    },
    fireImmediately: true,
  );
});
