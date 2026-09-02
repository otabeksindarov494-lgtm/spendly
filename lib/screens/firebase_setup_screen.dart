import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';

/// Firebase ulanmaganda ko'rsatiladigan ko'rsatma ekrani.
///
/// Oq ekran yoki tushunarsiz crash o'rniga aniq qadamlar ko'rsatiladi.
class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, required this.error});

  final String error;

  static const String _command = 'flutterfire configure';

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 24),
              Icon(BootstrapIcons.cloud_slash, size: 44, color: theme.yellow),
              const SizedBox(height: 20),
              Text(
                'Firebase sozlanmagan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.mainDarkBlue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ilova ishlashi uchun Firebase loyihasiga ulanishi kerak. '
                'Terminalda loyiha papkasida quyidagilarni bajaring:',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.inputColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _CodeLine(
                      text: 'dart pub global activate flutterfire_cli',
                    ),
                    SizedBox(height: 8),
                    _CodeLine(text: _command),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bu buyruq lib/firebase_options.dart faylini haqiqiy kalitlar '
                'bilan qayta yozadi va platforma sozlamalarini qo\'shadi. '
                'Firebase konsolida Authentication (Email/Parol) va Cloud '
                'Firestore yoqilgan bo\'lishi kerak.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Buyruqni nusxalash',
                icon: BootstrapIcons.copy,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: _command),
                  );
                },
              ),
              const SizedBox(height: 28),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                shape: const Border(),
                collapsedShape: const Border(),
                // M3 sukut bo'yicha ochilganda kulrang fon beradi — bu
                // sahifadagi tekis fonni buzadi.
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                title: Text(
                  'Texnik tafsilot',
                  style: TextStyle(fontSize: 12, color: theme.textGray),
                ),
                children: <Widget>[
                  Text(
                    error,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textGray,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.monoStyle().copyWith(
        fontSize: 12,
        color: context.theme.mainDarkBlue,
      ),
    );
  }
}
