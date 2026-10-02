import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/utils/notification_history.dart';
import 'package:spendly/utils/reminder_planner.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 5, 12, 0);

  PlannedReminder planned(int id, DateTime at, String title) =>
      PlannedReminder(id: id, at: at, title: title, body: 'matn');

  NotificationRecord record(DateTime at, String title) => NotificationRecord(
    at: at,
    title: title,
    body: 'matn',
    kind: ReminderKind.start,
  );

  test('vaqti o\'tgan rejadagi eslatma "kelgan" bo\'ladi', () {
    final List<NotificationRecord> all = NotificationHistory.merge(
      existing: <NotificationRecord>[],
      planned: <PlannedReminder>[
        planned(2, DateTime(2026, 10, 5, 9), 'Ish vaqti boshlandi'),
        planned(3, DateTime(2026, 10, 5, 18), 'Ish vaqti tugadi'),
      ],
      now: DateTime(2026, 10, 5, 7),
    );
    // Soat 12 da: 09:00 dagisi kelgan, 18:00 dagisi hali yo'q.
    final List<NotificationRecord> got = NotificationHistory.received(all, now);
    expect(got.map((NotificationRecord r) => r.title), <String>[
      'Ish vaqti boshlandi',
    ]);
    expect(got.single.kind, ReminderKind.start);
  });

  test('kelgan yozuvlarni qayta rejalashtirish o\'chirmaydi', () {
    final List<NotificationRecord> all = NotificationHistory.merge(
      existing: <NotificationRecord>[
        record(DateTime(2026, 10, 5, 9), 'Kelgan'),
      ],
      planned: <PlannedReminder>[],
      now: now,
    );
    expect(all.length, 1);
  });

  test('rejadan chiqqan kelajakdagi yozuv tarixdan ham ketadi', () {
    final List<NotificationRecord> all = NotificationHistory.merge(
      existing: <NotificationRecord>[
        record(DateTime(2026, 10, 5, 18), 'Kelajak'),
      ],
      planned: <PlannedReminder>[],
      now: now,
    );
    expect(all, isEmpty);
  });

  test('takroriy reja ikki marta yozilmaydi', () {
    final List<PlannedReminder> plan = <PlannedReminder>[
      planned(2, DateTime(2026, 10, 5, 9), 'Ish vaqti boshlandi'),
    ];
    final List<NotificationRecord> first = NotificationHistory.merge(
      existing: <NotificationRecord>[],
      planned: plan,
      now: DateTime(2026, 10, 5, 7),
    );
    final List<NotificationRecord> second = NotificationHistory.merge(
      existing: first,
      planned: plan,
      now: DateTime(2026, 10, 5, 8),
    );
    expect(second.length, 1);
  });

  test('30 kundan eskilari tashlanadi', () {
    final List<NotificationRecord> all = NotificationHistory.merge(
      existing: <NotificationRecord>[
        record(now.subtract(const Duration(days: 31)), 'Eski'),
        record(now.subtract(const Duration(days: 2)), 'Yangi'),
      ],
      planned: <PlannedReminder>[],
      now: now,
    );
    expect(all.map((NotificationRecord r) => r.title), <String>['Yangi']);
  });

  test('kelganlar yangidan eskiga tartiblanadi', () {
    final List<NotificationRecord> got = NotificationHistory.received(
      <NotificationRecord>[
        record(DateTime(2026, 10, 4, 9), 'Kecha'),
        record(DateTime(2026, 10, 5, 9), 'Bugun'),
      ],
      now,
    );
    expect(got.map((NotificationRecord r) => r.title), <String>[
      'Bugun',
      'Kecha',
    ]);
  });

  test('o\'qilmaganlar soni seenAt dan keyingilar', () {
    final List<NotificationRecord> all = <NotificationRecord>[
      record(DateTime(2026, 10, 5, 8, 50), 'A'),
      record(DateTime(2026, 10, 5, 9), 'B'),
      record(DateTime(2026, 10, 5, 18), 'Kelajak'),
    ];
    expect(NotificationHistory.unreadCount(all, now, null), 2);
    expect(
      NotificationHistory.unreadCount(all, now, DateTime(2026, 10, 5, 8, 55)),
      1,
    );
  });

  test('JSON saqlash va o\'qish; buzuq ma\'lumotda bo\'sh ro\'yxat', () {
    final List<NotificationRecord> all = <NotificationRecord>[
      record(DateTime(2026, 10, 5, 9), 'Ish vaqti boshlandi'),
    ];
    final List<NotificationRecord> back = NotificationHistory.decode(
      NotificationHistory.encode(all),
    );
    expect(back.single.title, 'Ish vaqti boshlandi');
    expect(back.single.kind, ReminderKind.start);
    expect(NotificationHistory.decode('buzuq'), isEmpty);
    expect(NotificationHistory.decode(null), isEmpty);
  });
}
