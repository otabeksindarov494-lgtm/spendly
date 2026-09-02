import 'package:bootstrap_icons/bootstrap_icons.dart';
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
import '../../widgets/common/app_button.dart';
import '../../widgets/common/attendance_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/shimmer_box.dart';
import '../../widgets/common/progress_dialog.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCheckIn ? 'Kelganingiz qayd etildi' : 'Ketganingiz qayd etildi',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
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
              const SectionTitle(title: 'Oxirgi 7 kun'),
              weekAsync.when(
                loading: () => const ShimmerList(itemCount: 3),
                error: (Object e, StackTrace _) =>
                    ErrorView(message: 'Ro\'yxat yuklanmadi: $e'),
                data: (List<Attendance> records) {
                  if (records.isEmpty) {
                    return const EmptyState(
                      icon: BootstrapIcons.calendar_x,
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
        Text(
          'Assalomu alaykum',
          style: TextStyle(fontSize: 12, color: theme.textGray),
        ),
        const SizedBox(height: 2),
        Text(
          firstName.isEmpty ? 'Spendly' : firstName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.mainDarkBlue,
          ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(22),
        // Juda nozik chegara — to'q gradient o'rniga tinch, toza yuza.
        border: Border.all(color: theme.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                BootstrapIcons.calendar_event,
                size: 16,
                color: context.theme.textGray,
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.longDate(DateTime.now()),
                style: TextStyle(fontSize: 12, color: context.theme.textGray),
              ),
              const Spacer(),
              if (!isWorkDay)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.gray,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.borderGray),
                  ),
                  child: Text(
                    'Dam olish kuni',
                    style: TextStyle(fontSize: 10, color: theme.textGray),
                  ),
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
            _buildCompletedBody(today),
        ],
      ),
    );
  }

  Widget _buildRestDayBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Bugun dam olish kuni',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.theme.mainDarkBlue,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Bu kun uchun hisob-kitob va jarima yuritilmaydi.',
          style: TextStyle(fontSize: 12, color: context.theme.textGray),
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
          style: TextStyle(fontSize: 13, color: context.theme.textGray),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Ishga keldim',
          icon: BootstrapIcons.camera_fill,
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
          icon: BootstrapIcons.box_arrow_right,
          variant: AppButtonVariant.secondary,
          isLoading: _isBusy,
          onPressed: () => _record(profile: profile, today: today),
        ),
      ],
    );
  }

  Widget _buildCompletedBody(Attendance today) {
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                BootstrapIcons.check_circle_fill,
                size: 16,
                color: context.theme.mainDarkBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bugungi ish kuni yopildi — '
                  '${Formatters.money(today.dailyEarning)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.theme.mainDarkBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
      childAspectRatio: 1.35,
      children: <Widget>[
        StatCard(
          icon: BootstrapIcons.stopwatch,
          label: 'Bugun ishlagan',
          value: today == null || !today.hasCheckedOut
              ? '—'
              : Formatters.hours(today.workedHours),
          accentColor: theme.blue,
        ),
        StatCard(
          icon: BootstrapIcons.calendar_check,
          label: 'Shu oy kelgan kunlar',
          value: summary == null ? '—' : '${summary.presentDays} kun',
          accentColor: theme.green,
        ),
        StatCard(
          icon: BootstrapIcons.alarm,
          label: 'Shu oy kechikish',
          value: summary == null
              ? '—'
              : Formatters.minutes(summary.lateMinutes),
          accentColor: theme.yellow,
        ),
        StatCard(
          icon: BootstrapIcons.cash_coin,
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
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.theme.textGray),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.theme.mainDarkBlue,
            ),
          ),
        ],
      ),
    );
  }
}
