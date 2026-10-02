import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/attendance_model.dart';
import '../../models/user_profile_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/salary_calculator.dart';
import '../../widgets/common/attendance_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/shimmer_box.dart';
import '../../widgets/common/stat_card.dart';

/// 2-tab: tanlangan oy bo'yicha to'liq hisobot (PROJECT.md 5.2).
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CustomTheme theme = context.theme;
    final DateTime month = ref.watch(selectedMonthProvider);
    final UserProfile? profile = ref.watch(profileProvider).value;
    final MonthlySummary? summary = ref.watch(monthlySummaryProvider);
    final AsyncValue<List<Attendance>> recordsAsync = ref.watch(
      monthAttendanceProvider,
    );
    final String currency = profile?.currency ?? 'so\'m';

    return Scaffold(
      appBar: AppBar(title: const Text('Hisobot')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: <Widget>[
            _MonthSelector(month: month),
            const SizedBox(height: 20),
            if (summary == null || profile == null)
              const ShimmerBox(height: 170, borderRadius: 24)
            else
              _buildHeroCard(theme, profile, summary, currency),
            const SizedBox(height: 20),
            if (summary == null)
              const ShimmerBox(height: 220, borderRadius: 20)
            else
              _buildStatsGrid(theme, summary),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Kunlik yozuvlar'),
            recordsAsync.when(
              loading: () => const ShimmerList(itemCount: 4),
              error: (Object e, StackTrace _) =>
                  ErrorView(message: 'Yozuvlar yuklanmadi: $e'),
              data: (List<Attendance> records) {
                if (records.isEmpty) {
                  return EmptyState(
                    icon: IconsaxPlusLinear.calendar_2,
                    title: '${Formatters.monthYear(month)} uchun yozuv yo\'q',
                    message: 'Bu oyda hali davomat qayd etilmagan.',
                  );
                }
                return Column(
                  children: <Widget>[
                    for (final Attendance record in records)
                      AttendanceTile(
                        attendance: record,
                        currency: currency,
                        // Fixed maoshda pul kunlarga bo'linmaydi — kunlik
                        // summa ko'rsatilsa "0 so'm" bo'lib chalg'itardi.
                        showEarning: profile?.salaryType != SalaryType.fixed,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    CustomTheme theme,
    UserProfile profile,
    MonthlySummary summary,
    String currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Joriy hisoblangan oylik',
            style: TextStyle(fontSize: 13, color: theme.textGray),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.money(summary.earnedAmount, currency: currency),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: theme.mainDarkBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Belgilangan oylik: '
            '${Formatters.money(profile.salaryAmount, currency: currency)}'
            '  |  Jarima: '
            '-${Formatters.money(summary.penaltyAmount, currency: currency)}',
            style: TextStyle(fontSize: 12, color: theme.textGray),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 6,
              backgroundColor: theme.borderGray,
              valueColor: AlwaysStoppedAnimation<Color>(theme.blue),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.elapsedWorkDays}/${summary.plannedWorkDays} ish kuni',
            style: TextStyle(fontSize: 12, color: theme.textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(CustomTheme theme, MonthlySummary summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: <Widget>[
        StatCard(
          icon: IconsaxPlusLinear.timer,
          label: 'Jami ishlangan soat',
          value: '${summary.workedHours.round()} soat',
          accentColor: theme.blue,
        ),
        StatCard(
          icon: IconsaxPlusLinear.calendar_tick,
          label: 'Kelgan kunlar',
          value: '${summary.presentDays} kun',
          accentColor: theme.green,
        ),
        StatCard(
          icon: IconsaxPlusLinear.calendar_remove,
          label: 'Kelmagan kunlar',
          value: '${summary.absentDays} kun',
          accentColor: theme.red,
        ),
        StatCard(
          icon: IconsaxPlusLinear.alarm,
          label: 'Jami kechikish',
          value: Formatters.minutes(summary.lateMinutes),
          accentColor: theme.yellow,
        ),
        StatCard(
          icon: IconsaxPlusLinear.logout,
          label: 'Jami erta ketish',
          value: Formatters.minutes(summary.earlyLeaveMinutes),
          accentColor: theme.yellow,
        ),
        StatCard(
          icon: IconsaxPlusLinear.minus_cirlce,
          label: 'Jami jarima',
          value: Formatters.money(summary.penaltyAmount),
          accentColor: theme.red,
        ),
      ],
    );
  }
}

/// "< Sentabr 2026 >" ko'rinishidagi oy navigatsiyasi.
class _MonthSelector extends ConsumerWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CustomTheme theme = context.theme;
    final SelectedMonthNotifier notifier = ref.read(
      selectedMonthProvider.notifier,
    );
    final bool canGoNext = notifier.canGoNext;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.borderGray),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(IconsaxPlusLinear.arrow_left_1, color: theme.mainDarkBlue),
            onPressed: notifier.previous,
          ),
          Expanded(
            child: Text(
              Formatters.monthYear(month),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.mainDarkBlue,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              IconsaxPlusLinear.arrow_right_3,
              color: canGoNext ? theme.mainDarkBlue : theme.favoriteGray,
            ),
            onPressed: canGoNext ? notifier.next : null,
          ),
        ],
      ),
    );
  }
}
