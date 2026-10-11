import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/firebase_setup_screen.dart';
import 'theme/app_theme.dart';

/// Ilovaning ildiz widget'i.
///
/// [firebaseError] `null` bo'lmasa, Firebase ishga tushmagan — bu holda
/// oq ekran o'rniga sozlash ko'rsatmalari ko'rsatiladi.
class SpendlyApp extends ConsumerWidget {
  const SpendlyApp({super.key, this.firebaseError});

  final String? firebaseError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: firebaseError == null
          ? const AuthGate()
          : FirebaseSetupScreen(error: firebaseError!),
    );
  }
}
