import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Har bir onboarding qadami uchun umumiy sarlavha + kontent joylashuvi.
///
/// Ishlatilishi: `steps/` papkasidagi barcha qadamlar.
class OnboardingStep extends StatelessWidget {
  const OnboardingStep({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 24),
          Text(title, style: context.text.headlineSmall),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: context.text.bodyMedium?.copyWith(color: theme.textGray),
            ),
          ],
          const SizedBox(height: 28),
          child,
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
