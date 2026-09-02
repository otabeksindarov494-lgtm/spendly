import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/time_utils.dart';
import 'app_card.dart';
import 'photo_preview_sheet.dart';

/// Bir kunlik davomat qatori.
///
/// Ishlatilishi: Home ("Oxirgi 7 kun") va Hisobot (oylik kunlik yozuvlar).
/// [showEarning] `true` bo'lsa shu kunlik ishlab topilgan summa ham
/// ko'rsatiladi — Hisobot ekrani uchun.
class AttendanceTile extends StatelessWidget {
  const AttendanceTile({
    super.key,
    required this.attendance,
    required this.currency,
    this.showEarning = false,
  });

  final Attendance attendance;
  final String currency;
  final bool showEarning;

  /// Status rangi: yashil = vaqtida, sariq = kechikkan, qizil = kelmagan.
  static Color statusColor(BuildContext context, Attendance attendance) {
    final CustomTheme theme = context.theme;
    if (!attendance.hasCheckedIn) return theme.red;
    if (attendance.isLate || attendance.earlyLeaveMinutes > 0) {
      return theme.yellow;
    }
    return theme.green;
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final DateTime? date = TimeUtils.dateFromKey(attendance.date);
    final Color accent = statusColor(context, attendance);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => PhotoPreviewSheet.show(context, attendance),
        child: Row(
          children: <Widget>[
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    date == null
                        ? attendance.date
                        : Formatters.shortDayLabel(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.mainDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _timeRange(),
                    style: TextStyle(fontSize: 11, color: theme.textGray),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  attendance.hasCheckedOut
                      ? Formatters.hours(attendance.workedHours)
                      : (attendance.hasCheckedIn ? 'Ishda' : '—'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.mainDarkBlue,
                  ),
                ),
                const SizedBox(height: 3),
                if (showEarning && attendance.hasCheckedOut)
                  Text(
                    Formatters.money(
                      attendance.dailyEarning,
                      currency: currency,
                    ),
                    style: TextStyle(fontSize: 11, color: theme.green),
                  )
                else if (attendance.isLate)
                  Text(
                    '+${Formatters.minutes(attendance.lateMinutes)} kech',
                    style: TextStyle(fontSize: 11, color: theme.yellow),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeRange() {
    final String checkIn = attendance.checkInTime == null
        ? '—'
        : Formatters.time(attendance.checkInTime!);
    final String checkOut = attendance.checkOutTime == null
        ? '—'
        : Formatters.time(attendance.checkOutTime!);
    return '$checkIn  →  $checkOut';
  }
}
