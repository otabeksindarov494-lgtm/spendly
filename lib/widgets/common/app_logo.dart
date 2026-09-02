import 'package:flutter/material.dart';

/// Spendly logotipi (`assets/logo.png`).
///
/// Ishlatilishi: splash ekrani, Login ekrani, onboarding "Xush kelibsiz".
/// Launcher ikonkasi ham shu logodan generatsiya qilinadi
/// (`flutter_launcher_icons`, `assets/icon/`).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
