import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common/app_card.dart';
import 'onboarding_step.dart';
import '../../../widgets/common/cupertino_pickers.dart';

/// Sana tanlash qadami.
///
/// Ishlatilishi: tug'ilgan kun va ishga kirgan sana — ikkalasi bir xil
/// ko'rinishda bo'lsin uchun bitta widget.
class DateStep extends StatelessWidget {
  const DateStep({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.initialWhenEmpty,
    this.icon = IconsaxPlusLinear.calendar_1,
    this.emptyLabel = 'Sanani tanlang',
  });

  final String title;
  final String? subtitle;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  /// Qiymat bo'lmaganda date picker qaysi sanadan ochilsin.
  final DateTime? initialWhenEmpty;

  final IconData icon;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return OnboardingStep(
      title: title,
      subtitle: subtitle,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        onTap: () => _pick(context),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: theme.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                value == null ? emptyLabel : Formatters.longDate(value!),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: value == null ? theme.textGray : theme.mainDarkBlue,
                ),
              ),
            ),
            Icon(
              IconsaxPlusLinear.arrow_right_3,
              size: 14,
              color: theme.favoriteGray,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final DateTime? picked = await SoftPickers.pickDate(
      context: context,
      title: title,
      initial: value ?? initialWhenEmpty ?? lastDate,
      first: firstDate,
      last: lastDate,
    );
    if (picked != null) onChanged(picked);
  }
}
