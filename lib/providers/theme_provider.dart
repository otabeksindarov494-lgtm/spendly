import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core_providers.dart';
import 'profile_provider.dart';

/// Mavzu rejimi: `SharedPreferences`da saqlanadi (PROJECT.md 2-bo'lim),
/// shu bilan birga Firestore profiliga ham ko'chiriladi (3.2 `themeMode`).
///
/// Ilova ochilishida darhol kerak bo'lgani uchun asosiy manba —
/// `SharedPreferences`, Firestore esa faqat nusxa.
///
/// **Faqat ikkita rejim:** Yorug' va Tungi. Qurilma tizimi rangi
/// hisobga OLINMAYDI — sukut bo'yicha har doim [ThemeMode.light].
/// (PROJECT.md 5.4 da "System" varianti ham bor edi, lekin u ataylab
/// olib tashlangan.) Qaytarish uchun [selectable] ro'yxatiga
/// [ThemeMode.system] ni qo'shish kifoya.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String storageKey = 'themeMode';

  /// Profil ekranida tanlash mumkin bo'lgan rejimlar.
  static const List<ThemeMode> selectable = <ThemeMode>[
    ThemeMode.light,
    ThemeMode.dark,
  ];

  @override
  ThemeMode build() {
    final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);
    final String? stored = prefs.getString(storageKey);
    if (stored != null) return fromName(stored);

    // Bu qurilmada hali tanlov yo'q (masalan yangi o'rnatish) — Firestore
    // profilidagi nusxadan olamiz, shunda tanlov qurilmalar orasida yo'qolmaydi.
    return fromName(ref.watch(profileProvider).value?.themeMode);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;

    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(storageKey, toName(mode));

    // Firestore'dagi nusxani yangilaymiz — kirilmagan bo'lsa o'tkazib yuboriladi.
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref
        .read(profileServiceProvider)
        .updateFields(userId, <String, dynamic>{'themeMode': toName(mode)});
  }

  /// Noma'lum yoki eski 'system' qiymati ham Yorug'ga tushadi.
  static ThemeMode fromName(String? name) =>
      name == 'dark' ? ThemeMode.dark : ThemeMode.light;

  static String toName(ThemeMode mode) =>
      mode == ThemeMode.dark ? 'dark' : 'light';

  static String label(ThemeMode mode) =>
      mode == ThemeMode.dark ? 'Tungi' : 'Yorug\'';
}

final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
