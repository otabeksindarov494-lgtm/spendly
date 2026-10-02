import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Har bir sahifa ostidagi fon: neytral gradient, rangsiz "kumush"
/// shakllar va ikki burchakdagi dumaloq yalpiz/osmon doiralari.
///
/// Shaffof shisha yuzalar orqali ular xiralashib ko'rinib, "oyna"
/// effektini beradi. Blur emas, radial gradient — tez.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: theme.backgroundGradient),
      child: Stack(
        children: <Widget>[
          // Neytral kumush shakllar — yorug'lik farqi.
          Positioned(
            top: -120,
            left: -100,
            child: _Shape(color: theme.backdropLight, size: 420),
          ),
          Positioned(
            bottom: 160,
            right: -150,
            child: _Shape(color: theme.backdropShade, size: 340),
          ),
          // Ikki burchakdagi dumaloq rangli doiralar: yalpiz yuqori-o'ngda,
          // osmon ko'ki pastki-chapda. Shaffof shisha orqali xiralashib ko'rinadi.
          Positioned(
            top: -70,
            right: -70,
            child: _Orb(color: theme.orbTopRight, size: 260),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _Orb(color: theme.orbBottomLeft, size: 280),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Shape extends StatelessWidget {
  const _Shape({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withValues(alpha: color.a * 0.5),
              color.withValues(alpha: 0),
            ],
            stops: const <double>[0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}

/// Dumaloq rangli doira: markazdan chetning ~60% igacha deyarli to'liq
/// rangda, faqat eng chekkasida yumshoq so'nadi — shaklsiz dog' emas,
/// aniq doira bo'lib ko'rinadi.
class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withValues(alpha: color.a * 0.85),
              color.withValues(alpha: color.a * 0.3),
              color.withValues(alpha: 0),
            ],
            stops: const <double>[0, 0.6, 0.85, 1],
          ),
        ),
      ),
    );
  }
}

/// Liquid Glass uslubidagi shisha yuza.
///
/// - To'ldirish: yuqori-chapdan (yorug'lik tushgan, [CustomTheme.glassFill])
///   pastki-o'ngga (shaffofroq, [CustomTheme.glassFillLow]) gradient.
/// - Qirra: yuqori-chap yaltiroq oq, pastki-o'ng xira — shisha qirrasi aksi.
/// - [blur] > 0 bo'lsa ortidagi narsa haqiqatan xiralashadi
///   (`BackdropFilter` qimmat — faqat asosiy panellarda).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.lg)),
    this.padding = EdgeInsets.zero,
    this.blur = 0,
    this.showShadow = true,
    this.showBorder = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final bool showShadow;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[theme.glassFill, theme.glassFillLow],
        ),
      ),
      child: CustomPaint(
        foregroundPainter: showBorder
            ? _GlassEdgePainter(
                borderRadius: borderRadius,
                light: theme.glassBorder,
                shade: theme.glassEdgeShade,
              )
            : null,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (blur > 0) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: surface,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: showShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: theme.glassShadow,
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: surface),
    );
  }
}

/// Shisha qirrasi: yuqori-chap yaltiroq, pastki-o'ng xira gradient chiziq.
class _GlassEdgePainter extends CustomPainter {
  _GlassEdgePainter({
    required this.borderRadius,
    required this.light,
    required this.shade,
  });

  final BorderRadius borderRadius;
  final Color light;
  final Color shade;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = borderRadius.toRRect(rect).deflate(0.5);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          light,
          light.withValues(alpha: light.a * 0.35),
          shade,
        ],
        stops: const <double>[0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlassEdgePainter old) =>
      old.borderRadius != borderRadius ||
      old.light != light ||
      old.shade != shade;
}

/// Haqiqiy blur'li shisha panel — asosiy joylar uchun (bosh kartalar,
/// forma paneli). [GlassSurface] ustida qurilgan.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.lg)),
    this.padding = EdgeInsets.zero,
    this.blur = 24,
    this.showBorder = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: borderRadius,
      padding: padding,
      blur: blur,
      showBorder: showBorder,
      child: child,
    );
  }
}

/// Har bir sahifani [GlassBackground] bilan o'rab, so'ng platformaning
/// odatiy o'tish animatsiyasini qo'llaydi.
///
/// Shu sabab ekranlar fonni o'zi chizmaydi (`Scaffold` shaffof), lekin
/// sahifa almashganda eski sahifa yangisining ostidan ko'rinib qolmaydi.
class GlassPageTransitionsBuilder extends PageTransitionsBuilder {
  const GlassPageTransitionsBuilder(this.delegate);

  final PageTransitionsBuilder delegate;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return delegate.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      GlassBackground(child: child),
    );
  }
}
