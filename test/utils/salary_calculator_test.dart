import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/utils/salary_calculator.dart';
import 'package:spendly/utils/time_utils.dart';

void main() {
  const List<int> monFri = <int>[1, 2, 3, 4, 5];

  group('workDaysInMonth', () {
    test('2026-yil sentabrda 22 ta ish kuni (Dush-Juma)', () {
      expect(SalaryCalculator.workDaysInMonth(2026, 9, monFri), 22);
    });

    test('2026-yil fevralda 20 ta ish kuni', () {
      expect(SalaryCalculator.workDaysInMonth(2026, 2, monFri), 20);
    });

    test('shanba qo\'shilsa ish kunlari ortadi', () {
      final int withSaturday =
          SalaryCalculator.workDaysInMonth(2026, 9, <int>[1, 2, 3, 4, 5, 6]);
      expect(withSaturday, greaterThan(22));
    });

    test('bo\'sh workDays 0 qaytaradi (nolga bo\'lish himoyasi)', () {
      expect(SalaryCalculator.workDaysInMonth(2026, 9, <int>[]), 0);
    });
  });

  group('elapsedWorkDaysInMonth', () {
    test('2-sentabrgacha 2 ta ish kuni o\'tgan', () {
      expect(
        SalaryCalculator.elapsedWorkDaysInMonth(
          2026,
          9,
          monFri,
          DateTime(2026, 9, 2),
        ),
        2,
      );
    });

    test('o\'tgan oy uchun to\'liq oy hisoblanadi', () {
      expect(
        SalaryCalculator.elapsedWorkDaysInMonth(
          2026,
          2,
          monFri,
          DateTime(2026, 9, 2),
        ),
        20,
      );
    });

    test('kelajakdagi oy uchun 0', () {
      expect(
        SalaryCalculator.elapsedWorkDaysInMonth(
          2026,
          12,
          monFri,
          DateTime(2026, 9, 2),
        ),
        0,
      );
    });
  });

  group('stavkalar', () {
    test('kunlik stavka = maosh / ish kunlari', () {
      expect(
        SalaryCalculator.dailyRate(monthlySalary: 5000000, workDaysCount: 20),
        250000,
      );
    });

    test('ish kunlari 0 bo\'lsa 0 qaytaradi, crash bo\'lmaydi', () {
      expect(
        SalaryCalculator.dailyRate(monthlySalary: 5000000, workDaysCount: 0),
        0,
      );
    });

    test('09:00-18:00 smena 9 soat', () {
      expect(
        SalaryCalculator.shiftHours(
          workStartMinutes: TimeUtils.minutesFromHm('09:00'),
          workEndMinutes: TimeUtils.minutesFromHm('18:00'),
        ),
        9.0,
      );
    });

    test('tungi smena (22:00-06:00) 8 soat deb hisoblanadi', () {
      expect(
        SalaryCalculator.shiftHours(
          workStartMinutes: TimeUtils.minutesFromHm('22:00'),
          workEndMinutes: TimeUtils.minutesFromHm('06:00'),
        ),
        8.0,
      );
    });

    test('soatlik stavka = kunlik / smena soati', () {
      expect(
        SalaryCalculator.hourlyRate(
          dailyRate: 225000,
          workStartMinutes: TimeUtils.minutesFromHm('09:00'),
          workEndMinutes: TimeUtils.minutesFromHm('18:00'),
        ),
        25000,
      );
    });
  });

  group('kechikish va erta ketish', () {
    test('09:15 kelsa 15 daqiqa kechikish', () {
      expect(
        SalaryCalculator.lateMinutes(
          checkIn: DateTime(2026, 9, 2, 9, 15),
          workStartMinutes: 540,
        ),
        15,
      );
    });

    test('erta kelsa kechikish 0 (bonus yo\'q)', () {
      expect(
        SalaryCalculator.lateMinutes(
          checkIn: DateTime(2026, 9, 2, 8, 30),
          workStartMinutes: 540,
        ),
        0,
      );
    });

    test('17:30 ketsa 30 daqiqa erta ketish', () {
      expect(
        SalaryCalculator.earlyLeaveMinutes(
          checkOut: DateTime(2026, 9, 2, 17, 30),
          workEndMinutes: 1080,
        ),
        30,
      );
    });

    test('kech ketsa erta ketish 0', () {
      expect(
        SalaryCalculator.earlyLeaveMinutes(
          checkOut: DateTime(2026, 9, 2, 19, 0),
          workEndMinutes: 1080,
        ),
        0,
      );
    });
  });

  group('calculateDay', () {
    // 5 000 000 / 20 = 250 000 kunlik, 9 soatlik smena → 27 777.78 soatlik,
    // ya'ni 462.96 so'm/daqiqa.
    const double dailyRate = 250000;
    final int start = TimeUtils.minutesFromHm('09:00');
    final int end = TimeUtils.minutesFromHm('18:00');

    test('vaqtida kelib vaqtida ketsa jarima yo\'q', () {
      final DailyCalculation result = SalaryCalculator.calculateDay(
        checkIn: DateTime(2026, 9, 2, 9, 0),
        checkOut: DateTime(2026, 9, 2, 18, 0),
        workStartMinutes: start,
        workEndMinutes: end,
        dailyRate: dailyRate,
      );
      expect(result.lateMinutes, 0);
      expect(result.earlyLeaveMinutes, 0);
      expect(result.penaltyAmount, 0);
      expect(result.dailyEarning, dailyRate);
      expect(result.workedHours, 9.0);
    });

    test('30 daqiqa kechiksa jarima soatlik stavkaning yarmi', () {
      final DailyCalculation result = SalaryCalculator.calculateDay(
        checkIn: DateTime(2026, 9, 2, 9, 30),
        checkOut: DateTime(2026, 9, 2, 18, 0),
        workStartMinutes: start,
        workEndMinutes: end,
        dailyRate: dailyRate,
      );
      final double hourly = dailyRate / 9;
      expect(result.lateMinutes, 30);
      expect(result.penaltyAmount, closeTo(hourly / 2, 0.01));
      expect(result.dailyEarning, closeTo(dailyRate - hourly / 2, 0.01));
    });

    test('kechikish va erta ketish jarimasi qo\'shiladi', () {
      final DailyCalculation result = SalaryCalculator.calculateDay(
        checkIn: DateTime(2026, 9, 2, 9, 20),
        checkOut: DateTime(2026, 9, 2, 17, 20),
        workStartMinutes: start,
        workEndMinutes: end,
        dailyRate: dailyRate,
      );
      final double perMinute = dailyRate / 9 / 60;
      expect(result.lateMinutes, 20);
      expect(result.earlyLeaveMinutes, 40);
      expect(result.penaltyAmount, closeTo(60 * perMinute, 0.01));
    });

    test('jarima kunlik stavkadan oshsa ham dailyEarning manfiy bo\'lmaydi',
        () {
      final DailyCalculation result = SalaryCalculator.calculateDay(
        // 18:30da kelib 18:35da ketgan: 570 daqiqa kechikish, bu 9 soatlik
        // smenadagi 540 daqiqadan ko'p, ya'ni jarima kunlik stavkadan oshadi.
        checkIn: DateTime(2026, 9, 2, 18, 30),
        checkOut: DateTime(2026, 9, 2, 18, 35),
        workStartMinutes: start,
        workEndMinutes: end,
        dailyRate: dailyRate,
      );
      expect(result.penaltyAmount, greaterThan(dailyRate));
      expect(result.dailyEarning, 0);
    });

    test('checkOut yo\'q bo\'lsa erta ketish jarimasi hisoblanmaydi', () {
      final DailyCalculation result = SalaryCalculator.calculateDay(
        checkIn: DateTime(2026, 9, 2, 9, 10),
        checkOut: null,
        workStartMinutes: start,
        workEndMinutes: end,
        dailyRate: dailyRate,
      );
      expect(result.earlyLeaveMinutes, 0);
      expect(result.lateMinutes, 10);
      expect(result.dailyEarning, 0, reason: 'kun hali yopilmagan');
      expect(result.workedHours, 0);
    });
  });

  newRulesTests();
}

/// Fixed maosh, tushlik tanaffusi va jarima siyosati — yangi qoidalar.
void newRulesTests() {
  final int start = TimeUtils.minutesFromHm('09:00');
  final int end = TimeUtils.minutesFromHm('18:00');

  group('tushlik tanaffusi', () {
    test('09:00-18:00 + 60 daq tushlik = 8 soat smena', () {
      expect(
        SalaryCalculator.shiftHours(
          workStartMinutes: start,
          workEndMinutes: end,
          lunchBreakMinutes: 60,
        ),
        8.0,
      );
    });

    test('tanaffus soatlik stavkani oshiradi', () {
      final double withoutLunch = SalaryCalculator.hourlyRate(
        dailyRate: 240000,
        workStartMinutes: start,
        workEndMinutes: end,
      );
      final double withLunch = SalaryCalculator.hourlyRate(
        dailyRate: 240000,
        workStartMinutes: start,
        workEndMinutes: end,
        lunchBreakMinutes: 60,
      );
      // Bir xil kunlik summa kamroq soatga bo'linadi.
      expect(withLunch, greaterThan(withoutLunch));
      expect(withLunch, 30000);
    });

    test('tanaffus smenadan uzun bo\'lsa 0 qaytadi, crash bo\'lmaydi', () {
      expect(
        SalaryCalculator.shiftHours(
          workStartMinutes: start,
          workEndMinutes: end,
          lunchBreakMinutes: 10 * 60,
        ),
        0,
      );
    });

    test('ishlagan soatdan tanaffus ayiriladi', () {
      expect(
        SalaryCalculator.workedHours(
          checkIn: DateTime(2026, 9, 2, 9, 0),
          checkOut: DateTime(2026, 9, 2, 18, 0),
          lunchBreakMinutes: 60,
        ),
        8.0,
      );
    });

    test('qisqa muddat tanaffusdan kam bo\'lsa manfiyga tushmaydi', () {
      expect(
        SalaryCalculator.workedHours(
          checkIn: DateTime(2026, 9, 2, 9, 0),
          checkOut: DateTime(2026, 9, 2, 9, 30),
          lunchBreakMinutes: 60,
        ),
        0.5,
      );
    });
  });

  group('jarima siyosati', () {
    test('penaltyEnabled=false bo\'lsa jarima 0, lekin kechikish yoziladi', () {
      final DailyCalculation result = SalaryCalculator.calculateDay(
        checkIn: DateTime(2026, 9, 2, 10, 0),
        checkOut: DateTime(2026, 9, 2, 17, 0),
        workStartMinutes: start,
        workEndMinutes: end,
        dailyRate: 250000,
        penaltyEnabled: false,
      );
      expect(result.lateMinutes, 60, reason: 'statistika saqlanadi');
      expect(result.earlyLeaveMinutes, 60);
      expect(result.penaltyAmount, 0, reason: 'pul ushlanmaydi');
      expect(result.dailyEarning, 250000, reason: 'to\'liq kunlik stavka');
    });

    test('penaltyEnabled=true bo\'lsa jarima ayiriladi', () {
      final DailyCalculation result = SalaryCalculator.calculateDay(
        checkIn: DateTime(2026, 9, 2, 10, 0),
        checkOut: DateTime(2026, 9, 2, 18, 0),
        workStartMinutes: start,
        workEndMinutes: end,
        dailyRate: 250000,
      );
      expect(result.penaltyAmount, greaterThan(0));
      expect(result.dailyEarning, lessThan(250000));
    });
  });

  group('fixed maosh', () {
    test('kunlik maosh yozilmaydi — pul kunlarga bo\'linmaydi', () {
      final DailyCalculation result = SalaryCalculator.calculateDay(
        checkIn: DateTime(2026, 9, 2, 9, 0),
        checkOut: DateTime(2026, 9, 2, 18, 0),
        workStartMinutes: start,
        workEndMinutes: end,
        dailyRate: 250000,
        isFixedSalary: true,
      );
      expect(result.dailyEarning, 0);
      expect(result.workedHours, 9.0, reason: 'soat baribir yoziladi');
    });

    test('kelmagan kun uchun oylikdan ushlanmaydi', () {
      // 22 ta ish kunidan faqat 10 tasiga kelgan bo'lsa ham summa to'liq.
      expect(
        SalaryCalculator.monthlyEarning(
          isFixedSalary: true,
          monthlySalary: 5000000,
          sumOfDailyEarnings: 0,
          totalPenalty: 0,
        ),
        5000000,
      );
    });

    test('jarima yoqilgan bo\'lsa faqat u ayiriladi', () {
      expect(
        SalaryCalculator.monthlyEarning(
          isFixedSalary: true,
          monthlySalary: 5000000,
          sumOfDailyEarnings: 0,
          totalPenalty: 150000,
        ),
        4850000,
      );
    });

    test('jarima oylikdan oshsa ham manfiy bo\'lmaydi', () {
      expect(
        SalaryCalculator.monthlyEarning(
          isFixedSalary: true,
          monthlySalary: 5000000,
          sumOfDailyEarnings: 0,
          totalPenalty: 9000000,
        ),
        0,
      );
    });

    test('kunlik hisobda esa kunlik summalar yig\'indisi olinadi', () {
      expect(
        SalaryCalculator.monthlyEarning(
          isFixedSalary: false,
          monthlySalary: 5000000,
          sumOfDailyEarnings: 3250000,
          totalPenalty: 150000,
        ),
        3250000,
        reason: 'jarima allaqachon har kunning ichida ayirilgan',
      );
    });
  });
}
