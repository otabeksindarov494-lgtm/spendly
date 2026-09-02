import 'package:bootstrap_icons/bootstrap_icons.dart';
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
              leading: Icon(BootstrapIcons.camera, color: theme.blue),
              title: const Text('Kameradan olish'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: Icon(BootstrapIcons.images, color: theme.blue),
              title: const Text('Galereyadan tanlash'),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            if (profile.profilePhotoBase64 != null)
              ListTile(
                leading: Icon(BootstrapIcons.trash, color: theme.red),
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
      hint: 'Masalan: Azizbek Erkinov',
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
            textCapitalization: TextCapitalization.words,
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

  static Future<void> editSalary(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: Formatters.number(profile.salaryAmount),
    );

    await _showSheet(
      context: context,
      title: 'Oylik maosh',
      builder: (BuildContext context, VoidCallback close) => Column(
        children: <Widget>[
          AppTextField(
            controller: controller,
            hint: '5 000 000',
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: const <TextInputFormatter>[ThousandsFormatter()],
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Saqlash',
            onPressed: () async {
              final double amount = ThousandsFormatter.parse(controller.text);
              if (amount <= 0) return;
              await _update(context, ref, <String, dynamic>{
                'salaryAmount': amount,
              });
              close();
            },
          ),
        ],
      ),
    );

    controller.dispose();
  }

  // --- Tug'ilgan kun -------------------------------------------------------

  static Future<void> editBirthDate(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          profile.birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Tug\'ilgan kuningiz',
      cancelText: 'Bekor qilish',
      confirmText: 'Tanlash',
    );
    if (picked == null || !context.mounted) return;
    await _update(context, ref, <String, dynamic>{'birthDate': picked});
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
    final int minutes = TimeUtils.minutesFromHmOr(current, fallbackMinutes);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: title,
      cancelText: 'Bekor qilish',
      confirmText: 'Tanlash',
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return TimeUtils.hmFromMinutes(picked.hour * 60 + picked.minute);
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
                        color: isSelected ? theme.blue : theme.background,
                        borderRadius: BorderRadius.circular(14),
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
                        color: isSelected ? theme.blue : theme.background,
                        borderRadius: BorderRadius.circular(12),
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
