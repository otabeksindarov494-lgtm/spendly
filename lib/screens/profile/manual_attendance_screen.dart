import 'package:bootstrap_icons/bootstrap_icons.dart';
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
import '../../widgets/common/progress_dialog.dart';

/// Davomat yozuvini qo'lda kiritish yoki tuzatish (Profil bo'limidan).
///
/// Nima uchun kerak: ilova yangi o'rnatilganda o'tgan kunlar yozilmagan
/// bo'ladi; check-in bosish esdan chiqishi mumkin; vaqt xato qayd etilishi
/// mumkin. Bu ekran o'sha kunlarni to'g'rilash imkonini beradi.
class ManualAttendanceScreen extends ConsumerStatefulWidget {
  const ManualAttendanceScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ManualAttendanceScreen(),
      ),
    );
  }

  @override
  ConsumerState<ManualAttendanceScreen> createState() =>
      _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState
    extends ConsumerState<ManualAttendanceScreen> {
  DateTime _date = DateTime.now();
  int _checkInMinutes = 9 * 60;
  int? _checkOutMinutes = 18 * 60;

  /// `true` bo'lsa chiqish vaqti yozilmaydi — kun "ishda" holatida qoladi.
  bool _stillAtWork = false;

  bool _isLoadingDay = true;
  bool _recordExists = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDay());
  }

  /// Tanlangan kunda yozuv bo'lsa, formani o'sha qiymatlar bilan to'ldiradi.
  Future<void> _loadDay() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isLoadingDay = true);
    final Attendance? existing =
        await ref.read(attendanceServiceProvider).fetchDay(userId, _date);
    if (!mounted) return;

    setState(() {
      _recordExists = existing != null;
      if (existing?.checkInTime != null) {
        _checkInMinutes = TimeUtils.minutesOfDay(existing!.checkInTime!);
      }
      if (existing?.checkOutTime != null) {
        _checkOutMinutes = TimeUtils.minutesOfDay(existing!.checkOutTime!);
        _stillAtWork = false;
      } else if (existing != null) {
        _stillAtWork = true;
        _checkOutMinutes = null;
      }
      _isLoadingDay = false;
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      // Kelajakdagi kunga davomat yozib bo'lmaydi.
      lastDate: now,
      helpText: 'Qaysi kun uchun',
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _loadDay();
  }

  Future<void> _pickTime({required bool isCheckIn}) async {
    final int current = isCheckIn
        ? _checkInMinutes
        : (_checkOutMinutes ?? 18 * 60);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: isCheckIn ? 'Kelgan vaqt' : 'Ketgan vaqt',
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      final int minutes = picked.hour * 60 + picked.minute;
      if (isCheckIn) {
        _checkInMinutes = minutes;
      } else {
        _checkOutMinutes = minutes;
      }
    });
  }

  Future<void> _save(UserProfile profile) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await runWithProgress<void>(
      context: context,
      title: 'Davomat saqlanmoqda',
      task: (ProgressReporter report) async {
        report('Hisob-kitob qilinmoqda...', 0.35);
        await ref.read(attendanceServiceProvider).saveManualEntry(
              userId: userId,
              profile: profile,
              date: _date,
              checkInMinutes: _checkInMinutes,
              checkOutMinutes: _stillAtWork ? null : _checkOutMinutes,
            );
        report('Firestore\'ga yozilmoqda...', 0.8);
      },
    );

    if (!mounted) return;
    ref.invalidate(todayAttendanceProvider);
    ref.invalidate(last7DaysProvider);
    ref.invalidate(currentMonthAttendanceProvider);
    ref.invalidate(monthAttendanceProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${Formatters.longDate(_date)} uchun saqlandi'),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final CustomTheme theme = context.theme;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Yozuvni o\'chirish'),
        content: Text(
          '${Formatters.longDate(_date)} uchun davomat yozuvi o\'chiriladi.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('O\'chirish', style: TextStyle(color: theme.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await runWithProgress<void>(
      context: context,
      title: 'O\'chirilmoqda',
      task: (ProgressReporter report) async {
        report('Yozuv o\'chirilmoqda...', 0.5);
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
      appBar: AppBar(title: const Text('Davomatni qo\'lda kiritish')),
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
                    icon: BootstrapIcons.calendar_event,
                    label: 'Sana',
                    value: Formatters.longDate(_date),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    theme: theme,
                    icon: BootstrapIcons.box_arrow_in_right,
                    label: 'Kelgan vaqt',
                    value: TimeUtils.hmFromMinutes(_checkInMinutes),
                    onTap: () => _pickTime(isCheckIn: true),
                  ),
                  const SizedBox(height: 10),
                  _buildRow(
                    theme: theme,
                    icon: BootstrapIcons.box_arrow_right,
                    label: 'Ketgan vaqt',
                    value: _stillAtWork
                        ? 'Hali ishda'
                        : TimeUtils.hmFromMinutes(_checkOutMinutes ?? 18 * 60),
                    onTap: _stillAtWork ? null : () => _pickTime(isCheckIn: false),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _stillAtWork,
                      activeThumbColor: theme.blue,
                      title: Text(
                        'Hali ishdaman',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.mainDarkBlue,
                        ),
                      ),
                      subtitle: Text(
                        'Ketgan vaqt yozilmaydi, kun ochiq qoladi',
                        style: TextStyle(fontSize: 11, color: theme.textGray),
                      ),
                      onChanged: (bool value) =>
                          setState(() => _stillAtWork = value),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildPreview(theme, profile),
                  const SizedBox(height: 22),
                  AppButton(
                    label: _recordExists ? 'Yangilash' : 'Saqlash',
                    icon: BootstrapIcons.check_circle_fill,
                    isLoading: _isLoadingDay,
                    onPressed: () => _save(profile),
                  ),
                  if (_recordExists) ...<Widget>[
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Bu kunning yozuvini o\'chirish',
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(BootstrapIcons.info_circle, size: 15, color: theme.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Check-in bosilmagan yoki vaqt noto\'g\'ri yozilgan kunlarni '
              'shu yerdan to\'g\'rilashingiz mumkin. Jarima va kunlik maosh '
              'avtomatik qayta hisoblanadi.',
              style: TextStyle(fontSize: 12, height: 1.45, color: theme.textGray),
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
              BootstrapIcons.chevron_right,
              size: 13,
              color: theme.favoriteGray,
            ),
          ],
        ],
      ),
    );
  }

  /// Saqlashdan oldin natijani ko'rsatadi — "nima yoziladi" aniq bo'lsin.
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
            'Natija',
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
              'Bu kun dam olish kuni',
              'hisobga olinmaydi',
              theme.yellow,
            )
          else ...<Widget>[
            _previewRow(
              theme,
              'Kechikish',
              Formatters.minutes(calc.lateMinutes),
              calc.lateMinutes > 0 ? theme.yellow : theme.green,
            ),
            _previewRow(
              theme,
              'Erta ketish',
              Formatters.minutes(calc.earlyLeaveMinutes),
              calc.earlyLeaveMinutes > 0 ? theme.yellow : theme.green,
            ),
            _previewRow(
              theme,
              'Ishlagan vaqt',
              checkOut == null ? '—' : Formatters.hours(calc.workedHours),
              theme.mainDarkBlue,
            ),
            _previewRow(
              theme,
              'Jarima',
              '-${Formatters.money(calc.penaltyAmount, currency: profile.currency)}',
              calc.penaltyAmount > 0 ? theme.red : theme.textGray,
            ),
            _previewRow(
              theme,
              'Kunlik maosh',
              checkOut == null
                  ? 'kun yopilmagan'
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
              style: TextStyle(fontSize: 12, color: theme.textGray),
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
