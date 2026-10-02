import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/attendance_model.dart';
import '../../models/user_profile_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/salary_calculator.dart';
import '../../utils/time_utils.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/attendance_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/glass.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/shimmer_box.dart';
import '../../services/attendance_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/progress_dialog.dart';
import '../../widgets/common/progress_ring.dart';
import '../../widgets/common/stat_bar.dart';
import '../../widgets/common/stat_card.dart';

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
        title: isCheckIn ? 'Kelish qayd etilmoqda' : 'Ketish qayd etilmoqda',
        task: (ProgressReporter report) async {
          report('Vaqt hisoblanmoqda...', 0.4);
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
          report('Saqlanmoqda...', 0.85);
        },
      );

      if (!mounted) return;
      // Yig'ma raqamlar aggregate so'rov orqali olinadi — o'zi yangilanmaydi.
      ref.invalidate(attendanceTotalsProvider);
      AppToast.show(
        context,
        isCheckIn ? 'Kelganingiz qayd etildi' : 'Ketganingiz qayd etildi',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, 'Xatolik: $e', isError: true);
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
                    ErrorView(message: 'Profil yuklanmadi: $e'),
                data: (UserProfile? profile) {
                  if (profile == null) {
                    return const ShimmerBox(height: 190, borderRadius: 24);
                  }
                  return todayAsync.when(
                    loading: () =>
                        const ShimmerBox(height: 190, borderRadius: 24),
                    error: (Object e, StackTrace _) =>
                        ErrorView(message: 'Davomat yuklanmadi: $e'),
                    data: (Attendance? today) =>
                        _buildTodayCard(theme, profile, today),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildStats(theme, profileAsync.value, todayAsync.value),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Statistika'),
              _buildStatistics(theme, profileAsync.value),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Oxirgi 7 kun'),
              weekAsync.when(
                loading: () => const ShimmerList(itemCount: 3),
                error: (Object e, StackTrace _) =>
                    ErrorView(message: 'Ro\'yxat yuklanmadi: $e'),
                data: (List<Attendance> records) {
                  if (records.isEmpty) {
                    return const EmptyState(
                      icon: IconsaxPlusLinear.calendar_remove,
                      title: 'Hali yozuv yo\'q',
                      message:
                          'Birinchi marta "Ishga keldim" tugmasini bosganingizda '
                          'shu yerda ko\'rinadi.',
                    );
                  }
                  return Column(
                    children: <Widget>[
                      for (final Attendance record in records)
                        AttendanceTile(
                          attendance: record,
                          currency: profileAsync.value?.currency ?? 'so\'m',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Assalomu alaykum', style: context.text.bodySmall),
        const SizedBox(height: 2),
        Text(
          // Ism yonida qo'l silkitish stikeri (iOS'da rangli emoji).
          firstName.isEmpty ? 'Spendly' : '$firstName 👋',
          style: context.text.headlineSmall,
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

    // Sahifaning asosiy elementi — haqiqiy blur'li shisha panel.
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
                  child: Text('Dam olish kuni', style: context.text.labelSmall),
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
        Text('Bugun dam olish kuni', style: context.text.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Bu kun uchun hisob-kitob va jarima yuritilmaydi.',
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
          'Ish boshlanishi: ${profile.workStartTime}',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Ishga keldim',
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
              label: 'Kelgan vaqt',
              value: Formatters.time(today.checkInTime!),
            ),
            if (today.isLate)
              _HeroStat(
                label: 'Kechikish',
                value: Formatters.minutes(today.lateMinutes),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Ishdan ketyapman',
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
              label: 'Kelgan',
              value: Formatters.time(today.checkInTime!),
            ),
            _HeroStat(
              label: 'Ketgan',
              value: Formatters.time(today.checkOutTime!),
            ),
            _HeroStat(
              label: 'Ishladi',
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
                  // Fixed maoshda kunlik summa yozilmaydi — o'rniga
                  // ishlangan vaqt ko'rsatiladi, aks holda "0 so'm"
                  // chiqib chalg'itardi.
                  profile.salaryType == SalaryType.fixed
                      ? 'Bugungi ish kuni yopildi — '
                            '${Formatters.hours(today.workedHours)} ishladingiz'
                      : 'Bugungi ish kuni yopildi — '
                            '${Formatters.money(today.dailyEarning, currency: profile.currency)}',
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

  /// Halqa + chiziqli barlar: oy davomidagi holat va umumiy ishlagan vaqt.
  Widget _buildStatistics(CustomTheme theme, UserProfile? profile) {
    final MonthlySummary? summary = ref.watch(currentMonthSummaryProvider);
    final AsyncValue<AttendanceTotals> totalsAsync = ref.watch(
      attendanceTotalsProvider,
    );

    if (summary == null || profile == null) {
      return const ShimmerBox(height: 260, borderRadius: 22);
    }

    final AttendanceTotals totals = totalsAsync.value ?? AttendanceTotals.empty;

    // Oyda kutilayotgan soat: ish kunlari x smena uzunligi.
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
                    '${summary.elapsedWorkDays}/${summary.plannedWorkDays}\nish kuni',
                size: 124,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Jami ishlagan vaqt', style: context.text.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      totalsAsync.isLoading && totalsAsync.value == null
                          ? '...'
                          : '${totals.workedHours.round()} soat',
                      style: context.text.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${totals.recordedDays} kun davomida',
                      style: context.text.labelSmall,
                    ),
                    const SizedBox(height: 14),
                    Text('Shu oyda', style: context.text.labelSmall),
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
            label: 'Ishlangan soat',
            value:
                '${summary.workedHours.round()} / '
                '${expectedHours.round()} soat',
            progress: expectedHours == 0
                ? 0
                : summary.workedHours / expectedHours,
            color: theme.blue,
          ),
          StatBar(
            label: 'Davomat',
            value: '${summary.presentDays} / ${summary.elapsedWorkDays} kun',
            progress: attendanceRate,
            color: theme.green,
          ),
          StatBar(
            label: 'Kechikish',
            value: Formatters.minutes(summary.lateMinutes),
            // Oyiga 10 soat kechikishni "to'liq shkala" deb olamiz.
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
    final String currency = profile?.currency ?? 'so\'m';

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      // 1.25: shkaladagi shrift bilan ikki qatorli yorliq sig'ishi uchun.
      childAspectRatio: 1.25,
      children: <Widget>[
        StatCard(
          icon: IconsaxPlusLinear.timer_1,
          label: 'Bugun ishlagan',
          value: today == null || !today.hasCheckedOut
              ? '—'
              : Formatters.hours(today.workedHours),
          accentColor: theme.blue,
        ),
        StatCard(
          icon: IconsaxPlusLinear.calendar_tick,
          label: 'Shu oy kelgan kunlar',
          value: summary == null ? '—' : '${summary.presentDays} kun',
          accentColor: theme.green,
        ),
        StatCard(
          icon: IconsaxPlusLinear.alarm,
          label: 'Shu oy kechikish',
          value: summary == null
              ? '—'
              : Formatters.minutes(summary.lateMinutes),
          accentColor: theme.yellow,
        ),
        StatCard(
          icon: IconsaxPlusLinear.moneys,
          label: 'Joriy oylik',
          value: summary == null
              ? '—'
              : Formatters.money(summary.earnedAmount, currency: currency),
          accentColor: theme.blue,
        ),
      ],
    );
  }
}

/// Hero karta ichidagi kichik statistika ustuni.
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
