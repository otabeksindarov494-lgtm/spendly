import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/attendance_model.dart';
import '../../models/user_profile_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_provider.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/salary_calculator.dart';
import '../../utils/time_utils.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/cupertino_pickers.dart';
import '../../widgets/common/progress_dialog.dart';

/// "Davomatni qo'lda kiritish" — o'tkazib yuborilgan yoki noto'g'ri
/// yozilgan vaqtlarni to'g'rilash (PROJECT.md 6-bo'lim).
class ManualAttendanceScreen extends ConsumerStatefulWidget {
  const ManualAttendanceScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  static Future<void> open(BuildContext context, {DateTime? initialDate}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            ManualAttendanceScreen(initialDate: initialDate),
      ),
    );
  }

  @override
  ConsumerState<ManualAttendanceScreen> createState() =>
      _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState
    extends ConsumerState<ManualAttendanceScreen> {
  late DateTime _date;
  int _checkInMinutes = 9 * 60;
  int? _checkOutMinutes = 18 * 60;
  bool _stillAtWork = false;
  bool _isLoadingDay = false;
  bool _recordExists = false;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _date = widget.initialDate ?? DateTime(now.year, now.month, now.day);
    _loadDayData();
  }

  /// Tanlangan sana uchun mavjud yozuvni Firestore'dan o'qiydi.
  Future<void> _loadDayData() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isLoadingDay = true);
    try {
      final Attendance? record = await ref
          .read(attendanceServiceProvider)
          .fetchDay(userId, _date);

      if (!mounted) return;
      if (record == null) {
        setState(() {
          _recordExists = false;
          _checkInMinutes = 9 * 60;
          _checkOutMinutes = 18 * 60;
          _stillAtWork = false;
        });
      } else {
        setState(() {
          _recordExists = true;
          if (record.checkInTime != null) {
            _checkInMinutes = TimeUtils.minutesOfDay(record.checkInTime!);
          } else {
            _checkInMinutes = 9 * 60;
          }
          if (record.checkOutTime == null) {
            _stillAtWork = true;
            _checkOutMinutes = 18 * 60;
          } else {
            _stillAtWork = false;
            _checkOutMinutes = TimeUtils.minutesOfDay(record.checkOutTime!);
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingDay = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await SoftPickers.pickDate(
      context: context,
      title: 'date'.tr(),
      initial: _date,
      first: DateTime(now.year - 5),
      last: now,
    );
    if (picked != null && mounted) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
      _loadDayData();
    }
  }

  Future<void> _pickTime({required bool isCheckIn}) async {
    final int initial = isCheckIn
        ? _checkInMinutes
        : (_checkOutMinutes ?? 18 * 60);
    final int? picked = await SoftPickers.pickTimeMinutes(
      context: context,
      title: isCheckIn ? 'arrived_time'.tr() : 'left'.tr(),
      initialMinutes: initial,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isCheckIn) {
          _checkInMinutes = picked;
        } else {
          _checkOutMinutes = picked;
        }
      });
    }
  }

  Future<void> _save(UserProfile profile) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await runWithProgress<void>(
      context: context,
      title: 'saving'.tr(),
      task: (ProgressReporter report) async {
        report('saving'.tr(), 0.5);
        await ref.read(attendanceServiceProvider).saveManualEntry(
              userId: userId,
              profile: profile,
              date: _date,
              checkInMinutes: _checkInMinutes,
              checkOutMinutes: _stillAtWork ? null : _checkOutMinutes,
            );
      },
    );

    if (!mounted) return;
    ref.invalidate(todayAttendanceProvider);
    ref.invalidate(last7DaysProvider);
    ref.invalidate(currentMonthAttendanceProvider);

    AppToast.show(context, 'saved_for'.tr(args: [Formatters.longDate(_date)]));
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final CustomTheme theme = context.theme;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('delete_record_title'.tr()),
        content: Text(
          'delete_record_confirm'.tr(args: [Formatters.longDate(_date)]),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr(), style: TextStyle(color: theme.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await runWithProgress<void>(
      context: context,
      title: 'deleting'.tr(),
      task: (ProgressReporter report) async {
        report('deleting_record'.tr(), 0.5);
        await ref
            .read(attendanceServiceProvider)
            .deleteDay(userId: userId, date: _date);
      },
    );

    if (!mounted) return;
    ref.invalidate(todayAttendanceProvider);
    ref.invalidate(last7DaysProvider);
    ref.invalidate(currentMonthAttendanceProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final UserProfile? profile = ref.watch(profileProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text('manual_attendance_title'.tr())),
      body: SafeArea(
        child: profile == null
            ? Center(child: CircularProgressIndicator(color: theme.blue))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: <Widget>[
                  _buildHint(theme),
                  const SizedBox(height: 18),
                  _buildRow(
                    theme: theme,
                    icon: IconsaxPlusLinear.calendar_1,
                    label: 'date'.tr(),
                    value: Formatters.longDate(_date),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    theme: theme,
                    icon: IconsaxPlusLinear.login,
                    label: 'arrived_time'.tr(),
                    value: TimeUtils.hmFromMinutes(_checkInMinutes),
                    onTap: () => _pickTime(isCheckIn: true),
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    theme: theme,
                    icon: IconsaxPlusLinear.logout,
                    label: 'left'.tr(),
                    value: _stillAtWork
                        ? 'still_at_work'.tr()
                        : TimeUtils.hmFromMinutes(_checkOutMinutes ?? 18 * 60),
                    onTap: _stillAtWork
                        ? null
                        : () => _pickTime(isCheckIn: false),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'still_at_work_title'.tr(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.mainDarkBlue,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'still_at_work_desc'.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        CupertinoSwitch(
                          value: _stillAtWork,
                          activeTrackColor: theme.blue,
                          onChanged: (bool value) =>
                              setState(() => _stillAtWork = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildPreview(theme, profile),
                  const SizedBox(height: 22),
                  AppButton(
                    label: _recordExists ? 'update'.tr() : 'save'.tr(),
                    icon: IconsaxPlusBold.tick_circle,
                    isLoading: _isLoadingDay,
                    onPressed: () => _save(profile),
                  ),
                  if (_recordExists) ...<Widget>[
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'delete_record_btn'.tr(),
                      variant: AppButtonVariant.text,
                      height: 46,
                      onPressed: _delete,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildHint(CustomTheme theme) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(IconsaxPlusLinear.info_circle, size: 15, color: theme.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'manual_attendance_hint'.tr(),
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: theme.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required CustomTheme theme,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: theme.textGray),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: theme.textGray),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: onTap == null ? theme.favoriteGray : theme.mainDarkBlue,
            ),
          ),
          if (onTap != null) ...<Widget>[
            const SizedBox(width: 6),
            Icon(
              IconsaxPlusLinear.arrow_right_3,
              size: 13,
              color: theme.favoriteGray,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview(CustomTheme theme, UserProfile profile) {
    final DateTime checkIn = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _checkInMinutes ~/ 60,
      _checkInMinutes % 60,
    );
    DateTime? checkOut;
    if (!_stillAtWork && _checkOutMinutes != null) {
      checkOut = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _checkOutMinutes! ~/ 60,
        _checkOutMinutes! % 60,
      );
      if (!checkOut.isAfter(checkIn)) {
        checkOut = checkOut.add(const Duration(days: 1));
      }
    }

    final DailyCalculation calc = AttendanceService.calculateFor(
      profile: profile,
      checkIn: checkIn,
      checkOut: checkOut,
    );
    final bool isWorkDay = profile.workDays.contains(_date.weekday);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'result'.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.mainDarkBlue,
            ),
          ),
          const SizedBox(height: 12),
          if (!isWorkDay)
            _previewRow(
              theme,
              'day_off_note'.tr(),
              'not_calculated'.tr(),
              theme.yellow,
            )
          else ...<Widget>[
            _previewRow(
              theme,
              'late_time'.tr(),
              Formatters.minutes(calc.lateMinutes),
              calc.lateMinutes > 0 ? theme.yellow : theme.green,
            ),
            _previewRow(
              theme,
              'early_leave'.tr(),
              Formatters.minutes(calc.earlyLeaveMinutes),
              calc.earlyLeaveMinutes > 0 ? theme.yellow : theme.green,
            ),
            _previewRow(
              theme,
              'worked_time'.tr(),
              checkOut == null ? '—' : Formatters.hours(calc.workedHours),
              theme.mainDarkBlue,
            ),
            _previewRow(
              theme,
              'penalty'.tr(),
              '-${Formatters.money(calc.penaltyAmount, currency: profile.currency)}',
              calc.penaltyAmount > 0 ? theme.red : theme.textGray,
            ),
            _previewRow(
              theme,
              'daily_earning'.tr(),
              checkOut == null
                  ? 'day_not_closed'.tr()
                  : Formatters.money(
                      calc.dailyEarning,
                      currency: profile.currency,
                    ),
              theme.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _previewRow(
    CustomTheme theme,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: theme.textGray),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
