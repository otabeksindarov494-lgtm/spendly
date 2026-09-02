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

    final (Color background, Color foreground, Color? border) = switch (
      variant
    ) {
      AppButtonVariant.primary => (theme.blue, CustomTheme.onAccent, null),
      AppButtonVariant.secondary => (
          theme.background,
          theme.mainDarkBlue,
          theme.borderGray,
        ),
      AppButtonVariant.danger => (theme.red, CustomTheme.onAccent, null),
      AppButtonVariant.text => (Colors.transparent, theme.blue, null),
    };

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
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

    return Opacity(
      opacity: disabled && !isLoading ? 0.5 : 1,
      child: SizedBox(
        width: expanded ? double.infinity : null,
        height: height,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
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
