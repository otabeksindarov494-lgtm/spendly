import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/attendance_model.dart';
import '../../models/user_profile_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/month_days.dart';
import '../../utils/salary_calculator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/glass.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/shimmer_box.dart';
import '../../widgets/common/stat_card.dart';
import 'report_day_tile.dart';

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
      appBar: AppBar(title: Text('report_title'.tr())),
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
              _buildHeroCard(context, theme, profile, summary, currency),
            const SizedBox(height: 20),
            if (summary == null)
              const ShimmerBox(height: 220, borderRadius: 20)
            else
              _buildStatsGrid(theme, summary),
            const SizedBox(height: 24),
            SectionTitle(title: 'daily_records'.tr()),
            // Oyning HAR BIR kuni (kelmagan va dam olish kunlari ham).
            // Elementlar to'g'ridan-to'g'ri ListView'ga qo'yiladi — faqat
            // ekranda ko'ringan kunlar (va ularning selfilari) quriladi.
            ...recordsAsync.when(
              loading: () => <Widget>[const ShimmerList(itemCount: 4)],
              error: (Object e, StackTrace _) => <Widget>[
                ErrorView(
                  message: 'records_load_error'.tr(args: <String>[e.toString()]),
                ),
              ],
              data: (List<Attendance> records) {
                final List<ReportDay> days = MonthDays.build(
                  month: month,
                  records: records,
                  workDays: profile?.workDays ?? const <int>[],
                  now: DateTime.now(),
                );
                if (records.isEmpty || days.isEmpty) {
                  return <Widget>[
                    EmptyState(
                      icon: IconsaxPlusLinear.calendar_2,
                      title: 'no_records_for_month'.tr(
                        args: <String>[Formatters.monthYear(month)],
                      ),
                      message: 'no_records_for_month_msg'.tr(),
                    ),
                  ];
                }
                return <Widget>[
                  for (final ReportDay day in days)
                    ReportDayTile(
                      day: day,
                      currency: currency,
                      // Fixed maoshda pul kunlarga bo'linmaydi — kunlik
                      // summa ko'rsatilsa "0 so'm" bo'lib chalg'itardi.
                      showEarning: profile?.salaryType != SalaryType.fixed,
                    ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    CustomTheme theme,
    UserProfile profile,
    MonthlySummary summary,
    String currency,
  ) {
    // Ekranning asosiy elementi — haqiqiy blur'li shisha panel.
    return GlassPanel(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('current_calculated_salary'.tr(), style: context.text.bodySmall),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.money(summary.earnedAmount, currency: currency),
              style: context.text.displaySmall,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'salary_and_penalty_format'.tr(
              args: <String>[
                Formatters.money(profile.salaryAmount, currency: currency),
                Formatters.money(summary.penaltyAmount, currency: currency),
              ],
            ),
            style: context.text.labelSmall,
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
            'work_days_progress_format'.tr(
              args: <String>[
                summary.elapsedWorkDays.toString(),
                summary.plannedWorkDays.toString(),
              ],
            ),
            style: context.text.labelSmall,
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
      // 1.25: shkaladagi shrift bilan ikki qatorli yorliq sig'ishi uchun.
      childAspectRatio: 1.25,
      children: <Widget>[
        StatCard(
          icon: IconsaxPlusLinear.timer,
          label: 'total_worked_hours_stat'.tr(),
          value: 'hours_suffix'.tr(
            args: <String>[summary.workedHours.round().toString()],
          ),
          accentColor: theme.blue,
        ),
        StatCard(
          icon: IconsaxPlusLinear.calendar_tick,
          label: 'present_days_label'.tr(),
          value: 'days_suffix'.tr(
            args: <String>[summary.presentDays.toString()],
          ),
          accentColor: theme.green,
        ),
        StatCard(
          icon: IconsaxPlusLinear.calendar_remove,
          label: 'absent_days_label'.tr(),
          value: 'days_suffix'.tr(args: <String>[summary.absentDays.toString()]),
          accentColor: theme.red,
        ),
        StatCard(
          icon: IconsaxPlusLinear.alarm,
          label: 'total_lateness'.tr(),
          value: Formatters.minutes(summary.lateMinutes),
          accentColor: theme.yellow,
        ),
        StatCard(
          icon: IconsaxPlusLinear.logout,
          label: 'total_early_leave'.tr(),
          value: Formatters.minutes(summary.earlyLeaveMinutes),
          accentColor: theme.yellow,
        ),
        StatCard(
          icon: IconsaxPlusLinear.minus_cirlce,
          label: 'total_penalty'.tr(),
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
        color: theme.glassFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.glassBorder),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(
              IconsaxPlusLinear.arrow_left_1,
              color: theme.mainDarkBlue,
            ),
            onPressed: notifier.previous,
          ),
          Expanded(
            child: Text(
              Formatters.monthYear(month),
              textAlign: TextAlign.center,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
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
