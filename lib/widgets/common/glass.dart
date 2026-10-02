import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Har bir sahifa ostidagi yumshoq gradient fon.
///
/// Shisha kartalar shu fon ustida "muzli shisha" bo'lib ko'rinadi. Dog'lar
/// `ImageFilter.blur` emas, radial gradient bilan chizilgan — telefonni
/// og'irlashtirmaydi.
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
          // Uchta katta nur: shisha kartalar ortida rang tovlanishi
          // ko'rinishi uchun ataylab ekran ichiga kirib turadi.
          Positioned(
            top: -90,
            right: -110,
            child: _Glow(color: theme.glowPrimary, size: 420),
          ),
          Positioned(
            top: 260,
            left: -170,
            child: _Glow(color: theme.glowSecondary, size: 380),
          ),
          Positioned(
            bottom: -120,
            right: -90,
            child: _Glow(color: theme.glowPrimary, size: 340),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

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
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Haqiqiy blur'li shisha panel — faqat bir nechta asosiy joyda
/// (pastki menyu, bosh kartalar, bottom sheet). Ro'yxatlardagi har bir
/// kartada ishlatilmaydi: `BackdropFilter` qimmat amal.
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
    final CustomTheme theme = context.theme;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.glassFill,
            borderRadius: borderRadius,
            border: showBorder ? Border.all(color: theme.glassBorder) : null,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
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
