import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

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
      child: Material(
        color: theme.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.borderGray),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 19, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: accentColor == null
                              ? theme.mainDarkBlue
                              : accent,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: theme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showChevron) ...<Widget>[
                  const SizedBox(width: 8),
                  Icon(
                    IconsaxPlusLinear.arrow_right_3,
                    size: 14,
                    color: theme.favoriteGray,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
