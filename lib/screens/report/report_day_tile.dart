import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../models/attendance_model.dart';
import '../../services/image_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/month_days.dart';
import '../../widgets/common/app_card.dart';

/// Hisobotdagi bir kun: kelgan/ketgan vaqt, ishlagan vaqt, kechikish,
/// erta ketish, jarima, kunlik pul va ikkala selfi (bosilsa dialogda).
///
/// Faqat Hisobot uchun — Bosh sahifadagi "Oxirgi 7 kun" umumiy
/// `AttendanceTile`dan foydalanadi va o'zgarmagan.
class ReportDayTile extends StatelessWidget {
  const ReportDayTile({
    super.key,
    required this.day,
    required this.currency,
    required this.showEarning,
  });

  final ReportDay day;
  final String currency;

  /// Fixed maoshda kunlik summa yo'q — ko'rsatilmaydi.
  final bool showEarning;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Attendance? record = day.record;
    final (String status, Color color) = _status(theme, day);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    Formatters.shortDayLabel(day.date),
                    style: context.text.titleSmall,
                  ),
                ),
                _StatusChip(label: status, color: color),
              ],
            ),
            if (day.kind == ReportDayKind.recorded &&
                record != null) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _Facts(
                      record: record,
                      currency: currency,
                      showEarning: showEarning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SelfieThumb(
                    label: 'arrived'.tr(),
                    time: record.checkInTime,
                    base64: record.checkInPhotoBase64,
                  ),
                  const SizedBox(width: 8),
                  _SelfieThumb(
                    label: 'left'.tr(),
                    time: record.checkOutTime,
                    base64: record.checkOutPhotoBase64,
                  ),
                ],
              ),
            ] else ...<Widget>[
              const SizedBox(height: 4),
              Text(_emptyNote(day.kind), style: context.text.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  static (String, Color) _status(CustomTheme theme, ReportDay day) {
    final Attendance? r = day.record;
    return switch (day.kind) {
      ReportDayKind.dayOff => ('status_day_off'.tr(), theme.textGray),
      ReportDayKind.absent => ('status_absent'.tr(), theme.red),
      ReportDayKind.today => ('status_today'.tr(), theme.textGray),
      ReportDayKind.recorded when r != null && !r.hasCheckedOut => (
        'status_at_work'.tr(),
        theme.blue,
      ),
      ReportDayKind.recorded
          when r != null && (r.isLate || r.earlyLeaveMinutes > 0) =>
        ('status_late'.tr(), theme.yellow),
      ReportDayKind.recorded => ('status_on_time'.tr(), theme.green),
    };
  }

  static String _emptyNote(ReportDayKind kind) => switch (kind) {
    ReportDayKind.dayOff => 'note_day_off'.tr(),
    ReportDayKind.absent => 'note_absent'.tr(),
    ReportDayKind.today => 'note_today'.tr(),
    ReportDayKind.recorded => '',
  };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Kunning barcha raqamlari — faqat mavjudlari (0 bo'lsa yashiriladi).
class _Facts extends StatelessWidget {
  const _Facts({
    required this.record,
    required this.currency,
    required this.showEarning,
  });

  final Attendance record;
  final String currency;
  final bool showEarning;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final List<(String, String, Color?)> rows = <(String, String, Color?)>[
      (
        'arrived'.tr(),
        record.checkInTime == null ? '—' : Formatters.time(record.checkInTime!),
        null,
      ),
      (
        'left'.tr(),
        record.checkOutTime == null
            ? '—'
            : Formatters.time(record.checkOutTime!),
        null,
      ),
      if (record.hasCheckedOut)
        ('worked'.tr(), Formatters.hours(record.workedHours), null),
      if (record.lateMinutes > 0)
        ('lateness_stat'.tr(), Formatters.minutes(record.lateMinutes), theme.yellow),
      if (record.earlyLeaveMinutes > 0)
        (
          'early_leave'.tr(),
          Formatters.minutes(record.earlyLeaveMinutes),
          theme.yellow,
        ),
      if (record.penaltyAmount > 0)
        (
          'penalty'.tr(),
          '−${Formatters.money(record.penaltyAmount, currency: currency)}',
          theme.red,
        ),
      if (showEarning && record.hasCheckedOut)
        (
          'daily_earning'.tr(),
          Formatters.money(record.dailyEarning, currency: currency),
          theme.green,
        ),
    ];

    return Column(
      children: <Widget>[
        for (final (String label, String value, Color? color) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(label, style: context.text.bodySmall)),
                Text(
                  value,
                  style: context.text.labelMedium?.copyWith(
                    color: color ?? theme.mainDarkBlue,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Kichik selfi. Base64 bir marta dekodlanadi va kichraytirib chiziladi
/// (oyda ~60 ta rasm xotirani to'ldirmasin). Bosilsa — dialog.
class _SelfieThumb extends StatefulWidget {
  const _SelfieThumb({
    required this.label,
    required this.time,
    required this.base64,
  });

  final String label;
  final DateTime? time;
  final String? base64;

  @override
  State<_SelfieThumb> createState() => _SelfieThumbState();
}

class _SelfieThumbState extends State<_SelfieThumb> {
  static const double _size = 56;
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = ImageService.decode(widget.base64);
  }

  @override
  void didUpdateWidget(_SelfieThumb old) {
    super.didUpdateWidget(old);
    if (old.base64 != widget.base64) {
      _bytes = ImageService.decode(widget.base64);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Uint8List? bytes = _bytes;
    final int cacheSize = (_size * MediaQuery.devicePixelRatioOf(context))
        .round();

    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: bytes == null
              ? null
              : () => showSelfieDialog(
                  context,
                  bytes: bytes,
                  label: widget.label,
                  time: widget.time,
                ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: _size,
              height: _size,
              child: bytes == null
                  ? ColoredBox(
                      color: theme.glassFill,
                      child: Icon(
                        IconsaxPlusLinear.image,
                        size: 20,
                        color: theme.textGray,
                      ),
                    )
                  : Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      cacheWidth: cacheSize,
                      gaplessPlayback: true,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(widget.label, style: context.text.labelSmall),
      ],
    );
  }
}

/// Selfini dialogda katta ko'rsatadi: kattalashtirish mumkin, tashqariga
/// bosilsa yoki "×" bosilsa yopiladi.
Future<void> showSelfieDialog(
  BuildContext context, {
  required Uint8List bytes,
  required String label,
  required DateTime? time,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      final CustomTheme theme = context.theme;
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      time == null
                          ? label
                          : '$label · ${Formatters.time(time)}',
                      style: context.text.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      IconsaxPlusLinear.close_circle,
                      color: theme.textGray,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      );
    },
  );
}
