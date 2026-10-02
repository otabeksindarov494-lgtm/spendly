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
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.mainDarkBlue,
              height: 1.25,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: theme.textGray,
                height: 1.45,
              ),
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
