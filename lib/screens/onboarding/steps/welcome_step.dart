import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_logo.dart';

/// 1-qadam: xush kelibsiz ekrani.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  static const List<(IconData, String, String)> _features =
      <(IconData, String, String)>[
    (
      BootstrapIcons.camera,
      'Selfie bilan davomat',
      'Ishga kelish va ketish vaqtini rasm bilan qayd eting',
    ),
    (
      BootstrapIcons.calculator,
      'Avtomatik maosh',
      'Kechikish va erta ketish jarimalari o\'zi hisoblanadi',
    ),
    (
      BootstrapIcons.mic,
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
          const SizedBox(height: 32),
          const AppLogo(size: 88),
          const SizedBox(height: 28),
          Text(
            'Spendly\'ga xush kelibsiz',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: theme.mainDarkBlue,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ish vaqtingizni kuzating, maoshingizni avtomatik hisoblang '
            'va qarzlaringizni bir joyda saqlang.',
            style: TextStyle(
              fontSize: 14,
              color: theme.textGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          for (final (IconData icon, String title, String body) feature
              in _features)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(feature.$1, size: 20, color: theme.blue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          feature.$2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.mainDarkBlue,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          feature.$3,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textGray,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
