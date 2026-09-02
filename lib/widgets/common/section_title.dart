import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Bo'lim sarlavhasi, ixtiyoriy o'ng tomondagi harakat bilan.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.mainDarkBlue,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
