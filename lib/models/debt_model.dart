import 'model_utils.dart';

/// Qarz yo'nalishi.
enum DebtType {
  /// Men qarzdorman — pulni men olganman.
  iOwe('i_owe'),

  /// Menga qarz — pulni men berganman.
  owedToMe('owed_to_me');

  const DebtType(this.value);

  final String value;

  static DebtType fromValue(String? value) {
    return DebtType.values.firstWhere(
      (DebtType t) => t.value == value,
      orElse: () => DebtType.iOwe,
    );
  }
}

/// Qarz qanday kiritilgani.
enum DebtSource {
  voice('voice'),
  manual('manual');

  const DebtSource(this.value);

  final String value;

  static DebtSource fromValue(String? value) {
    return DebtSource.values.firstWhere(
      (DebtSource s) => s.value == value,
      orElse: () => DebtSource.manual,
    );
  }
}

/// `users/{userId}/debts/{debtId}` (PROJECT.md 3.2).
class Debt {
  const Debt({
    required this.id,
    required this.personName,
    required this.amount,
    required this.type,
    this.description,
    this.createdVia = DebtSource.manual,
    this.isPaid = false,
    this.createdAt,
  });

  final String id;
  final String personName;
  final double amount;
  final DebtType type;
  final String? description;
  final DebtSource createdVia;
  final bool isPaid;
  final DateTime? createdAt;

  factory Debt.fromMap(String id, Map<String, dynamic> map) {
    return Debt(
      id: id,
      personName: asString(map['personName']) ?? '',
      amount: asDouble(map['amount']) ?? 0,
      type: DebtType.fromValue(asString(map['type'])),
      description: asString(map['description']),
      createdVia: DebtSource.fromValue(asString(map['createdVia'])),
      isPaid: asBool(map['isPaid']) ?? false,
      createdAt: asDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'personName': personName,
      'amount': amount,
      'type': type.value,
      'description': description,
      'createdVia': createdVia.value,
      'isPaid': isPaid,
      'createdAt': createdAt,
    };
  }

  Debt copyWith({
    String? id,
    String? personName,
    double? amount,
    DebtType? type,
    String? description,
    DebtSource? createdVia,
    bool? isPaid,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      createdVia: createdVia ?? this.createdVia,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Qarzlar bo'yicha umumiy balans (PROJECT.md 5.3, yuqori xulosa karta).
class DebtBalance {
  const DebtBalance({required this.owedToMe, required this.iOwe});

  /// "Sizdan qarz" — boshqalar menga qarzdor.
  final double owedToMe;

  /// "Siz qarzsiz" — men boshqalarga qarzdorman.
  final double iOwe;

  /// Sof holat: musbat bo'lsa menga ko'proq qarzdor.
  double get net => owedToMe - iOwe;

  static DebtBalance from(Iterable<Debt> debts) {
    double toMe = 0;
    double mine = 0;
    for (final Debt debt in debts) {
      if (debt.isPaid) continue;
      if (debt.type == DebtType.owedToMe) {
        toMe += debt.amount;
      } else {
        mine += debt.amount;
      }
    }
    return DebtBalance(owedToMe: toMe, iOwe: mine);
  }
}
