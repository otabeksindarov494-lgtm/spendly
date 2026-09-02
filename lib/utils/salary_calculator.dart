import 'time_utils.dart';

/// Bir kunlik hisob-kitob natijasi.
class DailyCalculation {
  const DailyCalculation({
    required this.workedHours,
    required this.lateMinutes,
    required this.earlyLeaveMinutes,
    required this.penaltyAmount,
    required this.dailyEarning,
  });

  final double workedHours;
  final int lateMinutes;
  final int earlyLeaveMinutes;
  final double penaltyAmount;
  final double dailyEarning;
}

/// Oylik yig'ma statistika.
class MonthlySummary {
  const MonthlySummary({
    required this.earnedAmount,
    required this.penaltyAmount,
    required this.workedHours,
    required this.presentDays,
    required this.absentDays,
    required this.lateMinutes,
    required this.earlyLeaveMinutes,
    required this.plannedWorkDays,
    required this.elapsedWorkDays,
  });

  /// Hozirgacha ishlab topilgan (jarimalar ayirilgan).
  final double earnedAmount;
  final double penaltyAmount;
  final double workedHours;
  final int presentDays;

  /// Ish kuni bo'lib, kelinmagan va allaqachon o'tib ketgan kunlar.
  final int absentDays;
  final int lateMinutes;
  final int earlyLeaveMinutes;

  /// Oydagi jami belgilangan ish kunlari.
  final int plannedWorkDays;

  /// Shundan hozirgacha o'tgan ish kunlari (progress bar uchun).
  final int elapsedWorkDays;

  /// 0.0 – 1.0 oralig'ida.
  double get progress =>
      plannedWorkDays == 0 ? 0 : (elapsedWorkDays / plannedWorkDays).clamp(0, 1);
}

/// Maosh, kechikish va jarima formulalari (PROJECT.md 5.2-bo'lim).
///
/// Sof Dart — Flutter'ga bog'liq emas, shuning uchun to'liq unit-test
/// qilinadi. `workDays` ro'yxati `DateTime.weekday` konvensiyasida:
/// 1 = Dushanba … 7 = Yakshanba (PRD'dagi `[1,2,3,4,5]` = Dush–Juma
/// aynan shunga mos tushadi).
abstract final class SalaryCalculator {
  /// Berilgan oyda nechta belgilangan ish kuni bor.
  static int workDaysInMonth(int year, int month, List<int> workDays) {
    if (workDays.isEmpty) return 0;
    final Set<int> allowed = workDays.toSet();
    final int days = TimeUtils.daysInMonth(year, month);
    int count = 0;
    for (int day = 1; day <= days; day++) {
      if (allowed.contains(DateTime(year, month, day).weekday)) count++;
    }
    return count;
  }

  /// Oyning boshidan [upTo] sanasigacha (shu kun ham kiradi) o'tgan ish kunlari.
  static int elapsedWorkDaysInMonth(
    int year,
    int month,
    List<int> workDays,
    DateTime upTo,
  ) {
    if (workDays.isEmpty) return 0;
    final Set<int> allowed = workDays.toSet();
    final int lastDay = (upTo.year == year && upTo.month == month)
        ? upTo.day
        : (DateTime(year, month).isBefore(DateTime(upTo.year, upTo.month))
              ? TimeUtils.daysInMonth(year, month)
              : 0);
    int count = 0;
    for (int day = 1; day <= lastDay; day++) {
      if (allowed.contains(DateTime(year, month, day).weekday)) count++;
    }
    return count;
  }

  /// kunlik_stavka = oylik_maosh / oydagi_ish_kunlari.
  ///
  /// Ish kunlari 0 bo'lsa 0 qaytaradi (nolga bo'lishdan himoya).
  static double dailyRate({
    required double monthlySalary,
    required int workDaysCount,
  }) {
    if (workDaysCount <= 0) return 0;
    return monthlySalary / workDaysCount;
  }

  /// Bir ish kunidagi haqiqiy ish soatlari.
  ///
  /// Tushlik tanaffusi ayiriladi: 09:00–18:00 va 60 daqiqa tushlik = 8 soat.
  /// Bu soatlik stavkaga ham ta'sir qiladi.
  ///
  /// Tugash vaqti boshlanish vaqtidan oldin bo'lsa (tungi smena),
  /// yarim tunni kesib o'tgan deb hisoblanadi.
  static double shiftHours({
    required int workStartMinutes,
    required int workEndMinutes,
    int lunchBreakMinutes = 0,
  }) {
    int diff = workEndMinutes - workStartMinutes;
    if (diff <= 0) diff += 24 * 60;
    diff -= lunchBreakMinutes;
    // Tanaffus smenadan uzun bo'lib qolsa, nolga tushib qolmasin.
    if (diff <= 0) return 0;
    return diff / 60.0;
  }

  /// soatlik_stavka = kunlik_stavka / smena_soatlari.
  static double hourlyRate({
    required double dailyRate,
    required int workStartMinutes,
    required int workEndMinutes,
    int lunchBreakMinutes = 0,
  }) {
    final double hours = shiftHours(
      workStartMinutes: workStartMinutes,
      workEndMinutes: workEndMinutes,
      lunchBreakMinutes: lunchBreakMinutes,
    );
    if (hours <= 0) return 0;
    return dailyRate / hours;
  }

  /// Kechikkan daqiqalar (vaqtida yoki erta kelsa — 0).
  static int lateMinutes({
    required DateTime checkIn,
    required int workStartMinutes,
  }) {
    final int diff = TimeUtils.minutesOfDay(checkIn) - workStartMinutes;
    return diff > 0 ? diff : 0;
  }

  /// Erta ketgan daqiqalar (vaqtida yoki kech ketsa — 0).
  static int earlyLeaveMinutes({
    required DateTime checkOut,
    required int workEndMinutes,
  }) {
    final int diff = workEndMinutes - TimeUtils.minutesOfDay(checkOut);
    return diff > 0 ? diff : 0;
  }

  /// Amalda ishlangan soat.
  ///
  /// Ish joyida o'tkazilgan vaqtdan tushlik tanaffusi ayiriladi — lekin
  /// faqat shu vaqt tanaffusdan uzun bo'lsa. Aks holda qisqa muddat
  /// manfiyga tushib ketardi.
  static double workedHours({
    required DateTime checkIn,
    required DateTime checkOut,
    int lunchBreakMinutes = 0,
  }) {
    int minutes = checkOut.difference(checkIn).inMinutes;
    if (minutes <= 0) return 0;
    if (minutes > lunchBreakMinutes) minutes -= lunchBreakMinutes;
    return minutes / 60.0;
  }

  /// Bir kunlik to'liq hisob-kitob.
  ///
  /// Kechikish va erta ketish HAR DOIM yoziladi — ular statistika uchun
  /// kerak. Pulga ta'siri esa ikki sozlamaga bog'liq:
  ///
  ///  * [penaltyEnabled] `false` — jarima 0 (ish joyida pul ushlanmaydi).
  ///  * [isFixedSalary] `true` — kunlik maosh yozilmaydi, chunki fixed
  ///    kelishuvda pul kunlarga bo'linmaydi. Oylik summa
  ///    [MonthlySummary] darajasida qo'shiladi.
  ///
  /// [checkOut] `null` bo'lsa (kun hali tugamagan) erta ketish jarimasi
  /// hisoblanmaydi — foydalanuvchi hali ishda.
  static DailyCalculation calculateDay({
    required DateTime checkIn,
    DateTime? checkOut,
    required int workStartMinutes,
    required int workEndMinutes,
    required double dailyRate,
    int lunchBreakMinutes = 0,
    bool penaltyEnabled = true,
    bool isFixedSalary = false,
  }) {
    final double perHour = hourlyRate(
      dailyRate: dailyRate,
      workStartMinutes: workStartMinutes,
      workEndMinutes: workEndMinutes,
      lunchBreakMinutes: lunchBreakMinutes,
    );
    final double perMinute = perHour / 60.0;

    final int late = lateMinutes(
      checkIn: checkIn,
      workStartMinutes: workStartMinutes,
    );
    final int early = checkOut == null
        ? 0
        : earlyLeaveMinutes(
            checkOut: checkOut,
            workEndMinutes: workEndMinutes,
          );

    final double penalty =
        penaltyEnabled ? (late + early) * perMinute : 0;

    final double earning;
    if (isFixedSalary || checkOut == null) {
      // Fixed: pul kunlarga bo'linmaydi. Kun ochiq: hali yopilmagan.
      earning = 0;
    } else {
      earning = (dailyRate - penalty).clamp(0.0, double.infinity);
    }

    return DailyCalculation(
      workedHours: checkOut == null
          ? 0
          : workedHours(
              checkIn: checkIn,
              checkOut: checkOut,
              lunchBreakMinutes: lunchBreakMinutes,
            ),
      lateMinutes: late,
      earlyLeaveMinutes: early,
      penaltyAmount: penalty,
      dailyEarning: earning,
    );
  }

  /// Oylik yakuniy summa.
  ///
  /// * **Fixed** — kelishilgan summa to'liq beriladi. Kelmagan kun uchun
  ///   ushlanmaydi. Jarima yoqilgan bo'lsa, faqat u ayiriladi.
  /// * **Kunlik hisob** — kunlik summalar yig'indisi (jarima allaqachon
  ///   har kunning ichida ayirilgan).
  static double monthlyEarning({
    required bool isFixedSalary,
    required double monthlySalary,
    required double sumOfDailyEarnings,
    required double totalPenalty,
  }) {
    if (!isFixedSalary) return sumOfDailyEarnings;
    return (monthlySalary - totalPenalty).clamp(0.0, double.infinity);
  }
}
