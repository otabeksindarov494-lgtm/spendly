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

/// O'zbekiston telefon raqamini yozish paytida guruhlaydi:
/// "901234567" → "+998 90 123 45 67".
///
/// "+998" ni foydalanuvchi yozmasa ham o'zi qo'shiladi; to'liq raqam
/// (998 bilan) qo'yilsa ham to'g'ri chiqadi. Oxirgi raqam o'chirilganda
/// maydon butunlay tozalanadi — "+998" da tiqilib qolmaydi.
class UzPhoneFormatter extends TextInputFormatter {
  const UzPhoneFormatter();

  /// Mahalliy raqam guruhlari: operator kodi (2) + 3 + 2 + 2.
  static const List<int> _groups = <int>[2, 3, 2, 2];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String formatted = format(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String format(String input) {
    String digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('998')) digits = digits.substring(3);
    if (digits.isEmpty) return '';
    if (digits.length > 9) digits = digits.substring(0, 9);

    final StringBuffer buffer = StringBuffer('+998');
    int start = 0;
    for (final int size in _groups) {
      if (start >= digits.length) break;
      final int end = start + size > digits.length
          ? digits.length
          : start + size;
      buffer
        ..write(' ')
        ..write(digits.substring(start, end));
      start = end;
    }
    return buffer.toString();
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
