import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_logo.dart';

/// 1-qadam: xush kelibsiz ekrani.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  List<(IconData, String, String)> get _features =>
      <(IconData, String, String)>[
        (
          IconsaxPlusLinear.camera,
          'feature_camera_title'.tr(),
          'feature_camera_desc'.tr(),
        ),
        (
          IconsaxPlusLinear.calculator,
          'feature_calculator_title'.tr(),
          'feature_calculator_desc'.tr(),
        ),
        (
          IconsaxPlusLinear.microphone_2,
          'feature_microphone_title'.tr(),
          'feature_microphone_desc'.tr(),
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
          const SizedBox(height: 8),
          const AppLogo(size: 60),
          const SizedBox(height: 20),
          Text('welcome_step_title'.tr(), style: context.text.displaySmall),
          const SizedBox(height: 10),
          Text(
            'welcome_step_desc'.tr(),
            style: context.text.bodyMedium?.copyWith(color: theme.textGray),
          ),
          const SizedBox(height: 22),
          for (final (IconData icon, String title, String body) feature
              in _features)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              // Har bir imkoniyat — alohida shisha karta.
              child: AppCard(
                padding: const EdgeInsets.all(14),
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
