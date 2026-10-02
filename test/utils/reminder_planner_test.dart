import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/utils/reminder_planner.dart';

void main() {
  // 2026-10-05 — Dushanba.
  final DateTime mondayMorning = DateTime(2026, 10, 5, 7, 0);
  const List<int> weekdays = <int>[1, 2, 3, 4, 5];

  List<PlannedReminder> planFor(
    DateTime now, {
    bool checkedIn = false,
    bool checkedOut = false,
    int days = 7,
    String start = '09:00',
    String end = '18:00',
  }) =>
      ReminderPlanner.plan(
        now: now,
        workStartTime: start,
        workEndTime: end,
        workDays: weekdays,
        checkedInToday: checkedIn,
        checkedOutToday: checkedOut,
        days: days,
      );

  test('ish kunida 3 ta eslatma: 10 daqiqa oldin, boshlanishda, tugashda', () {
    final List<PlannedReminder> today = planFor(mondayMorning, days: 1);
    expect(today.map((PlannedReminder r) => r.at), <DateTime>[
      DateTime(2026, 10, 5, 8, 50),
      DateTime(2026, 10, 5, 9, 0),
      DateTime(2026, 10, 5, 18, 0),
    ]);
    expect(today.first.title, '10 daqiqadan keyin ish boshlanadi');
    expect(today.first.body, contains('09:00'));
  });

  test('dam olish kunlarida eslatma yo\'q', () {
    final List<PlannedReminder> week = planFor(mondayMorning);
    final Set<int> weekdaysUsed =
        week.map((PlannedReminder r) => r.at.weekday).toSet();
    expect(weekdaysUsed, <int>{1, 2, 3, 4, 5});
    expect(week.length, 5 * 3);
  });

  test('check-in qilingan bo\'lsa bugungi boshlanish eslatmalari tushadi', () {
    final List<PlannedReminder> today =
        planFor(mondayMorning, checkedIn: true, days: 1);
    expect(today.map((PlannedReminder r) => r.title), <String>[
      'Ish vaqti tugadi',
    ]);
  });

  test('check-out ham qilingan bo\'lsa bugun hech narsa qolmaydi', () {
    expect(
      planFor(mondayMorning, checkedIn: true, checkedOut: true, days: 1),
      isEmpty,
    );
  });

  test('check-in faqat bugunga ta\'sir qiladi', () {
    final List<PlannedReminder> twoDays =
        planFor(mondayMorning, checkedIn: true, days: 2);
    final List<PlannedReminder> tuesday = twoDays
        .where((PlannedReminder r) => r.at.day == 6)
        .toList();
    expect(tuesday.length, 3);
  });

  test('o\'tib ketgan vaqtlar rejalashtirilmaydi', () {
    final List<PlannedReminder> today =
        planFor(DateTime(2026, 10, 5, 9, 5), days: 1);
    expect(today.map((PlannedReminder r) => r.at), <DateTime>[
      DateTime(2026, 10, 5, 18, 0),
    ]);
  });

  test('tungi smena: tugash vaqti ertasi kunga o\'tadi', () {
    final List<PlannedReminder> today = planFor(
      DateTime(2026, 10, 5, 12, 0),
      start: '22:00',
      end: '06:00',
      days: 1,
    );
    expect(today.last.at, DateTime(2026, 10, 6, 6, 0));
  });

  test('ID\'lar takrorlanmaydi', () {
    final List<PlannedReminder> all =
        planFor(mondayMorning, days: ReminderPlanner.daysAhead);
    final Set<int> ids = all.map((PlannedReminder r) => r.id).toSet();
    expect(ids.length, all.length);
  });

  test('buzuq vaqt formatida sukut qiymatlari ishlatiladi', () {
    final List<PlannedReminder> today =
        planFor(mondayMorning, start: 'xx', end: '', days: 1);
    expect(today.map((PlannedReminder r) => r.at.hour), <int>[8, 9, 18]);
  });
}
