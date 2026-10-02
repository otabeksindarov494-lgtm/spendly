import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import 'onboarding_step.dart';

/// Bitta variantni tanlash uchun qadam.
///
/// Ishlatilishi: maosh turi, valyuta, jarima siyosati — barchasi bir xil
/// ko'rinishda bo'lishi uchun umumiy widget.
class ChoiceStep<T> extends StatelessWidget {
  const ChoiceStep({
    super.key,
    required this.title,
    this.subtitle,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final List<ChoiceOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return OnboardingStep(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: <Widget>[
          for (final ChoiceOption<T> option in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onChanged(option.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: option.value == selected
                        ? theme.blue.withValues(alpha: 0.06)
                        : theme.glassFill,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: option.value == selected
                          ? theme.blue
                          : theme.borderGray,
                      width: option.value == selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        option.value == selected
                            ? IconsaxPlusBold.record_circle
                            : IconsaxPlusLinear.record,
                        size: 18,
                        color: option.value == selected
                            ? theme.blue
                            : theme.favoriteGray,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.mainDarkBlue,
                              ),
                            ),
                            if (option.description != null) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(
                                option.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: theme.textGray,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChoiceOption<T> {
  const ChoiceOption({
    required this.value,
    required this.label,
    this.description,
  });

  final T value;
  final String label;
  final String? description;
}
