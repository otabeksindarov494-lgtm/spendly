import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/attendance_model.dart';
import '../../models/user_profile_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/notification_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/salary_calculator.dart';
import '../../utils/time_utils.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/attendance_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/glass.dart';
import '../../widgets/common/progress_dialog.dart';
import '../../widgets/common/progress_ring.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/shimmer_box.dart';
import '../../widgets/common/stat_bar.dart';
import '../../widgets/common/stat_card.dart';
import '../notifications/notifications_screen.dart';

/// 1-tab: bugungi check-in / check-out va joriy holat (PROJECT.md 5.1).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isBusy = false;

  /// Ishga kelish yoki ketishni qayd etadi: selfie olinadi, so'ng yoziladi.
  Future<void> _record({
    required UserProfile profile,
    Attendance? today,
  }) async {
    setState(() => _isBusy = true);
    try {
      final String? userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final String? photo = await ref
          .read(imageServiceProvider)
          .captureSelfieBase64();
      // Foydalanuvchi kamerani bekor qildi — hech narsa yozmaymiz.
      if (photo == null) return;

      if (!mounted) return;
      final service = ref.read(attendanceServiceProvider);
      final bool isCheckIn = today == null || !today.hasCheckedIn;

      await runWithProgress<void>(
        context: context,
        title: isCheckIn ? 'check_in_recording'.tr() : 'check_out_recording'.tr(),
        task: (ProgressReporter report) async {
          report('calculating_time'.tr(), 0.4);
          if (isCheckIn) {
            await service.checkIn(
              userId: userId,
              profile: profile,
              photoBase64: photo,
            );
          } else {
            await service.checkOut(
              userId: userId,
              profile: profile,
              existing: today,
              photoBase64: photo,
            );
          }
          report('saving'.tr(), 0.85);
        },
      );

      if (!mounted) return;
      // Yig'ma raqamlar aggregate so'rov orqali olinadi — o'zi yangilanmaydi.
      ref.invalidate(attendanceTotalsProvider);
      AppToast.show(
        context,
        isCheckIn ? 'check_in_success'.tr() : 'check_out_success'.tr(),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'error_prefix'.tr(args: [e.toString()]), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final AsyncValue<UserProfile?> profileAsync = ref.watch(profileProvider);
    final AsyncValue<Attendance?> todayAsync = ref.watch(
      todayAttendanceProvider,
    );
    final AsyncValue<List<Attendance>> weekAsync = ref.watch(last7DaysProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: theme.blue,
          onRefresh: () async {
            ref.invalidate(todayAttendanceProvider);
            ref.invalidate(last7DaysProvider);
            ref.invalidate(currentMonthAttendanceProvider);
            ref.invalidate(attendanceTotalsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: <Widget>[
              _buildGreeting(theme, profileAsync.value),
              const SizedBox(height: 16),
              profileAsync.when(
                loading: () => const ShimmerBox(height: 190, borderRadius: 24),
                error: (Object e, StackTrace _) =>
                    ErrorView(message: 'profile_load_error'.tr(args: [e.toString()])),
                data: (UserProfile? profile) {
                  if (profile == null) {
                    return const ShimmerBox(height: 190, borderRadius: 24);
                  }
                  return todayAsync.when(
                    loading: () =>
                        const ShimmerBox(height: 190, borderRadius: 24),
                    error: (Object e, StackTrace _) =>
                        ErrorView(message: 'attendance_load_error'.tr(args: [e.toString()])),
                    data: (Attendance? today) =>
                        _buildTodayCard(theme, profile, today),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildStats(theme, profileAsync.value, todayAsync.value),
              const SizedBox(height: 24),
              SectionTitle(title: 'statistics'.tr()),
              _buildStatistics(theme, profileAsync.value),
              const SizedBox(height: 24),
              SectionTitle(title: 'last_7_days'.tr()),
              weekAsync.when(
                loading: () => const ShimmerList(itemCount: 3),
                error: (Object e, StackTrace _) =>
                    ErrorView(message: 'list_load_error'.tr(args: [e.toString()])),
                data: (List<Attendance> records) {
                  if (records.isEmpty) {
                    return EmptyState(
                      icon: IconsaxPlusLinear.calendar_remove,
                      title: 'no_records_yet'.tr(),
                      message: 'no_records_message'.tr(),
                    );
                  }
                  return Column(
                    children: <Widget>[
                      for (final Attendance record in records)
                        AttendanceTile(
                          attendance: record,
                          currency: profileAsync.value?.currency ?? 'currency_so_m'.tr(),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(CustomTheme theme, UserProfile? profile) {
    final String fullName = profile?.fullName.trim() ?? '';
    final String firstName = fullName.isEmpty
        ? ''
        : fullName.split(RegExp(r'\s+')).first;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('greeting'.tr(), style: context.text.bodySmall),
              const SizedBox(height: 2),
              Text(
                // Ism yonida qo'l silkitish stikeri (iOS'da rangli emoji).
                firstName.isEmpty ? 'app_title'.tr() : '$firstName 👋',
                style: context.text.headlineSmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _NotificationBell(
          unread: ref.watch(unreadNotificationsProvider),
          onTap: () => NotificationsScreen.open(context),
        ),
      ],
    );
  }

  Widget _buildTodayCard(
    CustomTheme theme,
    UserProfile profile,
    Attendance? today,
  ) {
    final bool isWorkDay = profile.workDays.contains(DateTime.now().weekday);

    return GlassPanel(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                IconsaxPlusLinear.calendar_1,
                size: 16,
                color: context.theme.textGray,
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.longDate(DateTime.now()),
                style: context.text.labelMedium?.copyWith(
                  color: context.theme.textGray,
                ),
              ),
              const Spacer(),
              if (!isWorkDay)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.glassFill,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: theme.borderGray, width: 0.6),
                  ),
                  child: Text('rest_day'.tr(), style: context.text.labelSmall),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (!isWorkDay && (today == null || !today.hasCheckedIn))
            _buildRestDayBody()
          else if (today == null || !today.hasCheckedIn)
            _buildNotCheckedInBody(profile, today)
          else if (!today.hasCheckedOut)
            _buildInProgressBody(profile, today)
          else
            _buildCompletedBody(today, profile),
        ],
      ),
    );
  }

  Widget _buildRestDayBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('rest_day_title'.tr(), style: context.text.titleLarge),
        const SizedBox(height: 6),
        Text(
          'rest_day_desc'.tr(),
          style: context.text.bodySmall,
        ),
      ],
    );
  }

  Widget _buildNotCheckedInBody(UserProfile profile, Attendance? today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'work_starts'.tr(args: [profile.workStartTime]),
          style: context.text.bodySmall,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'check_in_btn'.tr(),
          icon: IconsaxPlusBold.camera,
          isLoading: _isBusy,
          onPressed: () => _record(profile: profile, today: today),
        ),
      ],
    );
  }

  Widget _buildInProgressBody(UserProfile profile, Attendance today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _HeroStat(
              label: 'arrived_time'.tr(),
              value: Formatters.time(today.checkInTime!),
            ),
            if (today.isLate)
              _HeroStat(
                label: 'late_time'.tr(),
                value: Formatters.minutes(today.lateMinutes),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'check_out_btn'.tr(),
          icon: IconsaxPlusLinear.logout,
          variant: AppButtonVariant.secondary,
          isLoading: _isBusy,
          onPressed: () => _record(profile: profile, today: today),
        ),
      ],
    );
  }

  Widget _buildCompletedBody(Attendance today, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _HeroStat(
              label: 'arrived'.tr(),
              value: Formatters.time(today.checkInTime!),
            ),
            _HeroStat(
              label: 'left'.tr(),
              value: Formatters.time(today.checkOutTime!),
            ),
            _HeroStat(
              label: 'worked'.tr(),
              value: Formatters.hours(today.workedHours),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.theme.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                IconsaxPlusBold.tick_circle,
                size: 15,
                color: context.theme.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.salaryType == SalaryType.fixed
                      ? 'work_closed_hours'.tr(args: [Formatters.hours(today.workedHours)])
                      : 'work_closed_money'.tr(args: [Formatters.money(today.dailyEarning, currency: profile.currency)]),
                  style: context.text.labelMedium?.copyWith(
                    color: context.theme.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(CustomTheme theme, UserProfile? profile) {
    final MonthlySummary? summary = ref.watch(currentMonthSummaryProvider);
    final AsyncValue<AttendanceTotals> totalsAsync = ref.watch(
      attendanceTotalsProvider,
    );

    if (summary == null || profile == null) {
      return const ShimmerBox(height: 260, borderRadius: 22);
    }

    final AttendanceTotals totals = totalsAsync.value ?? AttendanceTotals.empty;

    final double shift = SalaryCalculator.shiftHours(
      workStartMinutes: TimeUtils.minutesFromHmOr(profile.workStartTime, 540),
      workEndMinutes: TimeUtils.minutesFromHmOr(profile.workEndTime, 1080),
      lunchBreakMinutes: profile.lunchBreakMinutes,
    );
    final double expectedHours = summary.plannedWorkDays * shift;
    final double attendanceRate = summary.elapsedWorkDays == 0
        ? 0
        : summary.presentDays / summary.elapsedWorkDays;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ProgressRing(
                value: summary.progress,
                centerLabel: '${(summary.progress * 100).round()}%',
                centerCaption:
                    'work_days_count'.tr(args: [summary.elapsedWorkDays.toString(), summary.plannedWorkDays.toString()]),
                size: 124,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('total_worked'.tr(), style: context.text.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      totalsAsync.isLoading && totalsAsync.value == null
                          ? '...'
                          : 'hours_suffix'.tr(args: [totals.workedHours.round().toString()]),
                      style: context.text.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'days_count'.tr(args: [totals.recordedDays.toString()]),
                      style: context.text.labelSmall,
                    ),
                    const SizedBox(height: 14),
                    Text('this_month'.tr(), style: context.text.labelSmall),
                    const SizedBox(height: 3),
                    Text(
                      Formatters.hours(summary.workedHours),
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          StatBar(
            label: 'worked_hours_stat'.tr(),
            value:
                '${summary.workedHours.round()} / '
                '${expectedHours.round()} ' + 'hours_suffix'.tr(args: ['']).trim(),
            progress: expectedHours == 0
                ? 0
                : summary.workedHours / expectedHours,
            color: theme.blue,
          ),
          StatBar(
            label: 'attendance_stat'.tr(),
            value: 'work_days_count'.tr(args: [summary.presentDays.toString(), summary.elapsedWorkDays.toString()]),
            progress: attendanceRate,
            color: theme.green,
          ),
          StatBar(
            label: 'lateness_stat'.tr(),
            value: Formatters.minutes(summary.lateMinutes),
            progress: summary.lateMinutes / 600,
            color: theme.yellow,
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
    CustomTheme theme,
    UserProfile? profile,
    Attendance? today,
  ) {
    final MonthlySummary? summary = ref.watch(currentMonthSummaryProvider);
    final String currency = profile?.currency ?? 'currency_so_m'.tr();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: <Widget>[
        StatCard(
          icon: IconsaxPlusLinear.timer_1,
          label: 'working_hours'.tr(),
          value: today == null || !today.hasCheckedOut
              ? '—'
              : Formatters.hours(today.workedHours),
          accentColor: theme.blue,
        ),
        StatCard(
          icon: IconsaxPlusLinear.calendar_tick,
          label: 'present_days_label'.tr(),
          value: summary == null ? '—' : 'days_suffix'.tr(args: [summary.presentDays.toString()]),
          accentColor: theme.green,
        ),
        StatCard(
          icon: IconsaxPlusLinear.alarm,
          label: 'total_lateness'.tr(),
          value: summary == null
              ? '—'
              : Formatters.minutes(summary.lateMinutes),
          accentColor: theme.yellow,
        ),
        StatCard(
          icon: IconsaxPlusLinear.moneys,
          label: 'monthly_salary'.tr(),
          value: summary == null
              ? '—'
              : Formatters.money(summary.earnedAmount, currency: currency),
          accentColor: theme.blue,
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: context.text.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Semantics(
      button: true,
      label: unread == 0
          ? 'notifications_title'.tr()
          : '${'notifications_title'.tr()}, $unread',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              GlassSurface(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                blur: 16,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    IconsaxPlusLinear.notification,
                    size: 22,
                    color: theme.mainDarkBlue,
                  ),
                ),
              ),
              if (unread > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.blue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CustomTheme.onAccent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CustomTheme.onAccent,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
