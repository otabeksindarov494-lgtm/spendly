import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile_model.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/info_row.dart';
import '../../widgets/common/section_title.dart';
import '../../widgets/common/shimmer_box.dart';
import 'profile_edit_sheets.dart';

/// "Barcha ma'lumotlar" — ro'yxatdan o'tishda so'ralgan hamma narsa
/// bir ekranda, har biri tahrirlanadigan holda.
class AllDataScreen extends ConsumerWidget {
  const AllDataScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const AllDataScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: Text('all_data'.tr())),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(itemCount: 8, itemHeight: 56),
          ),
          error: (Object e, StackTrace _) =>
              ErrorView(message: 'profile_load_error'.tr(args: [e.toString()])),
          data: (UserProfile? profile) => profile == null
              ? ErrorView(message: 'profile_not_found'.tr())
              : _buildBody(context, profile),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfile profile) {
    String orDash(String value) => value.trim().isEmpty ? '—' : value.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: <Widget>[
        SectionTitle(title: 'personal_section'.tr()),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: IconsaxPlusLinear.user,
                label: 'full_name'.tr(),
                value: orDash(profile.fullName),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editFullName(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.cake,
                label: 'birth_date_label'.tr(),
                value: profile.birthDate == null
                    ? '—'
                    : Formatters.longDate(profile.birthDate!),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editBirthDate(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.call,
                label: 'phone_label'.tr(),
                value: orDash(profile.phoneNumber),
                isLast: true,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editPhone(context, ref, profile),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(title: 'workplace_section'.tr()),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: IconsaxPlusLinear.building,
                label: 'company_label'.tr(),
                value: orDash(profile.companyName),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editCompany(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.personalcard,
                label: 'position_label'.tr(),
                value: orDash(profile.position),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editPosition(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.calendar_tick,
                label: 'employment_date_label'.tr(),
                value: profile.employmentStartDate == null
                    ? '—'
                    : Formatters.longDate(profile.employmentStartDate!),
                isLast: true,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editEmploymentDate(context, ref, profile),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(title: 'salary_section'.tr()),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: IconsaxPlusLinear.empty_wallet,
                label: 'salary_type_label'.tr(),
                value: profile.salaryType.label,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editSalaryType(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.moneys,
                label: 'salary_range_label'.tr(),
                value: profile.salaryMin <= 0 && profile.salaryMax <= 0
                    ? Formatters.money(
                        profile.salaryAmount,
                        currency: profile.currency,
                      )
                    : '${Formatters.number(profile.salaryMin)} – '
                          '${Formatters.money(profile.salaryMax, currency: profile.currency)}',
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editSalary(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.calculator,
                label: 'used_in_calc_label'.tr(),
                value: Formatters.money(
                  profile.salaryAmount,
                  currency: profile.currency,
                ),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editSalary(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.dollar_circle,
                label: 'select_currency'.tr(),
                value: profile.currency,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editCurrency(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.calendar_tick,
                label: 'pay_day_label'.tr(),
                value: 'pay_day_format'.tr(args: [profile.salaryPayDay.toString()]),
                isLast: true,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editPayDay(context, ref, profile),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(title: 'schedule_section'.tr()),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: IconsaxPlusLinear.clock,
                label: 'work_time_label'.tr(),
                value: '${profile.workStartTime} – ${profile.workEndTime}',
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editWorkTime(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.coffee,
                label: 'lunch_break_label'.tr(),
                value: profile.lunchBreakMinutes == 0
                    ? 'none_label'.tr()
                    : Formatters.minutes(profile.lunchBreakMinutes),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editLunchBreak(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.calendar,
                label: 'work_days_label'.tr(),
                value: profile.workDays.isEmpty
                    ? '—'
                    : Formatters.workDays(profile.workDays),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editWorkDays(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.alarm,
                label: 'penalty_policy_label'.tr(),
                value: profile.penaltyEnabled ? 'deducted'.tr() : 'not_deducted'.tr(),
                isLast: true,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editPenaltyPolicy(context, ref, profile),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildRuleNote(context, profile),
      ],
    );
  }

  /// Tanlangan sozlamalar amalda nimani anglatishini tushuntiradi.
  Widget _buildRuleNote(BuildContext context, UserProfile profile) {
    final CustomTheme theme = context.theme;
    final bool isFixed = profile.salaryType == SalaryType.fixed;

    final String text = isFixed
        ? 'fixed_rule_note'.tr()
        : 'calculated_rule_note'.tr();

    final String penaltyText = profile.penaltyEnabled
        ? 'penalty_rule_active'.tr()
        : 'penalty_rule_inactive'.tr();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(IconsaxPlusLinear.info_circle, size: 15, color: theme.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text + penaltyText,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
