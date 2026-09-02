import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import 'onboarding_step.dart';

/// 8-qadam: ish kunlarini tanlash.
///
/// Kunlar `DateTime.weekday` konvensiyasida: 1 = Dushanba … 7 = Yakshanba.
class WorkDaysStep extends StatelessWidget {
  const WorkDaysStep({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final List<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return OnboardingStep(
      title: 'Qaysi kunlar ishlaysiz?',
      subtitle: 'Tanlanmagan kunlarda jarima ham, hisob-kitob ham bo\'lmaydi.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List<Widget>.generate(7, (int index) {
          final int weekday = index + 1;
          final bool isSelected = selected.contains(weekday);

          return GestureDetector(
            onTap: () => onToggle(weekday),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? theme.blue : theme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? theme.blue : theme.borderGray,
                ),
              ),
              child: Text(
                Formatters.weekdaysShort[index],
                style: TextStyle(
                  fontSize: 14,
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
