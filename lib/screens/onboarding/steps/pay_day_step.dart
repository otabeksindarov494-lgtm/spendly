import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'onboarding_step.dart';

/// 9-qadam: maosh beriladigan kun (oyning 1–31 kuni).
class PayDayStep extends StatelessWidget {
  const PayDayStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return OnboardingStep(
      title: 'Maosh oyning nechinchi kuni beriladi?',
      subtitle: 'Masalan, 5-sana.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List<Widget>.generate(31, (int index) {
          final int day = index + 1;
          final bool isSelected = day == selected;

          return GestureDetector(
            onTap: () => onChanged(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? theme.blue : theme.glassFill,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected ? theme.blue : theme.borderGray,
                ),
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? CustomTheme.onAccent : theme.mainDarkBlue,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
