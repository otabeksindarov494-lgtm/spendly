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
      appBar: AppBar(title: const Text('Barcha ma\'lumotlar')),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: ShimmerList(itemCount: 8, itemHeight: 56),
          ),
          error: (Object e, StackTrace _) =>
              ErrorView(message: 'Profil yuklanmadi: $e'),
          data: (UserProfile? profile) => profile == null
              ? const ErrorView(message: 'Profil topilmadi.')
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
        const SectionTitle(title: 'Shaxsiy'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: IconsaxPlusLinear.user,
                label: 'Ism-familiya',
                value: orDash(profile.fullName),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editFullName(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.cake,
                label: 'Tug\'ilgan kun',
                value: profile.birthDate == null
                    ? '—'
                    : Formatters.longDate(profile.birthDate!),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editBirthDate(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.call,
                label: 'Telefon',
                value: orDash(profile.phoneNumber),
                isLast: true,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editPhone(context, ref, profile),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Ish joyi'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: IconsaxPlusLinear.building,
                label: 'Kompaniya',
                value: orDash(profile.companyName),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editCompany(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.personalcard,
                label: 'Lavozim',
                value: orDash(profile.position),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editPosition(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.calendar_tick,
                label: 'Ishga kirgan sana',
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
        const SectionTitle(title: 'Maosh'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: IconsaxPlusLinear.empty_wallet,
                label: 'Maosh turi',
                value: profile.salaryType.label,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editSalaryType(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.moneys,
                label: 'Maosh oralig\'i',
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
                label: 'Hisobda ishlatiladi',
                value: Formatters.money(
                  profile.salaryAmount,
                  currency: profile.currency,
                ),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editSalary(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.dollar_circle,
                label: 'Valyuta',
                value: profile.currency,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editCurrency(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.calendar_tick,
                label: 'Maosh beriladigan kun',
                value: 'Oyning ${profile.salaryPayDay}-kuni',
                isLast: true,
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editPayDay(context, ref, profile),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Ish jadvali'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              InfoRow(
                icon: IconsaxPlusLinear.clock,
                label: 'Ish vaqti',
                value: '${profile.workStartTime} – ${profile.workEndTime}',
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editWorkTime(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.coffee,
                label: 'Tushlik tanaffusi',
                value: profile.lunchBreakMinutes == 0
                    ? 'Yo\'q'
                    : Formatters.minutes(profile.lunchBreakMinutes),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editLunchBreak(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.calendar,
                label: 'Ish kunlari',
                value: profile.workDays.isEmpty
                    ? '—'
                    : Formatters.workDays(profile.workDays),
                onTap: (WidgetRef ref) =>
                    ProfileEditSheets.editWorkDays(context, ref, profile),
              ),
              InfoRow(
                icon: IconsaxPlusLinear.alarm,
                label: 'Kechikish jarimasi',
                value: profile.penaltyEnabled ? 'Ushlanadi' : 'Ushlanmaydi',
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

  /// Tanlangan sozlamalar amalda nimani anglatishini oddiy til bilan
  /// tushuntiradi — foydalanuvchi noto'g'ri tanlab qo'ymasin.
  Widget _buildRuleNote(BuildContext context, UserProfile profile) {
    final CustomTheme theme = context.theme;
    final bool isFixed = profile.salaryType == SalaryType.fixed;

    final String text = isFixed
        ? 'Maoshingiz **fixed**: kelishilgan summa har oy to\'liq beriladi. '
              'Ishga bormagan kun uchun pul ushlanmaydi, dam olish kunida '
              'ishlasangiz ham qo\'shilmaydi.'
        : 'Maoshingiz **kunlik hisob**: oylik summa ish kunlariga bo\'linadi '
              'va har bir kelgan kun uchun alohida yoziladi.';

    final String penaltyText = profile.penaltyEnabled
        ? ' Kechikish va erta ketish uchun pul ushlanadi.'
        : ' Kechikish pulga ta\'sir qilmaydi, faqat statistikada ko\'rinadi.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(IconsaxPlusLinear.info_circle, size: 15, color: theme.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.replaceAll('**', '') + penaltyText,
              style: TextStyle(
                fontSize: 12,
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
