import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_title.dart';

/// Sozlamalar: mavzu, eslatmalar, til va ilova versiyasi.
///
/// Profil ekrani faqat kirish nuqtasi bo'lib qolishi uchun alohida
/// ekranga ajratilgan.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CustomTheme theme = context.theme;
    final ThemeMode mode = ref.watch(themeModeProvider);
    final AsyncValue<String> version = ref.watch(appVersionProvider);
    final bool remindersEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            SectionTitle(title: 'appearance'.tr()),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        IconsaxPlusLinear.colorfilter,
                        size: 17,
                        color: theme.textGray,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'theme'.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.mainDarkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Qurilma tizimining rangi olinmaydi — tanlovingiz '
                    'saqlanadi.',
                    style: TextStyle(fontSize: 12, color: theme.textGray),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      for (final ThemeMode option
                          in ThemeModeNotifier.selectable)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: option == ThemeModeNotifier.selectable.last
                                  ? 0
                                  : 8,
                            ),
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(themeModeProvider.notifier)
                                  .setMode(option),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: mode == option
                                      ? theme.blue
                                      : theme.glassFill,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      option == ThemeMode.dark
                                          ? IconsaxPlusLinear.moon
                                          : IconsaxPlusLinear.sun_1,
                                      size: 15,
                                      color: mode == option
                                          ? CustomTheme.onAccent
                                          : theme.textGray,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      ThemeModeNotifier.label(option),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: mode == option
                                            ? CustomTheme.onAccent
                                            : theme.mainDarkBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(title: 'notifications'.tr()),
            AppCard(
              child: Row(
                children: <Widget>[
                  Icon(
                    IconsaxPlusLinear.notification,
                    size: 17,
                    color: theme.textGray,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'reminders'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.mainDarkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ish boshlanishidan 10 daqiqa oldin, boshlanganda '
                          'va tugaganda eslatadi. Dam olish kunlari jim.',
                          style: TextStyle(fontSize: 12, color: theme.textGray),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoSwitch(
                    value: remindersEnabled,
                    activeTrackColor: theme.blue,
                    onChanged: (bool value) => ref
                        .read(notificationsEnabledProvider.notifier)
                        .setEnabled(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(title: 'language'.tr()),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        IconsaxPlusLinear.global,
                        size: 17,
                        color: theme.textGray,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'language'.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.mainDarkBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      for (final MapEntry<String, String> entry in const [
                        MapEntry('uz', "O'zbek"),
                        MapEntry('ru', 'Русский'),
                        MapEntry('en', 'English'),
                      ])
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: entry.key == 'en' ? 0 : 8,
                            ),
                            child: GestureDetector(
                              onTap: () => context.setLocale(Locale(entry.key)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.locale.languageCode == entry.key
                                      ? theme.blue
                                      : theme.glassFill,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.locale.languageCode == entry.key
                                        ? CustomTheme.onAccent
                                        : theme.mainDarkBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(title: 'about'.tr()),
            AppCard(
              child: Row(
                children: <Widget>[
                  Icon(
                    IconsaxPlusLinear.info_circle,
                    size: 17,
                    color: theme.textGray,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'version'.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.mainDarkBlue,
                      ),
                    ),
                  ),
                  Text(
                    version.when(
                      loading: () => '...',
                      error: (Object _, StackTrace _) => '—',
                      data: (String value) => value,
                    ),
                    style: TextStyle(fontSize: 13, color: theme.textGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
