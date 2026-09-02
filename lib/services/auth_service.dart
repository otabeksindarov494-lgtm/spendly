import 'package:firebase_auth/firebase_auth.dart';

/// Foydalanuvchiga ko'rsatiladigan, o'zbekcha xabarli autentifikatsiya xatosi.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Firebase Authentication ustidagi yupqa qatlam (PROJECT.md 3.1).
///
/// Email + parol usuli ishlatiladi.
class AuthService {
  const AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = credential.user;
      if (user == null) {
        throw const AuthFailure('Kirish amalga oshmadi, qayta urinib ko\'ring.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<User> register({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          'Ro\'yxatdan o\'tish amalga oshmadi, qayta urinib ko\'ring.',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e));
    }
  }

  static String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email manzili noto\'g\'ri kiritilgan.';
      case 'user-disabled':
        return 'Bu hisob bloklangan.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email yoki parol noto\'g\'ri.';
      case 'email-already-in-use':
        return 'Bu email allaqachon ro\'yxatdan o\'tgan.';
      case 'weak-password':
        return 'Parol juda oddiy — kamida 6 ta belgi kiriting.';
      case 'network-request-failed':
        return 'Internet aloqasi yo\'q. Ulanishni tekshiring.';
      case 'too-many-requests':
        return 'Juda ko\'p urinish bo\'ldi. Birozdan so\'ng qayta urining.';
      default:
        return 'Xatolik yuz berdi: ${e.code}';
    }
  }
}
