import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_model.dart';
import '../models/user_profile_model.dart';
import '../services/attendance_service.dart';
import '../utils/salary_calculator.dart';
import 'core_providers.dart';
import 'profile_provider.dart';

/// Bugungi davomat yozuvi.
final StreamProvider<Attendance?> todayAttendanceProvider =
    StreamProvider<Attendance?>((Ref ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream<Attendance?>.value(null);
  return ref
      .watch(attendanceServiceProvider)
      .watchDay(userId, DateTime.now());
});

/// Bosh sahifadagi "Oxirgi 7 kun" ro'yxati.
final StreamProvider<List<Attendance>> last7DaysProvider =
    StreamProvider<List<Attendance>>((Ref ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream<List<Attendance>>.value(<Attendance>[]);
  final DateTime today = DateTime.now();
  return ref.watch(attendanceServiceProvider).watchRange(
        userId,
        today.subtract(const Duration(days: 6)),
        today,
      );
});

/// Hisobot ekranida tanlangan oy (oyning 1-kuni sifatida saqlanadi).
class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() =>
      state = DateTime(state.year, state.month - 1);

  void next() {
    final DateTime candidate = DateTime(state.year, state.month + 1);
    final DateTime now = DateTime.now();
    // Kelajakdagi oyga o'tishga ruxsat bermaymiz.
    if (candidate.isAfter(DateTime(now.year, now.month))) return;
    state = candidate;
  }

  /// Joriy oydan keyingi oy mavjudmi (o'ng strelka faolligi uchun).
  bool get canGoNext {
    final DateTime now = DateTime.now();
    return state.isBefore(DateTime(now.year, now.month));
  }
}

final NotifierProvider<SelectedMonthNotifier, DateTime> selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

/// Tanlangan oydagi barcha davomat yozuvlari.
final StreamProvider<List<Attendance>> monthAttendanceProvider =
    StreamProvider<List<Attendance>>((Ref ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream<List<Attendance>>.value(<Attendance>[]);
  final DateTime month = ref.watch(selectedMonthProvider);
  return ref.watch(attendanceServiceProvider).watchMonth(userId, month);
});

/// Tanlangan oy bo'yicha yig'ma statistika.
///
/// Profil yoki yozuvlar hali yuklanmagan bo'lsa `null`.
final Provider<MonthlySummary?> monthlySummaryProvider =
    Provider<MonthlySummary?>((Ref ref) {
  final UserProfile? profile = ref.watch(profileProvider).value;
  final List<Attendance>? records = ref.watch(monthAttendanceProvider).value;
  if (profile == null || records == null) return null;

  return AttendanceService.summarize(
    profile: profile,
    records: records,
    month: ref.watch(selectedMonthProvider),
  );
});

/// Joriy oy bo'yicha yig'ma statistika (bosh sahifa kartalari uchun).
final StreamProvider<List<Attendance>> currentMonthAttendanceProvider =
    StreamProvider<List<Attendance>>((Ref ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream<List<Attendance>>.value(<Attendance>[]);
  return ref
      .watch(attendanceServiceProvider)
      .watchMonth(userId, DateTime.now());
});

final Provider<MonthlySummary?> currentMonthSummaryProvider =
    Provider<MonthlySummary?>((Ref ref) {
  final UserProfile? profile = ref.watch(profileProvider).value;
  final List<Attendance>? records =
      ref.watch(currentMonthAttendanceProvider).value;
  if (profile == null || records == null) return null;

  return AttendanceService.summarize(
    profile: profile,
    records: records,
    month: DateTime.now(),
  );
});
