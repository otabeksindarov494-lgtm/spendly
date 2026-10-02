import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_logo.dart';

/// 1-qadam: xush kelibsiz ekrani.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  static const List<(IconData, String, String)> _features =
      <(IconData, String, String)>[
        (
          IconsaxPlusLinear.camera,
          'Selfie bilan davomat',
          'Ishga kelish va ketish vaqtini rasm bilan qayd eting',
        ),
        (
          IconsaxPlusLinear.calculator,
          'Avtomatik maosh',
          'Kechikish va erta ketish jarimalari o\'zi hisoblanadi',
        ),
        (
          IconsaxPlusLinear.microphone_2,
          'Ovoz orqali qarz',
          'Gapirib ayting — qarz o\'zi yozib olinadi',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 24),
          const AppLogo(size: 72),
          const SizedBox(height: 24),
          Text('Spendly\'ga xush kelibsiz', style: context.text.displaySmall),
          const SizedBox(height: 10),
          Text(
            'Ish vaqtingizni kuzating, maoshingizni avtomatik hisoblang '
            'va qarzlaringizni bir joyda saqlang.',
            style: context.text.bodyMedium?.copyWith(color: theme.textGray),
          ),
          const SizedBox(height: 28),
          for (final (IconData icon, String title, String body) feature
              in _features)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              // Har bir imkoniyat — alohida shisha karta.
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(feature.$1, size: 26, color: theme.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(feature.$2, style: context.text.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            feature.$3,
                            style: context.text.bodyMedium?.copyWith(
                              height: 1.4,
                              color: theme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
