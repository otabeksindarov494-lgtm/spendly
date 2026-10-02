import 'time_utils.dart';

/// Bitta rejalashtirilgan eslatma.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  /// Bildirishnoma ID'si — kun va tur bo'yicha barqaror.
  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// Rejaning o'zgarganini aniqlash uchun (bir xil reja qayta yozilmaydi).
  String get signature => '$id@${at.toIso8601String()}';
}

/// Ish vaqti eslatmalarini hisoblaydi.
///
/// Bu fayl ataylab sof Dart (Flutter va plagin import'isiz) — shu sabab
/// uni unit-test qilish mumkin. Haqiqiy rejalashtirish
/// `NotificationService`da.
abstract final class ReminderPlanner {
  /// Necha kun oldinga rejalashtiriladi. Ilova har ochilganda reja
  /// yangilanadi; 14 kun ichida bir marta ham ochilmasa eslatmalar to'xtaydi.
  static const int daysAhead = 14;

  /// Ish boshlanishidan necha daqiqa oldin ogohlantiriladi.
  static const int leadMinutes = 10;

  /// [now] dan keyingi [days] kun uchun eslatmalar.
  ///
  /// Faqat [workDays] dagi kunlar (`DateTime.weekday`: 1 = Dushanba).
  /// Bugun allaqachon check-in qilingan bo'lsa ([checkedInToday]) bugungi
  /// "boshlanadi"/"boshlandi" eslatmalari, check-out qilingan bo'lsa
  /// ([checkedOutToday]) "tugadi" eslatmasi chiqarilmaydi. O'tib ketgan
  /// vaqtlar ham tashlab yuboriladi.
  static List<PlannedReminder> plan({
    required DateTime now,
    required String workStartTime,
    required String workEndTime,
    required List<int> workDays,
    bool checkedInToday = false,
    bool checkedOutToday = false,
    int days = daysAhead,
  }) {
    final int startMinutes = TimeUtils.minutesFromHmOr(workStartTime, 9 * 60);
    final int endMinutes = TimeUtils.minutesFromHmOr(workEndTime, 18 * 60);
    final String startLabel = TimeUtils.hmFromMinutes(startMinutes);

    final List<PlannedReminder> result = <PlannedReminder>[];
    for (int offset = 0; offset < days; offset++) {
      // `DateTime(y, m, d + offset)` — yozgi vaqtga o'tishda ham to'g'ri kun.
      final DateTime day = DateTime(now.year, now.month, now.day + offset);
      if (!workDays.contains(day.weekday)) continue;

      final bool isToday = offset == 0;
      final DateTime start = day.add(Duration(minutes: startMinutes));
      DateTime end = day.add(Duration(minutes: endMinutes));
      // Tungi smena: tugash vaqti boshlanishdan oldin bo'lsa — ertasi kun.
      if (!end.isAfter(start)) end = end.add(const Duration(days: 1));

      final List<PlannedReminder> candidates = <PlannedReminder>[
        if (!(isToday && checkedInToday)) ...<PlannedReminder>[
          PlannedReminder(
            id: offset * 10 + 1,
            at: start.subtract(const Duration(minutes: leadMinutes)),
            title: '$leadMinutes daqiqadan keyin ish boshlanadi',
            body: 'Ish $startLabel da boshlanadi. Kelganingizda '
                '"Ishga keldim"ni bosishni unutmang.',
          ),
          PlannedReminder(
            id: offset * 10 + 2,
            at: start,
            title: 'Ish vaqti boshlandi',
            body: 'Ishga kelgan bo\'lsangiz, "Ishga keldim" tugmasini bosing.',
          ),
        ],
        if (!(isToday && checkedOutToday))
          PlannedReminder(
            id: offset * 10 + 3,
            at: end,
            title: 'Ish vaqti tugadi',
            body: 'Ketayotganingizda "Ishdan ketyapman" tugmasini bosing.',
          ),
      ];

      result.addAll(
        candidates.where((PlannedReminder r) => r.at.isAfter(now)),
      );
    }
    return result;
  }
}
