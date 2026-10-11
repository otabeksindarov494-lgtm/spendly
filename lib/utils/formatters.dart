import 'package:easy_localization/easy_localization.dart';
import 'time_utils.dart';

/// O'zbekcha / Xalqaro sana va pul formatlash.
abstract final class Formatters {
  static List<String> get monthsNominative => <String>[
        'month_1'.tr(),
        'month_2'.tr(),
        'month_3'.tr(),
        'month_4'.tr(),
        'month_5'.tr(),
        'month_6'.tr(),
        'month_7'.tr(),
        'month_8'.tr(),
        'month_9'.tr(),
        'month_10'.tr(),
        'month_11'.tr(),
        'month_12'.tr(),
      ];

  static List<String> get monthsShort => <String>[
        'month_short_1'.tr(),
        'month_short_2'.tr(),
        'month_short_3'.tr(),
        'month_short_4'.tr(),
        'month_short_5'.tr(),
        'month_short_6'.tr(),
        'month_short_7'.tr(),
        'month_short_8'.tr(),
        'month_short_9'.tr(),
        'month_short_10'.tr(),
        'month_short_11'.tr(),
        'month_short_12'.tr(),
      ];

  /// `DateTime.weekday` (1 = Dushanba … 7 = Yakshanba) bo'yicha.
  static List<String> get weekdaysShort => <String>[
        'weekday_short_1'.tr(),
        'weekday_short_2'.tr(),
        'weekday_short_3'.tr(),
        'weekday_short_4'.tr(),
        'weekday_short_5'.tr(),
        'weekday_short_6'.tr(),
        'weekday_short_7'.tr(),
      ];

  static List<String> get weekdaysFull => <String>[
        'weekday_1'.tr(),
        'weekday_2'.tr(),
        'weekday_3'.tr(),
        'weekday_4'.tr(),
        'weekday_5'.tr(),
        'weekday_6'.tr(),
        'weekday_7'.tr(),
      ];

  /// 5000000 → "5 000 000".
  static String number(num value) {
    final bool negative = value < 0;
    final String digits = value.abs().round().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return negative ? '-${buffer.toString()}' : buffer.toString();
  }

  /// 5000000 → "5 000 000 so'm".
  static String money(num value, {String? currency}) {
    final String defaultCurrency = 'currency_so_m'.tr();
    final String curr = currency ?? defaultCurrency;
    final String localizedCurr =
        (curr == 'so\'m' || curr == 'som') ? defaultCurrency : curr;
    return '${number(value)} $localizedCurr';
  }

  /// Ishorasi bilan: 450000 → "+450 000 so'm".
  static String signedMoney(num value, {String? currency}) {
    final String sign = value > 0 ? '+' : '';
    return '$sign${money(value, currency: currency)}';
  }

  /// "Sentabr 2026".
  static String monthYear(DateTime date) =>
      '${monthsNominative[date.month - 1]} ${date.year}';

  /// "Dush, 1-sen".
  static String shortDayLabel(DateTime date) =>
      '${weekdaysShort[date.weekday - 1]}, ${date.day}-${monthsShort[date.month - 1]}';

  /// "2-sentabr, 2026".
  static String longDate(DateTime date) =>
      '${date.day}-${monthsNominative[date.month - 1].toLowerCase()}, ${date.year}';

  /// [DateTime]dan "09:05".
  static String time(DateTime date) =>
      TimeUtils.hmFromMinutes(TimeUtils.minutesOfDay(date));

  /// 9.08 → "9s 05daq".
  static String hours(double value) {
    final int totalMinutes = (value * 60).round();
    final int h = totalMinutes ~/ 60;
    final int m = totalMinutes % 60;
    return 'hours_and_minutes'.tr(
      args: [h.toString(), m.toString().padLeft(2, '0')],
    );
  }

  /// 95 → "1s 35daq", 40 → "40 daq".
  static String minutes(int value) {
    if (value < 60) return 'minutes_only'.tr(args: [value.toString()]);
    return 'hours_and_minutes'.tr(
      args: [(value ~/ 60).toString(), (value % 60).toString().padLeft(2, '0')],
    );
  }

  /// [1,2,3,4,5] → "Dush, Sesh, Chor, Pay, Jum".
  static String workDays(List<int> days) {
    final List<int> sorted = List<int>.of(days)..sort();
    return sorted
        .where((int d) => d >= 1 && d <= 7)
        .map((int d) => weekdaysShort[d - 1])
        .join(', ');
  }
}
