import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_card.dart';
import 'onboarding_step.dart';

/// 3-qadam: tug'ilgan kun (date picker).
class BirthDateStep extends StatelessWidget {
  const BirthDateStep({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return OnboardingStep(
      title: 'Tug\'ilgan kuningiz qachon?',
      subtitle: 'Bu ma\'lumot faqat profilingizda ko\'rinadi.',
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        onTap: () => _pick(context),
        child: Row(
          children: <Widget>[
            Icon(BootstrapIcons.cake2, color: theme.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                value == null
                    ? 'Sanani tanlang'
                    : Formatters.longDate(value!),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: value == null ? theme.textGray : theme.mainDarkBlue,
                ),
              ),
            ),
            Icon(BootstrapIcons.chevron_right, color: theme.textGray),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Tug\'ilgan kuningiz',
      cancelText: 'Bekor qilish',
      confirmText: 'Tanlash',
    );
    if (picked != null) onChanged(picked);
  }
}
