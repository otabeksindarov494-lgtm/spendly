import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import 'onboarding_step.dart';

/// Tushlik tanaffusi (daqiqa).
///
/// Bu qiymat ish soatidan ayiriladi, ya'ni soatlik stavkaga ham ta'sir
/// qiladi: 09:00–18:00 + 1 soat tanaffus = 8 soat ish.
class LunchBreakStep extends StatelessWidget {
  const LunchBreakStep({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  final int minutes;
  final ValueChanged<int> onChanged;

  static const List<int> _presets = <int>[0, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return OnboardingStep(
      title: 'Tushlik tanaffusi qancha?',
      subtitle: 'Bu vaqt ish soatidan ayiriladi va soatlik stavkaga '
          'ta\'sir qiladi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              for (final int preset in _presets)
                GestureDetector(
                  onTap: () => onChanged(preset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: preset == minutes ? theme.blue : theme.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: preset == minutes
                            ? theme.blue
                            : theme.borderGray,
                      ),
                    ),
                    child: Text(
                      preset == 0 ? 'Yo\'q' : Formatters.minutes(preset),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: preset == minutes
                            ? CustomTheme.onAccent
                            : theme.mainDarkBlue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
