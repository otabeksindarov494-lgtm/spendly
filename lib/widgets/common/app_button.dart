import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Tugma ko'rinishi.
enum AppButtonVariant { primary, secondary, danger, text }

/// Ilovaning yagona uslubdagi tugmasi.
///
/// Ishlatilishi: Login/Register, Onboarding, Home, Qarzlar, Profil.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final bool disabled = onPressed == null || isLoading;

    final (
      Color background,
      Color foreground,
      Color? border,
    ) = switch (variant) {
      AppButtonVariant.primary => (theme.blue, CustomTheme.onAccent, null),
      AppButtonVariant.secondary => (
        theme.glassFill,
        theme.mainDarkBlue,
        theme.borderGray,
      ),
      AppButtonVariant.danger => (theme.red, CustomTheme.onAccent, null),
      AppButtonVariant.text => (Colors.transparent, theme.blue, null),
    };

    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    final bool isPrimary = variant == AppButtonVariant.primary;

    final Widget content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(color: foreground),
                ),
              ),
            ],
          );

    return Opacity(
      opacity: disabled && !isLoading ? 0.5 : 1,
      child: Container(
        width: expanded ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          // Asosiy tugma: nozik brend gradienti va yumshoq rangli soya.
          gradient: isPrimary ? theme.gradient : null,
          boxShadow: isPrimary && !disabled
              ? <BoxShadow>[
                  BoxShadow(
                    color: theme.blue.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: isPrimary ? Colors.transparent : background,
          borderRadius: radius,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: radius,
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 24),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: border == null ? null : Border.all(color: border),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
