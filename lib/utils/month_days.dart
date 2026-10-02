import '../models/attendance_model.dart';
import 'time_utils.dart';

/// Hisobotdagi bir kunning turi.
enum ReportDayKind {
  /// Davomat yozuvi bor (kelgan yoki hali ishda).
  recorded,

  /// Ish kuni, lekin kelmagan (o'tgan kun).
  absent,

  /// Dam olish kuni, yozuv yo'q.
  dayOff,

  /// Bugun — ish kuni, hali qayd yo'q.
  today,
}

class ReportDay {
  const ReportDay({required this.date, required this.kind, this.record});

  final DateTime date;
  final ReportDayKind kind;
  final Attendance? record;
}

/// Tanlangan oyning HAR BIR kuni — faqat yozuvi borlari emas.
///
/// Joriy oyda bugungacha, o'tgan oyda oxirigacha; kelajakdagi kunlar
/// ko'rsatilmaydi. Yangi kunlar birinchi. Sof Dart — unit-test qilinadi.
abstract final class MonthDays {
  static List<ReportDay> build({
    required DateTime month,
    required List<Attendance> records,
    required List<int> workDays,
    required DateTime now,
  }) {
    final DateTime today = TimeUtils.startOfDay(now);
    final DateTime firstOfMonth = DateTime(month.year, month.month);
    if (firstOfMonth.isAfter(today)) return <ReportDay>[];

    final Map<String, Attendance> byDate = <String, Attendance>{
      for (final Attendance a in records) a.date: a,
    };
    final int lastDay = (month.year == today.year && month.month == today.month)
        ? today.day
        : TimeUtils.daysInMonth(month.year, month.month);
    final Set<int> allowed = workDays.toSet();

    final List<ReportDay> days = <ReportDay>[];
    for (int day = lastDay; day >= 1; day--) {
      final DateTime date = DateTime(month.year, month.month, day);
      final Attendance? record = byDate[TimeUtils.dateKey(date)];
      final ReportDayKind kind;
      if (record != null && record.hasCheckedIn) {
        kind = ReportDayKind.recorded;
      } else if (!allowed.contains(date.weekday)) {
        kind = ReportDayKind.dayOff;
      } else if (TimeUtils.isSameDay(date, today)) {
        kind = ReportDayKind.today;
      } else {
        kind = ReportDayKind.absent;
      }
      days.add(ReportDay(date: date, kind: kind, record: record));
    }
    return days;
  }
}
