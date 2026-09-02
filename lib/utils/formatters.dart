import 'time_utils.dart';

/// O'zbekcha sana/pul formatlash.
///
/// `intl` locale ma'lumotlariga bog'lanmaslik uchun nomlar qo'lda
/// berilgan — shunda `initializeDateFormatting` chaqirish shart emas
/// va format har qanday qurilmada bir xil chiqadi.
abstract final class Formatters {
  static const List<String> monthsNominative = <String>[
    'Yanvar',
    'Fevral',
    'Mart',
    'Aprel',
    'May',
    'Iyun',
    'Iyul',
    'Avgust',
    'Sentabr',
    'Oktabr',
    'Noyabr',
    'Dekabr',
  ];

  static const List<String> monthsShort = <String>[
    'yan',
    'fev',
    'mar',
    'apr',
    'may',
    'iyn',
    'iyl',
    'avg',
    'sen',
    'okt',
    'noy',
    'dek',
  ];

  /// `DateTime.weekday` (1 = Dushanba … 7 = Yakshanba) bo'yicha.
  static const List<String> weekdaysShort = <String>[
    'Dush',
    'Sesh',
    'Chor',
    'Pay',
    'Jum',
    'Shan',
    'Yak',
  ];

  static const List<String> weekdaysFull = <String>[
    'Dushanba',
    'Seshanba',
    'Chorshanba',
    'Payshanba',
    'Juma',
    'Shanba',
    'Yakshanba',
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
  static String money(num value, {String currency = 'so\'m'}) =>
      '${number(value)} $currency';

  /// Ishorasi bilan: 450000 → "+450 000 so'm".
  static String signedMoney(num value, {String currency = 'so\'m'}) {
    final String sign = value > 0 ? '+' : '';
    return '$sign${number(value)} $currency';
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
    return '${h}s ${m.toString().padLeft(2, '0')}daq';
  }

  /// 95 → "1s 35daq", 40 → "40 daq".
  static String minutes(int value) {
    if (value < 60) return '$value daq';
    return '${value ~/ 60}s ${(value % 60).toString().padLeft(2, '0')}daq';
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
