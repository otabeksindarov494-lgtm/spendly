import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/core_providers.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_title.dart';

/// Sozlamalar: mavzu, til va ilova versiyasi.
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

    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            const SectionTitle(title: 'Ko\'rinish'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        BootstrapIcons.palette,
                        size: 17,
                        color: theme.textGray,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Mavzu',
                        style: TextStyle(
                          fontSize: 14,
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
                    style: TextStyle(fontSize: 11, color: theme.textGray),
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
                                      : theme.inputColor,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      option == ThemeMode.dark
                                          ? BootstrapIcons.moon
                                          : BootstrapIcons.sun,
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
            const SectionTitle(title: 'Til'),
            AppCard(
              child: Row(
                children: <Widget>[
                  Icon(BootstrapIcons.globe2, size: 17, color: theme.textGray),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Interfeys tili',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.mainDarkBlue,
                      ),
                    ),
                  ),
                  Text(
                    'O\'zbekcha',
                    style: TextStyle(fontSize: 13, color: theme.textGray),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Ilova haqida'),
            AppCard(
              child: Row(
                children: <Widget>[
                  Icon(
                    BootstrapIcons.info_circle,
                    size: 17,
                    color: theme.textGray,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Versiya',
                      style: TextStyle(
                        fontSize: 14,
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
