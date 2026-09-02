import 'package:flutter/material.dart';

import '../../../widgets/common/app_text_field.dart';
import 'onboarding_step.dart';

/// 2-qadam: ism-familiya (matn kiritish).
class TextInputStep extends StatelessWidget {
  const TextInputStep({
    super.key,
    required this.title,
    this.subtitle,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.textCapitalization = TextCapitalization.words,
  });

  final String title;
  final String? subtitle;
  final TextEditingController controller;
  final String hint;
  final void Function(String)? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return OnboardingStep(
      title: title,
      subtitle: subtitle,
      child: AppTextField(
        controller: controller,
        hint: hint,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
      ),
    );
  }
}
