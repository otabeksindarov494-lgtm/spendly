import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_card.dart';

/// Profil ekranidagi katta bosiladigan karta.
///
/// Ishlatilishi: Barcha ma'lumotlar, Davomat, Sozlamalar, Chiqish.
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Berilmasa mavzudagi `blue`.
  final Color? accentColor;

  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Color accent = accentColor ?? theme.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: context.text.titleSmall?.copyWith(
                      color: accentColor == null ? theme.mainDarkBlue : accent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: context.text.bodySmall),
                ],
              ),
            ),
            if (showChevron) ...<Widget>[
              const SizedBox(width: 8),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 16,
                color: theme.textGray,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
