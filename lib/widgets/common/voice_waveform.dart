import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Mikrofon darajasiga qarab harakatlanadigan to'lqin.
///
/// Foydalanuvchi ilova uni **eshitayotganini** ko'rib turishi kerak —
/// aks holda "gapiryapman, lekin nimadir bo'lyaptimi?" degan noaniqlik
/// qoladi. Chiziqlar haqiqiy `onSoundLevelChange` qiymatiga bog'langan.
class VoiceWaveform extends StatefulWidget {
  const VoiceWaveform({
    super.key,
    required this.level,
    this.barCount = 7,
    this.height = 74,
    this.color,
  });

  /// `speech_to_text` beradigan xom daraja (taxminan -2 … 10).
  final double level;

  final int barCount;
  final double height;
  final Color? color;

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Xom darajani 0.0 – 1.0 oralig'iga keltiradi.
  double get _normalized {
    final double clamped = widget.level.clamp(0.0, 10.0);
    return (clamped / 10).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Color accent = widget.color ?? theme.blue;
    final double amplitude = _normalized;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(widget.barCount, (int index) {
              // Har bir chiziq o'z fazasida tebranadi — jonli ko'rinadi.
              final double phase =
                  (_controller.value * 2 * math.pi) + index * 0.8;
              final double wave = (math.sin(phase) + 1) / 2;

              // Markazdagi chiziqlar balandroq.
              final double centerBias = 1 -
                  ((index - (widget.barCount - 1) / 2).abs() /
                      ((widget.barCount - 1) / 2)) *
                      0.45;

              final double minHeight = widget.height * 0.12;
              final double barHeight = minHeight +
                  widget.height * 0.78 * amplitude * centerBias *
                      (0.55 + 0.45 * wave);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 110),
                  curve: Curves.easeOut,
                  width: 6,
                  height: barHeight.clamp(minHeight, widget.height),
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: 0.45 + 0.55 * amplitude,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
