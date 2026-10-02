import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'glass.dart';

/// Ilova bo'ylab yagona ko'rinishdagi karta — Liquid Glass uslubidagi
/// shisha yuza ([GlassSurface]): yorug'lik gradienti, yaltiroq qirra,
/// yumshoq soya.
///
/// Haqiqiy blur ishlatilmaydi (ro'yxatlarda ko'p karta bo'ladi); kerak
/// bo'lsa — `GlassPanel`.
///
/// Ishlatilishi: Home, Hisobot, Qarzlar, Profil ekranlari.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = AppRadius.lg,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return GlassSurface(
      borderRadius: radius,
      showBorder: showBorder,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
