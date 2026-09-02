import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Ilova bo'ylab yagona ko'rinishdagi karta konteyneri.
///
/// Ishlatilishi: Home, Hisobot, Qarzlar, Profil ekranlari.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 20,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return Material(
      color: theme.background,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: showBorder
                ? Border.all(color: theme.borderGray)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
