import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Mavzu tanlovi ilova ochilishida darhol kerak bo'lgani uchun
  // `SharedPreferences` sinxron ishlatiladigan qilib oldindan yuklanadi.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    // Sozlanmagan bo'lsa ilova crash bo'lmaydi — ko'rsatma ekrani chiqadi.
    firebaseError = error.toString();
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('uz'),
        Locale('ru'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('uz'),
      child: ProviderScope(
        // `Override` tipi flutter_riverpod'dan eksport qilinmagan,
        // shuning uchun bu yerda tip inferensiyasi ishlatiladi.
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: SpendlyApp(firebaseError: firebaseError),
      ),
    ),
  );
}
