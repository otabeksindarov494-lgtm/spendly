import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/models/attendance_model.dart';
import 'package:spendly/utils/month_days.dart';

void main() {
  const List<int> weekdays = <int>[1, 2, 3, 4, 5];

  Attendance present(String date) => Attendance(
    id: date,
    date: date,
    checkInTime: DateTime.parse('${date}T09:00:00'),
    checkOutTime: DateTime.parse('${date}T18:00:00'),
  );

  test('joriy oyda bugungacha har bir kun, yangisi birinchi', () {
    // 2026-10-07 — Chorshanba.
    final List<ReportDay> days = MonthDays.build(
      month: DateTime(2026, 10),
      records: <Attendance>[present('2026-10-01'), present('2026-10-06')],
      workDays: weekdays,
      now: DateTime(2026, 10, 7, 8),
    );
    expect(days.length, 7);
    expect(days.first.date, DateTime(2026, 10, 7));
    expect(days.last.date, DateTime(2026, 10, 1));
  });

  test('turlar: yozuv, kelmadi, dam olish, bugun', () {
    final List<ReportDay> days = MonthDays.build(
      month: DateTime(2026, 10),
      records: <Attendance>[present('2026-10-01'), present('2026-10-06')],
      workDays: weekdays,
      now: DateTime(2026, 10, 7, 8),
    );
    ReportDayKind kindOf(int day) =>
        days.firstWhere((ReportDay d) => d.date.day == day).kind;

    expect(kindOf(1), ReportDayKind.recorded); // Payshanba, kelgan
    expect(kindOf(2), ReportDayKind.absent); // Juma, kelmagan
    expect(kindOf(3), ReportDayKind.dayOff); // Shanba
    expect(kindOf(4), ReportDayKind.dayOff); // Yakshanba
    expect(kindOf(5), ReportDayKind.absent); // Dushanba
    expect(kindOf(6), ReportDayKind.recorded);
    expect(kindOf(7), ReportDayKind.today); // bugun, hali qayd yo'q
  });

  test('dam olish kunida ishlagan bo\'lsa — yozuv sifatida ko\'rinadi', () {
    final List<ReportDay> days = MonthDays.build(
      month: DateTime(2026, 10),
      records: <Attendance>[present('2026-10-03')],
      workDays: weekdays,
      now: DateTime(2026, 10, 4, 12),
    );
    expect(
      days.firstWhere((ReportDay d) => d.date.day == 3).kind,
      ReportDayKind.recorded,
    );
  });

  test('o\'tgan oy to\'liq ko\'rsatiladi', () {
    final List<ReportDay> days = MonthDays.build(
      month: DateTime(2026, 9),
      records: <Attendance>[],
      workDays: weekdays,
      now: DateTime(2026, 10, 7),
    );
    expect(days.length, 30);
    expect(days.where((ReportDay d) => d.kind == ReportDayKind.today), isEmpty);
  });

  test('kelajakdagi oy uchun bo\'sh ro\'yxat', () {
    expect(
      MonthDays.build(
        month: DateTime(2026, 11),
        records: <Attendance>[],
        workDays: weekdays,
        now: DateTime(2026, 10, 7),
      ),
      isEmpty,
    );
  });
}
