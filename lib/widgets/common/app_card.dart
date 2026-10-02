import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Ilova bo'ylab yagona ko'rinishdagi karta konteyneri — "shisha" karta.
///
/// Yarim shaffof to'ldirish + yorug' chegara + yumshoq soya. Haqiqiy blur
/// ishlatilmaydi (ro'yxatlarda ko'p karta bo'ladi), gradient fon ustida
/// baribir shisha bo'lib ko'rinadi. Haqiqiy blur kerak bo'lsa — `GlassPanel`.
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
    final CustomTheme theme = context.theme;
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.glassShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: theme.glassFill,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: showBorder ? Border.all(color: theme.glassBorder) : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
