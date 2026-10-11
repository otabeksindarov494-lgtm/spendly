import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/debt_model.dart';
import '../../providers/core_providers.dart';
import '../../theme/app_theme.dart';
import 'debt_form.dart';

/// Qo'lda qarz qo'shish oynasi (PROJECT.md 5.3).
class ManualDebtSheet extends ConsumerStatefulWidget {
  const ManualDebtSheet({super.key, this.existing});

  final Debt? existing;

  static Future<void> show(BuildContext context, {Debt? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => ManualDebtSheet(existing: existing),
    );
  }

  @override
  ConsumerState<ManualDebtSheet> createState() => _ManualDebtSheetState();
}

class _ManualDebtSheetState extends ConsumerState<ManualDebtSheet> {
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _save({
    required String personName,
    required double amount,
    required DebtType type,
    String? description,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(debtServiceProvider);
      if (widget.existing == null) {
        await service.add(
          userId: userId,
          personName: personName,
          amount: amount,
          type: type,
          description: description,
        );
      } else {
        await service.update(
          userId: userId,
          debt: widget.existing!.copyWith(
            personName: personName,
            amount: amount,
            type: type,
            description: description,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'save_error_format'.tr(args: [e.toString()]));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Debt? existing = widget.existing;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.borderGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                existing == null ? 'new_debt'.tr() : 'edit_debt'.tr(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.mainDarkBlue,
                ),
              ),
              const SizedBox(height: 20),
              DebtForm(
                initialName: existing?.personName,
                initialAmount: existing?.amount,
                initialType: existing?.type,
                initialDescription: existing?.description,
                submitLabel: existing == null ? 'save'.tr() : 'update'.tr(),
                isSaving: _isSaving,
                onSubmit: _save,
              ),
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(fontSize: 13, color: theme.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
