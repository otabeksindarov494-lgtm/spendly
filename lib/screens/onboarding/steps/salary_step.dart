import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/app_text_field.dart';
import 'onboarding_step.dart';

/// 5-qadam: oylik maosh miqdori.
class SalaryStep extends StatelessWidget {
  const SalaryStep({
    super.key,
    required this.controller,
    required this.currency,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String currency;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return OnboardingStep(
      title: 'Oylik maoshingiz qancha?',
      subtitle: 'Kunlik va soatlik stavka shu summadan hisoblanadi.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppTextField(
            controller: controller,
            hint: 'Oylik summasi',
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            inputFormatters: const <TextInputFormatter>[ThousandsFormatter()],
            suffix: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Align(
                widthFactor: 1,
                child: Text(
                  currency,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textGray,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
