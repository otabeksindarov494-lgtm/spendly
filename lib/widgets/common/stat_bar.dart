import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Yorliq va qiymatli chiziqli progress qatori.
///
/// Ishlatilishi: Bosh sahifadagi statistika bloki.
class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    this.color,
  });

  final String label;

  /// O'ng tomonda ko'rinadigan matn (masalan "142 soat").
  final String value;

  /// 0.0 – 1.0.
  final double progress;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Color accent = color ?? theme.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: theme.textGray),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.mainDarkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
              builder: (BuildContext context, double animated, Widget? child) =>
                  LinearProgressIndicator(
                    value: animated,
                    minHeight: 7,
                    backgroundColor: theme.borderGray,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
