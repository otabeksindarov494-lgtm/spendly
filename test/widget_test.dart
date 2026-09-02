import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendly/app.dart';
import 'package:spendly/providers/core_providers.dart';
import 'package:spendly/providers/theme_provider.dart';
import 'package:spendly/theme/app_theme.dart';

/// Butun `lib/` daraxtini kompilyatsiya qiladigan smoke-testlar.
///
/// Firebase'ga ulanish talab qilinmaydi: [SpendlyApp] `firebaseError`
/// berilganda sozlash ekranini ko'rsatadi.
Future<Widget> _buildApp({String? firebaseError, ThemeMode? saved}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (saved != null) ThemeModeNotifier.storageKey: ThemeModeNotifier.toName(saved),
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: SpendlyApp(firebaseError: firebaseError),
  );
}

void main() {
  testWidgets('Firebase sozlanmagan bo\'lsa ko\'rsatma ekrani chiqadi',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      await _buildApp(firebaseError: 'UnsupportedError: test'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Firebase sozlanmagan'), findsOneWidget);
    expect(find.text('flutterfire configure'), findsOneWidget);
  });

  testWidgets('saqlangan mavzu rejimi o\'qiladi', (WidgetTester tester) async {
    await tester.pumpWidget(
      await _buildApp(firebaseError: 'test', saved: ThemeMode.dark),
    );
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('sukut bo\'yicha Yorug\' mavzu (tizim rangi olinmaydi)',
      (WidgetTester tester) async {
    await tester.pumpWidget(await _buildApp(firebaseError: 'test'));
    await tester.pumpAndSettle();

    final MaterialApp app =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(app.themeMode, isNot(ThemeMode.system));
  });

  testWidgets('eski "system" qiymati ham Yorug\'ga tushadi', (_) async {
    expect(ThemeModeNotifier.fromName('system'), ThemeMode.light);
    expect(ThemeModeNotifier.fromName(null), ThemeMode.light);
    expect(ThemeModeNotifier.fromName('dark'), ThemeMode.dark);
  });

  testWidgets('interfeys tili o\'zbekcha', (WidgetTester tester) async {
    await tester.pumpWidget(await _buildApp(firebaseError: 'test'));
    await tester.pumpAndSettle();

    final MaterialApp app =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('uz'));
    expect(app.supportedLocales, contains(const Locale('uz')));
  });

  testWidgets('CustomTheme kengaytmasi ikkala mavzuda ham mavjud',
      (WidgetTester tester) async {
    for (final ThemeData theme in <ThemeData>[
      AppTheme.light,
      AppTheme.dark,
    ]) {
      late CustomTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (BuildContext context) {
              resolved = context.theme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // Ranglar hardcode qilinmagan — hammasi kengaytmadan olinadi.
      expect(resolved.blue, const Color(0xFF3083FF));
      expect(resolved.gradient.colors.length, 2);
    }
  });
}
