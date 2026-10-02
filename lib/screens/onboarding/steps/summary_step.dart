import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_card.dart';
import 'onboarding_step.dart';

/// Yakuniy tasdiqlash ro'yxatidagi bitta qator.
class SummaryEntry {
  const SummaryEntry({
    required this.label,
    required this.value,
    required this.stepIndex,
    required this.icon,
  });

  final String label;
  final String value;

  /// "Tahrirlash" bosilganda qaysi qadamga qaytish kerakligi.
  final int stepIndex;

  final IconData icon;
}

/// 10-qadam: barcha kiritilgan ma'lumotlarni ko'rish va tasdiqlash.
class SummaryStep extends StatelessWidget {
  const SummaryStep({super.key, required this.entries, required this.onEdit});

  final List<SummaryEntry> entries;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return OnboardingStep(
      title: 'Hammasi to\'g\'rimi?',
      subtitle: 'Har bir qatorni bosib tahrirlashingiz mumkin.',
      child: Column(
        children: <Widget>[
          for (final SummaryEntry entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                onTap: () => onEdit(entry.stepIndex),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(entry.icon, size: 18, color: theme.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            entry.label,
                            style: context.text.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value,
                            style: context.text.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      IconsaxPlusLinear.edit,
                      size: 18,
                      color: theme.favoriteGray,
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
