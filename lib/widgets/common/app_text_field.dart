import 'package:flutter/cupertino.dart' show cupertinoTextSelectionControls;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Yagona uslubdagi kiritish maydoni.
///
/// Ishlatilishi: Login/Register, Onboarding qadamlari, Qarz formalari,
/// Profil tahrirlash oynalari.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: context.text.labelMedium?.copyWith(
              color: theme.mainDarkBlue.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          maxLines: obscureText ? 1 : maxLines,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          style: context.text.bodyLarge,
          // iOS uslubidagi yumshoq his: yumaloq kursor, Cupertino
          // belgilash menyusi va mavzuga mos klaviatura ko'rinishi.
          cursorColor: theme.blue,
          cursorRadius: const Radius.circular(2),
          cursorWidth: 2,
          selectionControls: cupertinoTextSelectionControls,
          keyboardAppearance: Theme.of(context).brightness,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 20, color: theme.textGray),
            suffixIcon: suffix,
            // Shisha input: yarim shaffof to'ldirish; chegara mavzudan
            // (ko'rinadigan kulrang, fokusda brend rangi).
            fillColor: theme.glassFill,
          ),
        ),
      ],
    );
  }
}

/// Faqat raqam kiritishga ruxsat beruvchi va guruhlab ko'rsatuvchi formatter.
///
/// Foydalanuvchi "5000000" yozsa ekranda "5 000 000" ko'rinadi.
class ThousandsFormatter extends TextInputFormatter {
  const ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final String formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// "5 000 000" → 5000000.
  static double parse(String text) =>
      double.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}
