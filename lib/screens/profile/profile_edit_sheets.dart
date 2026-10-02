import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile_model.dart';
import '../../providers/core_providers.dart';
import '../../services/image_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/time_utils.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/progress_dialog.dart';
import '../../widgets/common/cupertino_pickers.dart';

/// Profil maydonlarini tahrirlash oynalari (PROJECT.md 5.4).
///
/// Har bir metod faqat o'zi tegishli maydonni Firestore'ga yozadi —
/// butun profilni qayta yozmaydi, shunda boshqa maydonlar tasodifan
/// o'chib ketmaydi.
abstract final class ProfileEditSheets {
  /// Maydonlarni yozadi va jarayonni progress oynasi bilan ko'rsatadi.
  ///
  /// Foiz soxta emas: har bosqich haqiqiy ish birligiga mos keladi.
  static Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> fields,
  ) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    // Ism yoki rasm o'zgarsa, chat ro'yxatidagi ochiq profil ham yangilanadi.
    final bool touchesPublic =
        fields.containsKey('fullName') ||
        fields.containsKey('profilePhotoBase64');

    await runWithProgress<void>(
      context: context,
      title: 'Saqlanmoqda',
      task: (ProgressReporter report) async {
        report('Ma\'lumot yuborilmoqda...', 0.4);
        await ref.read(profileServiceProvider).updateFields(userId, fields);
        if (!touchesPublic) return;

        report('Chat profili yangilanmoqda...', 0.7);
        final UserProfile? current = await ref
            .read(profileServiceProvider)
            .fetch(userId);
        if (current == null) return;
        await ref
            .read(profileServiceProvider)
            .syncPublicProfile(
              userId,
              fullName: current.fullName,
              avatarBase64: await ImageService.avatarThumbnailBase64(
                current.profilePhotoBase64,
              ),
            );
      },
    );
  }

  // --- Rasm ----------------------------------------------------------------

  static Future<void> changePhoto(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final CustomTheme theme = context.theme;

    final String? action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(IconsaxPlusLinear.camera, color: theme.blue),
              title: const Text('Kameradan olish'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: Icon(IconsaxPlusLinear.gallery, color: theme.blue),
              title: const Text('Galereyadan tanlash'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            if (profile.profilePhotoBase64 != null)
              ListTile(
                leading: Icon(IconsaxPlusLinear.trash, color: theme.red),
                title: Text(
                  'Rasmni olib tashlash',
                  style: TextStyle(color: theme.red),
                ),
                onTap: () => Navigator.of(context).pop('remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !context.mounted) return;

    if (action == 'remove') {
      await _update(context, ref, <String, dynamic>{
        'profilePhotoBase64': null,
      });
      return;
    }

    final String? encoded = action == 'camera'
        ? await ref.read(imageServiceProvider).captureSelfieBase64()
        : await ref.read(imageServiceProvider).pickFromGalleryBase64();

    if (encoded == null || !context.mounted) return;
    await _update(context, ref, <String, dynamic>{
      'profilePhotoBase64': encoded,
    });
  }

  // --- Matnli maydonlar ----------------------------------------------------

  static Future<void> editFullName(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return _editText(
      context: context,
      title: 'Ism-familiya',
      initialValue: profile.fullName,
      hint: 'Ism va familiyangiz',
      onSave: (String value) =>
          _update(context, ref, <String, dynamic>{'fullName': value.trim()}),
    );
  }

  static Future<void> editCompany(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return _editText(
      context: context,
      title: 'Ish joyi',
      initialValue: profile.companyName,
      hint: 'Kompaniya nomi',
      onSave: (String value) =>
          _update(context, ref, <String, dynamic>{'companyName': value.trim()}),
    );
  }

  static Future<void> _editText({
    required BuildContext context,
    required String title,
    required String initialValue,
    required String hint,
    required Future<void> Function(String value) onSave,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );

    await _showSheet(
      context: context,
      title: title,
      builder: (BuildContext context, VoidCallback close) => Column(
        children: <Widget>[
          AppTextField(
            controller: controller,
            hint: hint,
            autofocus: true,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Saqlash',
            onPressed: () async {
              await onSave(controller.text);
              close();
            },
          ),
        ],
      ),
    );

    controller.dispose();
  }

  // --- Maosh ---------------------------------------------------------------

  static Future<void> editPhone(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return _editText(
      context: context,
      title: 'Telefon raqami',
      initialValue: profile.phoneNumber,
      hint: 'Telefon raqamingiz',
      keyboardType: TextInputType.phone,
      inputFormatters: const <TextInputFormatter>[UzPhoneFormatter()],
      textCapitalization: TextCapitalization.none,
      onSave: (String value) =>
          _update(context, ref, <String, dynamic>{'phoneNumber': value.trim()}),
    );
  }

  static Future<void> editPosition(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return _editText(
      context: context,
      title: 'Lavozim',
      initialValue: profile.position,
      hint: 'Lavozimingiz',
      onSave: (String value) =>
          _update(context, ref, <String, dynamic>{'position': value.trim()}),
    );
  }

  // --- Bitta variantli tanlovlar -------------------------------------------

  static Future<void> editSalaryType(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return _pickOne<SalaryType>(
      context: context,
      title: 'Maosh turi',
      current: profile.salaryType,
      options: <(SalaryType, String, String)>[
        for (final SalaryType type in SalaryType.values)
          (type, type.label, type.description),
      ],
      onSelected: (SalaryType value) =>
          _update(context, ref, <String, dynamic>{'salaryType': value.value}),
    );
  }

  static Future<void> editCurrency(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return _pickOne<String>(
      context: context,
      title: 'Valyuta',
      current: profile.currency,
      options: const <(String, String, String)>[
        ('so\'m', 'So\'m (UZS)', ''),
        ('USD', 'Dollar (USD)', ''),
      ],
      onSelected: (String value) =>
          _update(context, ref, <String, dynamic>{'currency': value}),
    );
  }

  static Future<void> editPenaltyPolicy(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return _pickOne<bool>(
      context: context,
      title: 'Kechikish jarimasi',
      current: profile.penaltyEnabled,
      options: const <(bool, String, String)>[
        (
          true,
          'Ushlanadi',
          'Kechikkan va erta ketgan daqiqalar uchun pul ayiriladi.',
        ),
        (false, 'Ushlanmaydi', 'Kechikish faqat statistika uchun yoziladi.'),
      ],
      onSelected: (bool value) =>
          _update(context, ref, <String, dynamic>{'penaltyEnabled': value}),
    );
  }

  static Future<void> editLunchBreak(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) {
    return _pickOne<int>(
      context: context,
      title: 'Tushlik tanaffusi',
      current: profile.lunchBreakMinutes,
      options: <(int, String, String)>[
        for (final int minutes in const <int>[0, 30, 45, 60, 90, 120])
          (minutes, minutes == 0 ? 'Yo\'q' : Formatters.minutes(minutes), ''),
      ],
      onSelected: (int value) =>
          _update(context, ref, <String, dynamic>{'lunchBreakMinutes': value}),
    );
  }

  /// Bir nechta tahrirlash uchun umumiy "bitta variantni tanlash" oynasi.
  static Future<void> _pickOne<T>({
    required BuildContext context,
    required String title,
    required T current,
    required List<(T, String, String)> options,
    required Future<void> Function(T value) onSelected,
  }) {
    return _showSheet(
      context: context,
      title: title,
      builder: (BuildContext sheetContext, VoidCallback close) {
        final CustomTheme theme = sheetContext.theme;
        return Column(
          children: <Widget>[
            for (final (T value, String label, String description) option
                in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () async {
                    close();
                    await onSelected(option.$1);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: option.$1 == current
                          ? theme.blue.withValues(alpha: 0.06)
                          : theme.glassFill,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: option.$1 == current
                            ? theme.blue
                            : theme.borderGray,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          option.$2,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.mainDarkBlue,
                          ),
                        ),
                        if (option.$3.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            option.$3,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: theme.textGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static Future<void> editSalary(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final TextEditingController minController = TextEditingController(
      text: profile.salaryMin > 0 ? Formatters.number(profile.salaryMin) : '',
    );
    final TextEditingController maxController = TextEditingController(
      text: profile.salaryMax > 0 ? Formatters.number(profile.salaryMax) : '',
    );

    await _showSheet(
      context: context,
      title: 'Oylik maosh oralig\'i',
      builder: (BuildContext sheetContext, VoidCallback close) {
        final CustomTheme theme = sheetContext.theme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: minController,
                    label: 'Eng kam',
                    hint: 'Summani kiriting',
                    keyboardType: TextInputType.number,
                    inputFormatters: const <TextInputFormatter>[
                      ThousandsFormatter(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: maxController,
                    label: 'Eng ko\'p',
                    hint: 'Summani kiriting',
                    keyboardType: TextInputType.number,
                    inputFormatters: const <TextInputFormatter>[
                      ThousandsFormatter(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Hisob-kitobda shu oraliqning o\'rtachasi ishlatiladi.',
              style: TextStyle(fontSize: 12, color: theme.textGray),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Saqlash',
              onPressed: () async {
                final double min = ThousandsFormatter.parse(minController.text);
                final double max = ThousandsFormatter.parse(maxController.text);
                if (min <= 0 && max <= 0) return;

                final double lo = min <= max ? min : max;
                final double hi = min <= max ? max : min;
                close();
                await _update(context, ref, <String, dynamic>{
                  'salaryMin': lo,
                  'salaryMax': hi,
                  'salaryAmount': UserProfile.averageOf(lo, hi),
                });
              },
            ),
          ],
        );
      },
    );

    minController.dispose();
    maxController.dispose();
  }

  // --- Tug'ilgan kun -------------------------------------------------------

  static Future<void> editBirthDate(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await SoftPickers.pickDate(
      context: context,
      title: 'Tug\'ilgan kuningiz',
      initial: profile.birthDate ?? DateTime(now.year - 25, now.month, now.day),
      first: DateTime(now.year - 100),
      last: now,
    );
    if (picked == null || !context.mounted) return;
    await _update(context, ref, <String, dynamic>{'birthDate': picked});
  }

  static Future<void> editEmploymentDate(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await SoftPickers.pickDate(
      context: context,
      title: 'Ishga kirgan sana',
      initial: profile.employmentStartDate ?? DateTime(now.year, now.month),
      first: DateTime(now.year - 50),
      last: now,
    );
    if (picked == null || !context.mounted) return;
    await _update(context, ref, <String, dynamic>{
      'employmentStartDate': picked,
    });
  }

  // --- Ish vaqti -----------------------------------------------------------

  static Future<void> editWorkTime(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final String? start = await _pickTime(
      context: context,
      title: 'Ish boshlanish vaqti',
      current: profile.workStartTime,
      fallbackMinutes: 9 * 60,
    );
    if (start == null || !context.mounted) return;

    final String? end = await _pickTime(
      context: context,
      title: 'Ish tugash vaqti',
      current: profile.workEndTime,
      fallbackMinutes: 18 * 60,
    );
    if (end == null || !context.mounted) return;

    await _update(context, ref, <String, dynamic>{
      'workStartTime': start,
      'workEndTime': end,
    });
  }

  static Future<String?> _pickTime({
    required BuildContext context,
    required String title,
    required String current,
    required int fallbackMinutes,
  }) async {
    final int? minutes = await SoftPickers.pickTimeMinutes(
      context: context,
      title: title,
      initialMinutes: TimeUtils.minutesFromHmOr(current, fallbackMinutes),
    );
    if (minutes == null) return null;
    return TimeUtils.hmFromMinutes(minutes);
  }

  // --- Ish kunlari ---------------------------------------------------------

  static Future<void> editWorkDays(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    List<int> selected = List<int>.of(profile.workDays);

    await _showSheet(
      context: context,
      title: 'Ish kunlari',
      builder: (BuildContext context, VoidCallback close) {
        final CustomTheme theme = context.theme;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) => Column(
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List<Widget>.generate(7, (int index) {
                  final int weekday = index + 1;
                  final bool isSelected = selected.contains(weekday);
                  return GestureDetector(
                    onTap: () => setSheetState(() {
                      final List<int> updated = List<int>.of(selected);
                      if (updated.contains(weekday)) {
                        updated.remove(weekday);
                      } else {
                        updated.add(weekday);
                      }
                      updated.sort();
                      selected = updated;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.blue : theme.glassFill,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected ? theme.blue : theme.borderGray,
                        ),
                      ),
                      child: Text(
                        Formatters.weekdaysShort[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? CustomTheme.onAccent
                              : theme.mainDarkBlue,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Saqlash',
                onPressed: selected.isEmpty
                    ? null
                    : () async {
                        await _update(context, ref, <String, dynamic>{
                          'workDays': selected,
                        });
                        close();
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Maosh kuni ----------------------------------------------------------

  static Future<void> editPayDay(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    int selected = profile.salaryPayDay;

    await _showSheet(
      context: context,
      title: 'Maosh beriladigan kun',
      builder: (BuildContext context, VoidCallback close) {
        final CustomTheme theme = context.theme;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) => Column(
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List<Widget>.generate(31, (int index) {
                  final int day = index + 1;
                  final bool isSelected = day == selected;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selected = day),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? theme.blue : theme.glassFill,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: isSelected ? theme.blue : theme.borderGray,
                        ),
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? CustomTheme.onAccent
                              : theme.mainDarkBlue,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Saqlash',
                onPressed: () async {
                  await _update(context, ref, <String, dynamic>{
                    'salaryPayDay': selected,
                  });
                  close();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Umumiy oyna ---------------------------------------------------------

  static Future<void> _showSheet({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext context, VoidCallback close) builder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final CustomTheme theme = sheetContext.theme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.borderGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.mainDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  builder(sheetContext, () => Navigator.of(sheetContext).pop()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
