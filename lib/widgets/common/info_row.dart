import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';

/// Ma'lumot qatori: ikonka, yorliq, qiymat va strelka.
///
/// Ishlatilishi: Profil ekrani va "Barcha ma'lumotlar" ekrani — ikkalasida
/// bir xil ko'rinish bo'lishi uchun umumiy widget.
class InfoRow extends ConsumerWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// `null` bo'lsa qator bosilmaydi (faqat ko'rsatish uchun).
  final void Function(WidgetRef ref)? onTap;

  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CustomTheme theme = context.theme;

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(ref),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 17, color: theme.textGray),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: TextStyle(fontSize: 11, color: theme.textGray),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.mainDarkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    BootstrapIcons.chevron_right,
                    size: 13,
                    color: theme.favoriteGray,
                  ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              color: theme.borderGray,
              height: 1,
              indent: 45,
              endIndent: 16,
            ),
        ],
      ),
    );
  }
}
