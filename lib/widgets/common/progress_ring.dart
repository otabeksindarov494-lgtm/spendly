import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Dumaloq (halqa) progress ko'rsatkichi, markazida qiymat.
///
/// `fl_chart` kabi paket qo'shilmagan — bitta halqa uchun butun grafik
/// kutubxonasini olib kelish ortiqcha. `CustomPainter` yengil va
/// mavzu ranglariga to'liq bo'ysunadi.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.centerLabel,
    required this.centerCaption,
    this.size = 132,
    this.strokeWidth = 11,
    this.color,
  });

  /// 0.0 – 1.0.
  final double value;

  final String centerLabel;
  final String centerCaption;
  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Color accent = color ?? theme.blue;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
        builder: (BuildContext context, double animated, Widget? child) {
          return CustomPaint(
            painter: _RingPainter(
              value: animated,
              trackColor: theme.borderGray,
              progressColor: accent,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    centerLabel,
                    style: TextStyle(
                      fontSize: size * 0.19,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: theme.mainDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    centerCaption,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      // Kamida 12 px — shkalaning eng kichik darajasi.
                      fontSize: size * 0.1 < 12 ? 12 : size * 0.1,
                      height: 1.25,
                      color: theme.textGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double value;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide - strokeWidth) / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint progress = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    if (value > 0) {
      // Yuqoridan boshlab soat yo'nalishi bo'yicha.
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, progress);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.trackColor != trackColor;
}
