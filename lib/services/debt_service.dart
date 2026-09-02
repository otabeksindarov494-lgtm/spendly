import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/debt_model.dart';

/// Qarzlar bilan ishlash (PROJECT.md 5.3).
class DebtService {
  const DebtService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _db.collection('users').doc(userId).collection('debts');

  Stream<List<Debt>> watchAll(String userId) {
    return _collection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    Debt.fromMap(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  Future<void> add({
    required String userId,
    required String personName,
    required double amount,
    required DebtType type,
    String? description,
    DebtSource createdVia = DebtSource.manual,
  }) {
    return _collection(userId).add(<String, dynamic>{
      'personName': personName.trim(),
      'amount': amount,
      'type': type.value,
      'description': (description == null || description.trim().isEmpty)
          ? null
          : description.trim(),
      'createdVia': createdVia.value,
      'isPaid': false,
      // Ataylab server emas, mijoz vaqti: `serverTimestamp()` mahalliy
      // snapshot'da null bo'lib turadi va `orderBy('createdAt')` natijasida
      // yangi qarz avval ro'yxat oxirida ko'rinib, keyin yuqoriga sakraydi.
      'createdAt': DateTime.now(),
    });
  }

  Future<void> setPaid({
    required String userId,
    required String debtId,
    required bool isPaid,
  }) {
    return _collection(userId).doc(debtId).update(<String, dynamic>{
      'isPaid': isPaid,
    });
  }

  Future<void> update({
    required String userId,
    required Debt debt,
  }) {
    return _collection(userId).doc(debt.id).update(<String, dynamic>{
      'personName': debt.personName.trim(),
      'amount': debt.amount,
      'type': debt.type.value,
      'description': debt.description,
    });
  }

  Future<void> delete({required String userId, required String debtId}) {
    return _collection(userId).doc(debtId).delete();
  }
}
