import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendly/models/attendance_model.dart';
import 'package:spendly/screens/report/report_day_tile.dart';
import 'package:spendly/theme/app_theme.dart';
import 'package:spendly/utils/month_days.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpTile(WidgetTester tester, ReportDay day) async {
    // iPhone 16e kengligi.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ReportDayTile(
              day: day,
              currency: 'so\'m',
              showEarning: true,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('kelgan kun: barcha raqamlar va selfilar, toshib ketmaydi', (
    WidgetTester tester,
  ) async {
    await pumpTile(
      tester,
      ReportDay(
        date: DateTime(2026, 10, 5),
        kind: ReportDayKind.recorded,
        record: Attendance(
          id: '2026-10-05',
          date: '2026-10-05',
          checkInTime: DateTime(2026, 10, 5, 9, 12),
          checkOutTime: DateTime(2026, 10, 5, 17, 50),
          workedHours: 7.6,
          lateMinutes: 12,
          earlyLeaveMinutes: 10,
          penaltyAmount: 25000,
          dailyEarning: 202270,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final String label in <String>[
      'Keldi',
      'Ketdi',
      'Ishladi',
      'Kechikish',
      'Erta ketish',
      'Jarima',
      'Kunlik maosh',
      'Kelgan',
      'Ketgan',
      'Kechikdi',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('09:12'), findsOneWidget);
    expect(find.text('17:50'), findsOneWidget);
  });

  testWidgets('kelmagan va dam olish kunlari', (WidgetTester tester) async {
    await pumpTile(
      tester,
      ReportDay(date: DateTime(2026, 10, 2), kind: ReportDayKind.absent),
    );
    expect(find.text('Kelmadi'), findsOneWidget);

    await pumpTile(
      tester,
      ReportDay(date: DateTime(2026, 10, 3), kind: ReportDayKind.dayOff),
    );
    expect(find.text('Dam olish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
