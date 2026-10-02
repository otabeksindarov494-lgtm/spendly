import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/debt_model.dart';
import '../../providers/core_providers.dart';
import '../../providers/debt_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/shimmer_box.dart';
import 'manual_debt_sheet.dart';
import 'voice_debt_sheet.dart';

/// 3-tab: qarzlar ro'yxati, balans va qo'shish tugmalari (PROJECT.md 5.3).
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CustomTheme theme = context.theme;
    final AsyncValue<List<Debt>> debtsAsync = ref.watch(debtsProvider);
    final DebtBalance balance = ref.watch(debtBalanceProvider);
    final List<Debt> filtered = ref.watch(filteredDebtsProvider);
    final DebtFilter activeFilter = ref.watch(debtFilterProvider);
    final String currency =
        ref.watch(profileProvider).value?.currency ?? 'so\'m';

    return Scaffold(
      appBar: AppBar(title: const Text('Qarzlar')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: <Widget>[
            _buildBalanceCard(theme, balance, currency),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _AddButton(
                    icon: IconsaxPlusBold.microphone_2,
                    label: 'Ovoz orqali',
                    background: theme.blue,
                    foreground: CustomTheme.onAccent,
                    onTap: () => VoiceDebtSheet.show(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddButton(
                    icon: IconsaxPlusLinear.edit,
                    label: 'Qo\'lda',
                    background: theme.glassFill,
                    foreground: theme.mainDarkBlue,
                    borderColor: theme.borderGray,
                    onTap: () => ManualDebtSheet.show(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFilters(ref, theme, activeFilter),
            const SizedBox(height: 16),
            debtsAsync.when(
              loading: () => const ShimmerList(itemCount: 4, itemHeight: 78),
              error: (Object e, StackTrace _) =>
                  ErrorView(message: 'Qarzlar yuklanmadi: $e'),
              data: (List<Debt> all) {
                if (all.isEmpty) {
                  return const EmptyState(
                    icon: IconsaxPlusLinear.empty_wallet,
                    title: 'Qarzlar ro\'yxati bo\'sh',
                    message:
                        'Mikrofon tugmasini bosib aytib yuboring yoki qo\'lda '
                        'qo\'shing.',
                  );
                }
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: IconsaxPlusLinear.filter,
                    title: 'Bu filtrga mos qarz yo\'q',
                  );
                }
                return Column(
                  children: <Widget>[
                    for (final Debt debt in filtered)
                      _DebtTile(debt: debt, currency: currency),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    CustomTheme theme,
    DebtBalance balance,
    String currency,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _BalanceColumn(
                  label: 'Sizdan qarz',
                  amount: balance.owedToMe,
                  color: theme.green,
                  currency: currency,
                ),
              ),
              Container(width: 1, height: 44, color: theme.borderGray),
              Expanded(
                child: _BalanceColumn(
                  label: 'Siz qarzsiz',
                  amount: balance.iOwe,
                  color: theme.red,
                  currency: currency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: (balance.net >= 0 ? theme.green : theme.red).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'Sof holat: '
              '${Formatters.signedMoney(balance.net, currency: currency)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: balance.net >= 0 ? theme.green : theme.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref, CustomTheme theme, DebtFilter active) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final DebtFilter filter in DebtFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () =>
                    ref.read(debtFilterProvider.notifier).select(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: filter == active ? theme.blue : theme.glassFill,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: filter == active ? theme.blue : theme.borderGray,
                    ),
                  ),
                  child: Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: filter == active
                          ? CustomTheme.onAccent
                          : theme.mainDarkBlue,
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

class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
  });

  final String label;
  final double amount;
  final Color color;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    return Column(
      children: <Widget>[
        Text(label, style: TextStyle(fontSize: 12, color: theme.textGray)),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            Formatters.money(amount, currency: currency),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bitta qarz kartasi: svayp bilan o'chirish, checkbox bilan "to'landi".
class _DebtTile extends ConsumerWidget {
  const _DebtTile({required this.debt, required this.currency});

  final Debt debt;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CustomTheme theme = context.theme;
    final Color accent = debt.type == DebtType.owedToMe
        ? theme.green
        : theme.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey<String>(debt.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: theme.red,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(IconsaxPlusLinear.trash, color: CustomTheme.onAccent),
        ),
        confirmDismiss: (DismissDirection _) => _confirmDelete(context, theme),
        onDismissed: (DismissDirection _) {
          final String? userId = ref.read(currentUserIdProvider);
          if (userId == null) return;
          ref.read(debtServiceProvider).delete(userId: userId, debtId: debt.id);
        },
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => ManualDebtSheet.show(context, existing: debt),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  debt.personName.isEmpty
                      ? '?'
                      : debt.personName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            debt.personName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.mainDarkBlue,
                              decoration: debt.isPaid
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (debt.createdVia == DebtSource.voice) ...<Widget>[
                          const SizedBox(width: 6),
                          Icon(
                            IconsaxPlusBold.microphone_2,
                            size: 13,
                            color: theme.favoriteGray,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: theme.textGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    Formatters.money(debt.amount, currency: currency),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: debt.isPaid ? theme.textGray : accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      final String? userId = ref.read(currentUserIdProvider);
                      if (userId == null) return;
                      ref
                          .read(debtServiceProvider)
                          .setPaid(
                            userId: userId,
                            debtId: debt.id,
                            isPaid: !debt.isPaid,
                          );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          debt.isPaid
                              ? IconsaxPlusBold.tick_square
                              : IconsaxPlusLinear.stop,
                          size: 16,
                          color: debt.isPaid ? theme.green : theme.favoriteGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'To\'landi',
                          style: TextStyle(
                            fontSize: 12,
                            color: debt.isPaid ? theme.green : theme.textGray,
                          ),
                        ),
                      ],
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

  String _subtitle() {
    final String date = debt.createdAt == null
        ? ''
        : Formatters.longDate(debt.createdAt!);
    final String? note = debt.description;
    if (note == null || note.isEmpty) return date;
    return date.isEmpty ? note : '$date · $note';
  }

  Future<bool> _confirmDelete(BuildContext context, CustomTheme theme) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Qarzni o\'chirish'),
        content: Text('${debt.personName} bilan bog\'liq yozuv o\'chiriladi.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('O\'chirish', style: TextStyle(color: theme.red)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
