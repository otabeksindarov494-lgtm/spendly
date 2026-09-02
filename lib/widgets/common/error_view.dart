import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_button.dart';

/// Xatolikni ko'rsatish (PROJECT.md 7-bosqich, error handling).
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(BootstrapIcons.exclamation_circle, size: 36, color: theme.red),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: theme.textGray),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: 16),
            AppButton(
              label: 'Qayta urinish',
              variant: AppButtonVariant.secondary,
              expanded: false,
              height: 44,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
