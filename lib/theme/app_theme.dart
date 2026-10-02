import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/common/glass.dart';

/// Spendly dizayn tizimi (PROJECT.md 2-bo'lim).
///
/// Barcha ranglar SHU yerdan olinadi — ekranlarda hech qanday rang
/// hardcode qilinmaydi. Foydalanish: `context.theme.blue`.
@immutable
class CustomTheme extends ThemeExtension<CustomTheme> {
  const CustomTheme({
    required this.background,
    required this.inputColor,
    required this.gray,
    required this.borderGray,
    required this.textGray,
    required this.favoriteGray,
    required this.bottomNavBg,
    required this.bottomNavBlue,
    required this.mainDarkBlue,
    required this.textMainDarkBlue,
    required this.yellow,
    required this.red,
    required this.blue,
    required this.green,
    required this.gradient,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.backgroundGradient,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.glassFill,
    required this.glassBorder,
    required this.glassShadow,
  });

  /// Kartalar, sahifa foni.
  final Color background;

  /// Input maydonlari, scaffold foni.
  final Color inputColor;

  /// Ikkinchi darajali fon.
  final Color gray;

  /// Chegaralar.
  final Color borderGray;

  /// Ikkinchi darajali matn.
  final Color textGray;

  /// Neytral ikonkalar.
  final Color favoriteGray;

  /// Pastki navigatsiya foni.
  final Color bottomNavBg;

  /// Faol bo'lmagan tab ikonkasi.
  final Color bottomNavBlue;

  /// Asosiy matn, aktiv elementlar.
  final Color mainDarkBlue;

  /// [mainDarkBlue] ustidagi matn.
  final Color textMainDarkBlue;

  /// Ogohlantirish, kechikish belgisi.
  final Color yellow;

  /// Xato, qarz (siz qarzsiz), manfiy.
  final Color red;

  /// Asosiy brend aksenti: tugmalar, faol tab, havolalar.
  ///
  /// Nomi tarixiy — dastlab ko'k edi, endi logoga mos qizil. Nom
  /// o'zgartirilmadi, chunki 70+ joyda ishlatiladi.
  final Color blue;

  /// Muvaffaqiyat, ijobiy, "sizdan qarz".
  final Color green;

  /// "Hero" kartalar uchun gradient — mavjud tokenlardan tashkil topgan.
  final LinearGradient gradient;

  /// Shimmer (skeleton loading) asosiy rangi.
  final Color shimmerBase;

  /// Shimmer yorug' chizig'i.
  final Color shimmerHighlight;

  // --- Glassmorphism ---------------------------------------------------------

  /// Sahifa foni — shisha kartalar ostidagi yumshoq gradient.
  final LinearGradient backgroundGradient;

  /// Fondagi xira rangli dog'lar (shisha effekti shular ustida ko'rinadi).
  final Color glowPrimary;
  final Color glowSecondary;

  /// Shisha karta to'ldirishi — yarim shaffof.
  final Color glassFill;

  /// Shisha karta chetidagi yorug' chiziq.
  final Color glassBorder;

  /// Shisha karta soyasi.
  final Color glassShadow;

  // --- Light ---------------------------------------------------------------
  static const Color _lightBackground = Color(0xFFFFFFFF);
  static const Color _lightInputColor = Color(0xFFF7F6FB);
  static const Color _lightGray = Color(0xFFFAFAFA);
  static const Color _lightBorderGray = Color(0xFFEEEEEE);
  static const Color _textGray = Color(0xFF9CA3AF);
  static const Color _favoriteGray = Color(0xFFD9D9D9);
  static const Color _lightBottomNavBlue = Color(0xFF677294);
  static const Color _navy = Color(0xFF2F2E41);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _lightYellow = Color(0xFFFFCC00);

  // --- Dark ----------------------------------------------------------------
  static const Color _darkBackground = Color(0xFF1E1E1E);
  static const Color _darkInputColor = Color(0xFF2A3037);
  static const Color _darkBorderGray = Color(0xFF313740);
  static const Color _darkYellow = Color(0xFFFFEE02);

  // --- Aksent ustidagi ranglar ---------------------------------------------
  // Bular `static const`: gradient/blue/red fon har doim to'q bo'lgani uchun
  // ikkala mavzuda ham bir xil qoladi, shu bilan birga `const` widget'lar
  // ichida ishlatilishi mumkin (PROJECT.md 10.3 — rang hardcode qilinmaydi).

  /// Gradient yoki to'yingan aksent ustidagi asosiy matn/ikonka.
  static const Color onAccent = _white;

  /// Aksent ustidagi ikkinchi darajali matn (oq, 70%).
  static const Color onAccentMuted = Color(0xB3FFFFFF);

  /// Aksent ustidagi yengil qatlam: badge foni, progress track (oq, 18%).
  static const Color onAccentOverlay = Color(0x2EFFFFFF);

  /// Rasmni to'liq ekranda ko'rish foni.
  static const Color viewerBackground = Color(0xFF000000);

  // --- Har ikkala mavzuda bir xil ------------------------------------------
  static const Color _red = Color(0xFFF55556);
  static const Color _green = Color(0xFF46E180);

  /// Brend qizili — logodagi qizildan biroz yumshoqroq, ko'zni charchatmaydi.
  static const Color _brand = Color(0xFFEE1C25);

  static const CustomTheme light = CustomTheme(
    background: _lightBackground,
    inputColor: _lightInputColor,
    gray: _lightGray,
    borderGray: _lightBorderGray,
    textGray: _textGray,
    favoriteGray: _favoriteGray,
    bottomNavBg: _lightBackground,
    bottomNavBlue: _lightBottomNavBlue,
    mainDarkBlue: _navy,
    textMainDarkBlue: _white,
    yellow: _lightYellow,
    red: _red,
    blue: _brand,
    green: _green,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFFF3B42), _brand],
    ),
    shimmerBase: _lightBorderGray,
    shimmerHighlight: _lightGray,
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFFFE1E4), Color(0xFFFFF0F1), Color(0xFFE9E3FF)],
    ),
    glowPrimary: Color(0x73FF7A85),
    glowSecondary: Color(0x8C8B7CF6),
    glassFill: Color(0x73FFFFFF),
    glassBorder: Color(0xB3FFFFFF),
    glassShadow: Color(0x1F8A1C24),
  );

  static const CustomTheme dark = CustomTheme(
    background: _darkBackground,
    inputColor: _darkInputColor,
    gray: _darkInputColor,
    borderGray: _darkBorderGray,
    textGray: _textGray,
    favoriteGray: _favoriteGray,
    bottomNavBg: _darkInputColor,
    bottomNavBlue: _textGray,
    mainDarkBlue: _white,
    textMainDarkBlue: _navy,
    yellow: _darkYellow,
    red: _red,
    blue: _brand,
    green: _green,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFFFF3B42), Color(0xFFD9141D)],
    ),
    shimmerBase: _darkInputColor,
    shimmerHighlight: _darkBorderGray,
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFF241316), Color(0xFF141216), Color(0xFF1A1530)],
    ),
    glowPrimary: Color(0x59FF3B42),
    glowSecondary: Color(0x738B7CF6),
    glassFill: Color(0x1AFFFFFF),
    glassBorder: Color(0x33FFFFFF),
    glassShadow: Color(0x66000000),
  );

  @override
  CustomTheme copyWith({
    Color? background,
    Color? inputColor,
    Color? gray,
    Color? borderGray,
    Color? textGray,
    Color? favoriteGray,
    Color? bottomNavBg,
    Color? bottomNavBlue,
    Color? mainDarkBlue,
    Color? textMainDarkBlue,
    Color? yellow,
    Color? red,
    Color? blue,
    Color? green,
    LinearGradient? gradient,
    Color? shimmerBase,
    Color? shimmerHighlight,
    LinearGradient? backgroundGradient,
    Color? glowPrimary,
    Color? glowSecondary,
    Color? glassFill,
    Color? glassBorder,
    Color? glassShadow,
  }) {
    return CustomTheme(
      background: background ?? this.background,
      inputColor: inputColor ?? this.inputColor,
      gray: gray ?? this.gray,
      borderGray: borderGray ?? this.borderGray,
      textGray: textGray ?? this.textGray,
      favoriteGray: favoriteGray ?? this.favoriteGray,
      bottomNavBg: bottomNavBg ?? this.bottomNavBg,
      bottomNavBlue: bottomNavBlue ?? this.bottomNavBlue,
      mainDarkBlue: mainDarkBlue ?? this.mainDarkBlue,
      textMainDarkBlue: textMainDarkBlue ?? this.textMainDarkBlue,
      yellow: yellow ?? this.yellow,
      red: red ?? this.red,
      blue: blue ?? this.blue,
      green: green ?? this.green,
      gradient: gradient ?? this.gradient,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      glowPrimary: glowPrimary ?? this.glowPrimary,
      glowSecondary: glowSecondary ?? this.glowSecondary,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      glassShadow: glassShadow ?? this.glassShadow,
    );
  }

  @override
  CustomTheme lerp(covariant ThemeExtension<CustomTheme>? other, double t) {
    if (other is! CustomTheme) return this;
    return CustomTheme(
      background: Color.lerp(background, other.background, t)!,
      inputColor: Color.lerp(inputColor, other.inputColor, t)!,
      gray: Color.lerp(gray, other.gray, t)!,
      borderGray: Color.lerp(borderGray, other.borderGray, t)!,
      textGray: Color.lerp(textGray, other.textGray, t)!,
      favoriteGray: Color.lerp(favoriteGray, other.favoriteGray, t)!,
      bottomNavBg: Color.lerp(bottomNavBg, other.bottomNavBg, t)!,
      bottomNavBlue: Color.lerp(bottomNavBlue, other.bottomNavBlue, t)!,
      mainDarkBlue: Color.lerp(mainDarkBlue, other.mainDarkBlue, t)!,
      textMainDarkBlue: Color.lerp(
        textMainDarkBlue,
        other.textMainDarkBlue,
        t,
      )!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      red: Color.lerp(red, other.red, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      green: Color.lerp(green, other.green, t)!,
      gradient: LinearGradient.lerp(gradient, other.gradient, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
      backgroundGradient: LinearGradient.lerp(
        backgroundGradient,
        other.backgroundGradient,
        t,
      )!,
      glowPrimary: Color.lerp(glowPrimary, other.glowPrimary, t)!,
      glowSecondary: Color.lerp(glowSecondary, other.glowSecondary, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
    );
  }
}

/// Burchak radiuslari — butun ilovada faqat shu to'rttasi ishlatiladi.
abstract final class AppRadius {
  /// Kichik elementlar: chip, badge, ikonka foni.
  static const double sm = 12;

  /// Tugma, input, ro'yxat qatori.
  static const double md = 16;

  /// Karta.
  static const double lg = 22;

  /// Bottom sheet, katta "hero" karta.
  static const double xl = 28;
}

/// `AppTheme.light` / `AppTheme.dark` — `MaterialApp`ga beriladigan mavzular.
abstract final class AppTheme {
  /// Butun ilova shrifti — `google_fonts` orqali olinadi.
  ///
  /// PROJECT.md'da Gilroy ko'rsatilgan, lekin u tijoriy shrift va Google
  /// Fonts'da mavjud emas. **Plus Jakarta Sans** — unga eng yaqin bepul
  /// geometrik shrift. Boshqa shriftga o'tish uchun faqat shu ikkita
  /// metodni o'zgartirish kifoya (masalan `GoogleFonts.poppins`).
  static TextStyle fontStyle() => GoogleFonts.plusJakartaSans();

  static TextTheme fontTextTheme(TextTheme base) =>
      GoogleFonts.plusJakartaSansTextTheme(base);

  /// Kod/buyruq matnlari uchun monoshrift.
  static TextStyle monoStyle() => GoogleFonts.robotoMono();

  // `static final` — bir marta quriladi. Getter bo'lganda MaterialApp'ning
  // har build'ida yangi ThemeData yasalib, keraksiz qayta chizish bo'lardi.
  static final ThemeData light = _build(CustomTheme.light, Brightness.light);

  static final ThemeData dark = _build(CustomTheme.dark, Brightness.dark);

  static ThemeData _build(CustomTheme c, Brightness brightness) {
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: c.blue,
      onPrimary: CustomTheme._white,
      secondary: c.green,
      onSecondary: CustomTheme._navy,
      error: c.red,
      onError: CustomTheme._white,
      surface: c.background,
      onSurface: c.mainDarkBlue,
    );

    final TextStyle base = fontStyle();
    final TextTheme textTheme = _typeScale(
      fontTextTheme(
        ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: c.mainDarkBlue,
          displayColor: c.mainDarkBlue,
        ),
      ),
      c,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // Aniq TextStyle beruvchi widget'lar ham shu shriftga tayanishi uchun.
      fontFamily: base.fontFamily,
      fontFamilyFallback: base.fontFamilyFallback,
      colorScheme: scheme,
      // Shaffof: sahifa fonini `GlassPageTransitionsBuilder` chizadi
      // (gradient + dog'lar), shisha kartalar shu fon ustida ko'rinadi.
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: GlassPageTransitionsBuilder(
            CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.android: GlassPageTransitionsBuilder(
            ZoomPageTransitionsBuilder(),
          ),
        },
      ),
      canvasColor: c.background,
      dividerColor: c.borderGray,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      appBarTheme: AppBarTheme(
        // Shaffof — ostidagi sahifa foni ko'rinadi.
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.mainDarkBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: c.glassFill,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.glassBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputColor,
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textGray),
        errorStyle: textTheme.labelSmall?.copyWith(color: c.red),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.red, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bottomNavBg,
        selectedItemColor: c.blue,
        unselectedItemColor: c.bottomNavBlue,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.mainDarkBlue,
        contentTextStyle: textTheme.labelLarge?.copyWith(
          color: c.textMainDarkBlue,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.blue,
        linearTrackColor: c.borderGray,
      ),
    );
  }

  /// Yagona shrift shkalasi. Ekranlar o'lchamni qo'lda yozmasdan
  /// `context.text.titleMedium` kabi shu darajalardan foydalanadi.
  ///
  /// | Daraja          | O'lcham | Vazifasi                               |
  /// |-----------------|---------|----------------------------------------|
  /// | displaySmall    | 32 w700 | Asosiy raqam (oylik, taymer)            |
  /// | headlineSmall   | 24 w700 | Ekran sarlavhasi                        |
  /// | titleLarge      | 20 w700 | Karta ichidagi katta qiymat             |
  /// | titleMedium     | 17 w600 | AppBar, bo'lim sarlavhasi               |
  /// | titleSmall      | 15 w600 | Ro'yxat qatori sarlavhasi               |
  /// | bodyLarge       | 16 w500 | Kiritilgan matn                         |
  /// | bodyMedium      | 15 w400 | Oddiy matn, hint                        |
  /// | bodySmall       | 13 w400 | Ikkinchi darajali matn (kulrang)        |
  /// | labelLarge      | 15 w600 | Tugma yozuvi                            |
  /// | labelMedium     | 13 w600 | Input yorlig'i, chip                    |
  /// | labelSmall      | 12 w500 | Eng kichik matn — undan kichigi yo'q    |
  static TextTheme _typeScale(TextTheme t, CustomTheme c) {
    TextStyle? s(
      TextStyle? style,
      double size,
      FontWeight weight, {
      double height = 1.3,
      double letterSpacing = 0,
      Color? color,
    }) => style?.copyWith(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? c.mainDarkBlue,
      // Raqamlar bir xil kenglikda — summa va taymer "sakramaydi".
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    return t.copyWith(
      displaySmall: s(
        t.displaySmall,
        32,
        FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.8,
      ),
      headlineSmall: s(
        t.headlineSmall,
        24,
        FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      titleLarge: s(
        t.titleLarge,
        20,
        FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
      ),
      titleMedium: s(t.titleMedium, 17, FontWeight.w600, letterSpacing: -0.2),
      titleSmall: s(t.titleSmall, 15, FontWeight.w600),
      bodyLarge: s(t.bodyLarge, 16, FontWeight.w500, height: 1.4),
      bodyMedium: s(t.bodyMedium, 15, FontWeight.w400, height: 1.45),
      bodySmall: s(
        t.bodySmall,
        13,
        FontWeight.w400,
        height: 1.4,
        color: c.textGray,
      ),
      labelLarge: s(t.labelLarge, 15, FontWeight.w600, letterSpacing: 0.1),
      labelMedium: s(t.labelMedium, 13, FontWeight.w600),
      labelSmall: s(t.labelSmall, 12, FontWeight.w500, color: c.textGray),
    );
  }
}

/// `context.text.titleMedium` — shrift shkalasiga qisqa murojaat.
extension AppTextX on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}

/// `context.theme.blue` ko'rinishida ranglarga murojaat qilish uchun.
extension CustomThemeX on BuildContext {
  CustomTheme get theme => Theme.of(this).extension<CustomTheme>()!;
}
