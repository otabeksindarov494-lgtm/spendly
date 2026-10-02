import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// Asosiy aksent, tugmalar.
  final Color blue;

  /// Muvaffaqiyat, ijobiy, "sizdan qarz".
  final Color green;

  /// "Hero" kartalar uchun gradient — mavjud tokenlardan tashkil topgan.
  final LinearGradient gradient;

  /// Shimmer (skeleton loading) asosiy rangi.
  final Color shimmerBase;

  /// Shimmer yorug' chizig'i.
  final Color shimmerHighlight;

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
  static const Color _blue = Color(0xFF3083FF);
  static const Color _green = Color(0xFF46E180);

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
    blue: _blue,
    green: _green,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[_blue, _navy],
    ),
    shimmerBase: _lightBorderGray,
    shimmerHighlight: _lightGray,
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
    blue: _blue,
    green: _green,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[_blue, _darkInputColor],
    ),
    shimmerBase: _darkInputColor,
    shimmerHighlight: _darkBorderGray,
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
      textMainDarkBlue:
          Color.lerp(textMainDarkBlue, other.textMainDarkBlue, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      red: Color.lerp(red, other.red, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      green: Color.lerp(green, other.green, t)!,
      gradient: LinearGradient.lerp(gradient, other.gradient, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight:
          Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

/// `AppTheme.light` / `AppTheme.dark` — `MaterialApp`ga beriladigan mavzular.
abstract final class AppTheme {
  /// Butun ilova shrifti — `google_fonts` orqali olinadi.
  ///
  /// PROJECT.md'da Gilroy ko'rsatilgan, lekin u tijoriy shrift va Google
  /// Fonts'da mavjud emas. Foydalanuvchi tanlovi bilan **Inter** ishlatiladi.
  /// Boshqa shriftga o'tish uchun faqat shu ikkita metodni o'zgartirish
  /// kifoya (masalan `GoogleFonts.poppins`).
  static TextStyle fontStyle() => GoogleFonts.inter();

  static TextTheme fontTextTheme(TextTheme base) =>
      GoogleFonts.interTextTheme(base);

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
    final TextTheme textTheme = fontTextTheme(
      ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: c.mainDarkBlue,
            displayColor: c.mainDarkBlue,
          ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // Aniq TextStyle beruvchi widget'lar ham shu shriftga tayanishi uchun.
      fontFamily: base.fontFamily,
      fontFamilyFallback: base.fontFamilyFallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.inputColor,
      canvasColor: c.background,
      dividerColor: c.borderGray,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.inputColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.mainDarkBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: c.mainDarkBlue,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputColor,
        hintStyle: TextStyle(fontSize: 13, color: c.textGray),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.mainDarkBlue,
        contentTextStyle: TextStyle(color: c.textMainDarkBlue),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.blue,
        linearTrackColor: c.borderGray,
      ),
    );
  }
}

/// `context.theme.blue` ko'rinishida ranglarga murojaat qilish uchun.
extension CustomThemeX on BuildContext {
  CustomTheme get theme => Theme.of(this).extension<CustomTheme>()!;
}
