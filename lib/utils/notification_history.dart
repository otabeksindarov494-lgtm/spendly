import 'dart:convert';

import 'reminder_planner.dart';

/// Eslatma turi — ro'yxatdagi ikonka shunga qarab tanlanadi.
enum ReminderKind { beforeStart, start, end }

/// Bildirishnomalar ro'yxatidagi bitta yozuv.
class NotificationRecord {
  const NotificationRecord({
    required this.at,
    required this.title,
    required this.body,
    required this.kind,
  });

  factory NotificationRecord.fromPlanned(PlannedReminder reminder) =>
      NotificationRecord(
        at: reminder.at,
        title: reminder.title,
        body: reminder.body,
        // ReminderPlanner ID'si: kun * 10 + (1 — oldin, 2 — boshlanish,
        // 3 — tugash).
        kind: switch (reminder.id % 10) {
          1 => ReminderKind.beforeStart,
          2 => ReminderKind.start,
          _ => ReminderKind.end,
        },
      );

  factory NotificationRecord.fromJson(Map<String, dynamic> json) =>
      NotificationRecord(
        at: DateTime.parse(json['at'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        kind: ReminderKind.values.byName(json['kind'] as String),
      );

  final DateTime at;
  final String title;
  final String body;
  final ReminderKind kind;

  /// Bir xil vaqt va matn — bitta yozuv (qayta rejalashtirishda takrorlanmaydi).
  String get key => '${at.toIso8601String()}|$title';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'at': at.toIso8601String(),
    'title': title,
    'body': body,
    'kind': kind.name,
  };
}

/// Kelgan bildirishnomalar tarixi.
///
/// Eslatmalar lokal: iOS ilovaga "foydalanuvchi ko'rdi" degan ma'lumotni
/// bermaydi. Shuning uchun rejalashtirilgan eslatma vaqti o'tgach, u
/// "kelgan" hisoblanadi. Sof Dart — unit-test qilinadi.
abstract final class NotificationHistory {
  /// Necha kunlik tarix saqlanadi.
  static const int keepDays = 30;

  /// Mavjud tarixni yangi reja bilan birlashtiradi.
  ///
  /// - Vaqti o'tgan yozuvlar (kelganlar) o'zgarmaydi — qayta rejalashtirish
  ///   ularni o'chirmaydi.
  /// - Kelajakdagi eski yozuvlar o'rniga [planned] dagi yangilari qo'yiladi
  ///   (masalan check-in qilinsa bugungi boshlanish eslatmasi rejadan
  ///   chiqadi — tarixda ham "kelmaydi").
  /// - [keepDays] dan eskilari tashlanadi.
  static List<NotificationRecord> merge({
    required List<NotificationRecord> existing,
    required List<PlannedReminder> planned,
    required DateTime now,
  }) {
    final DateTime cutoff = now.subtract(const Duration(days: keepDays));
    final Map<String, NotificationRecord> byKey = <String, NotificationRecord>{
      for (final NotificationRecord r in existing)
        if (!r.at.isAfter(now) && r.at.isAfter(cutoff)) r.key: r,
    };
    for (final PlannedReminder p in planned) {
      final NotificationRecord record = NotificationRecord.fromPlanned(p);
      byKey.putIfAbsent(record.key, () => record);
    }
    return byKey.values.toList()..sort(
      (NotificationRecord a, NotificationRecord b) => a.at.compareTo(b.at),
    );
  }

  /// Kelgan (vaqti o'tgan) yozuvlar — yangilari birinchi.
  static List<NotificationRecord> received(
    List<NotificationRecord> all,
    DateTime now,
  ) => all.where((NotificationRecord r) => !r.at.isAfter(now)).toList()
    ..sort(
      (NotificationRecord a, NotificationRecord b) => b.at.compareTo(a.at),
    );

  /// [seenAt] dan keyin kelganlar soni (qo'ng'iroqchadagi raqam).
  static int unreadCount(
    List<NotificationRecord> all,
    DateTime now,
    DateTime? seenAt,
  ) => received(all, now)
      .where((NotificationRecord r) => seenAt == null || r.at.isAfter(seenAt))
      .length;

  static String encode(List<NotificationRecord> records) =>
      jsonEncode(records.map((NotificationRecord r) => r.toJson()).toList());

  /// Buzuq ma'lumotda bo'sh ro'yxat — ilova hech qachon yiqilmaydi.
  static List<NotificationRecord> decode(String? raw) {
    if (raw == null || raw.isEmpty) return <NotificationRecord>[];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map(
            (dynamic e) =>
                NotificationRecord.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return <NotificationRecord>[];
    }
  }
}
