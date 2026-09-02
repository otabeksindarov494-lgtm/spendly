/// Vaqt/sana yordamchilari.
///
/// Bu fayl ataylab sof Dart (Flutter import'isiz) — shu sabab uni
/// widget muhitisiz unit-test qilish mumkin.
abstract final class TimeUtils {
  /// "09:00" → 540 (yarim tundan boshlab daqiqalar).
  ///
  /// Format buzuq bo'lsa [FormatException] tashlaydi.
  static int minutesFromHm(String hm) {
    final List<String> parts = hm.split(':');
    if (parts.length != 2) {
      throw FormatException('Vaqt formati "HH:mm" bo\'lishi kerak', hm);
    }
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      throw FormatException('Vaqt qiymati noto\'g\'ri', hm);
    }
    return h * 60 + m;
  }

  /// Buzuq qiymatda [fallback] qaytaradi — UI hech qachon crash bo'lmasligi uchun.
  static int minutesFromHmOr(String? hm, int fallback) {
    if (hm == null) return fallback;
    try {
      return minutesFromHm(hm);
    } on FormatException {
      return fallback;
    }
  }

  /// 540 → "09:00".
  static String hmFromMinutes(int minutes) {
    final int normalized = minutes % (24 * 60);
    final int h = normalized ~/ 60;
    final int m = normalized % 60;
    return '${_two(h)}:${_two(m)}';
  }

  /// [DateTime]dan yarim tundan boshlab o'tgan daqiqalar.
  static int minutesOfDay(DateTime time) => time.hour * 60 + time.minute;

  /// Firestore'da `date` maydoni uchun kalit: "2026-09-02".
  static String dateKey(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  /// "2026-09-02" → [DateTime] (mahalliy, kun boshi).
  static DateTime? dateFromKey(String key) {
    final List<String> parts = key.split('-');
    if (parts.length != 3) return null;
    final int? y = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    final int? d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// Vaqt qismisiz kun boshi.
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Oydagi kunlar soni.
  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Ikkala sana bir xil kunmi?
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _two(int value) => value.toString().padLeft(2, '0');
}
