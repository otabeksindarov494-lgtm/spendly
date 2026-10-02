import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Har bir sahifa ostidagi toza neytral gradient fon.
///
/// Rangli nurlar ataylab yo'q (foydalanuvchi so'rovi) — shisha ko'rinishi
/// yarim shaffof oq qatlam, yorug' chegara, yumshoq soya va blur'dan keladi.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.theme.backgroundGradient),
      child: child,
    );
  }
}

/// Haqiqiy blur'li shisha panel — faqat bir nechta asosiy joyda
/// (bosh kartalar, forma paneli). Ro'yxatlardagi har bir kartada
/// ishlatilmaydi: `BackdropFilter` qimmat amal.
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

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.glassShadow,
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
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
