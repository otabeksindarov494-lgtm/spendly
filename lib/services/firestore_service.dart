import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/public_profile_model.dart';
import '../models/user_profile_model.dart';

/// Profil ma'lumotlari bilan ishlash (PROJECT.md 3.2).
///
/// Profil maydonlari `users/{userId}` hujjatining o'zida saqlanadi;
/// `attendance`, `debts`, `transactions` esa uning subkolleksiyalari.
class ProfileService {
  const ProfileService(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> userDoc(String userId) =>
      _db.collection('users').doc(userId);

  Stream<UserProfile?> watch(String userId) {
    return userDoc(userId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return UserProfile.fromMap(data);
    });
  }

  Future<UserProfile?> fetch(String userId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await userDoc(userId).get();
    final Map<String, dynamic>? data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return UserProfile.fromMap(data);
  }

  /// Profilni to'liq yozadi (mavjud maydonlar ustiga qo'shiladi).
  Future<void> save(String userId, UserProfile profile) {
    return userDoc(userId).set(profile.toMap(), SetOptions(merge: true));
  }

  /// Faqat ayrim maydonlarni yangilaydi.
  Future<void> updateFields(String userId, Map<String, dynamic> fields) {
    return userDoc(userId).set(fields, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> publicDoc(String userId) =>
      _db.collection('publicProfiles').doc(userId);

  /// Chat ro'yxatida ko'rinadigan ochiq profilni yangilaydi.
  ///
  /// Bu yerga FAQAT ism va kichik avatar yoziladi — maosh, davomat va
  /// qarzlar `users/{userId}` da qoladi va boshqalarga ko'rinmaydi.
  Future<void> syncPublicProfile(
    String userId, {
    required String fullName,
    String? avatarBase64,
  }) {
    return publicDoc(userId).set(
      PublicProfile(
        userId: userId,
        fullName: fullName.trim().isEmpty ? 'Foydalanuvchi' : fullName.trim(),
        avatarBase64: avatarBase64,
        updatedAt: DateTime.now(),
      ).toMap(),
      SetOptions(merge: true),
    );
  }

  /// Yangi foydalanuvchi uchun bo'sh profil yaratadi (onboarding'gacha).
  Future<void> createIfMissing(String userId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await userDoc(userId).get();
    if (snapshot.exists) return;
    await userDoc(userId).set(<String, dynamic>{
      'onboardingCompleted': false,
      'themeMode': 'light',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
