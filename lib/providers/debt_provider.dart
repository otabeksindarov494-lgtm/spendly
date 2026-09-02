import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/debt_model.dart';
import 'core_providers.dart';

/// Barcha qarzlar.
final StreamProvider<List<Debt>> debtsProvider =
    StreamProvider<List<Debt>>((Ref ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream<List<Debt>>.value(<Debt>[]);
  return ref.watch(debtServiceProvider).watchAll(userId);
});

/// Yuqori xulosa karta uchun balans (to'langanlar hisobga olinmaydi).
final Provider<DebtBalance> debtBalanceProvider =
    Provider<DebtBalance>((Ref ref) {
  final List<Debt> debts = ref.watch(debtsProvider).value ?? <Debt>[];
  return DebtBalance.from(debts);
});

/// Qarzlar ro'yxati filtri.
enum DebtFilter {
  all('Hammasi'),
  owedToMe('Sizdan qarz'),
  iOwe('Siz qarzdorsiz');

  const DebtFilter(this.label);

  final String label;
}

class DebtFilterNotifier extends Notifier<DebtFilter> {
  @override
  DebtFilter build() => DebtFilter.all;

  void select(DebtFilter filter) => state = filter;
}

final NotifierProvider<DebtFilterNotifier, DebtFilter> debtFilterProvider =
    NotifierProvider<DebtFilterNotifier, DebtFilter>(DebtFilterNotifier.new);

/// Filtrga mos qarzlar: to'lanmaganlari yuqorida.
final Provider<List<Debt>> filteredDebtsProvider =
    Provider<List<Debt>>((Ref ref) {
  final List<Debt> debts = ref.watch(debtsProvider).value ?? <Debt>[];
  final DebtFilter filter = ref.watch(debtFilterProvider);

  final List<Debt> filtered = debts.where((Debt debt) {
    switch (filter) {
      case DebtFilter.all:
        return true;
      case DebtFilter.owedToMe:
        return debt.type == DebtType.owedToMe;
      case DebtFilter.iOwe:
        return debt.type == DebtType.iOwe;
    }
  }).toList();

  filtered.sort((Debt a, Debt b) {
    if (a.isPaid != b.isPaid) return a.isPaid ? 1 : -1;
    final DateTime aDate = a.createdAt ?? DateTime(1970);
    final DateTime bDate = b.createdAt ?? DateTime(1970);
    return bDate.compareTo(aDate);
  });

  return filtered;
});
