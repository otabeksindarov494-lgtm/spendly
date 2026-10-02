import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/debt_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

/// Qarz ma'lumotlarini kiritish/tahrirlash formasi.
///
/// Ikkala joyda ishlatiladi:
///  * `ManualDebtSheet` — qo'lda kiritish,
///  * `VoiceDebtSheet` — ovozdan olingan natijani tasdiqlash
///    (PROJECT.md 10.8: tasdiqlash ekranisiz saqlanmaydi).
class DebtForm extends StatefulWidget {
  const DebtForm({
    super.key,
    this.initialName,
    this.initialAmount,
    this.initialType,
    this.initialDescription,
    required this.submitLabel,
    required this.onSubmit,
    this.isSaving = false,
  });

  final String? initialName;
  final double? initialAmount;
  final DebtType? initialType;
  final String? initialDescription;
  final String submitLabel;
  final bool isSaving;

  final void Function({
    required String personName,
    required double amount,
    required DebtType type,
    String? description,
  })
  onSubmit;

  @override
  State<DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends State<DebtForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late DebtType _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _amountController = TextEditingController(
      text: widget.initialAmount == null
          ? ''
          : _formatInitialAmount(widget.initialAmount!),
    );
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    // Ovozdan yo'nalish aniqlanmagan bo'lsa, xavfsiz standart tanlanadi
    // va foydalanuvchi uni ko'rib chiqadi.
    _type = widget.initialType ?? DebtType.iOwe;
  }

  static String _formatInitialAmount(double amount) {
    final String digits = amount.round().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      personName: _nameController.text,
      amount: ThousandsFormatter.parse(_amountController.text),
      type: _type,
      description: _descriptionController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            controller: _nameController,
            label: 'Ism',
            hint: 'Masalan: Alisher',
            prefixIcon: IconsaxPlusLinear.user,
            textCapitalization: TextCapitalization.words,
            validator: (String? value) =>
                (value ?? '').trim().isEmpty ? 'Ismni kiriting' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _amountController,
            label: 'Summa',
            hint: '30 000',
            prefixIcon: IconsaxPlusLinear.moneys,
            keyboardType: TextInputType.number,
            inputFormatters: const <TextInputFormatter>[ThousandsFormatter()],
            validator: (String? value) =>
                ThousandsFormatter.parse(value ?? '') <= 0
                ? 'Summani kiriting'
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Turi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textGray,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _TypeOption(
                  label: 'Men qarzdorman',
                  color: theme.red,
                  isSelected: _type == DebtType.iOwe,
                  onTap: () => setState(() => _type = DebtType.iOwe),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TypeOption(
                  label: 'Menga qarz',
                  color: theme.green,
                  isSelected: _type == DebtType.owedToMe,
                  onTap: () => setState(() => _type = DebtType.owedToMe),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _descriptionController,
            label: 'Izoh (ixtiyoriy)',
            hint: 'Nima uchun berilgan?',
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: widget.submitLabel,
            isLoading: widget.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : theme.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? color : theme.borderGray,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              isSelected
                  ? IconsaxPlusBold.record_circle
                  : IconsaxPlusLinear.record,
              size: 18,
              color: isSelected ? color : theme.favoriteGray,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : theme.mainDarkBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
