import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/debt_service.dart';
import '../services/firestore_service.dart';
import '../services/image_service.dart';
import '../services/speech_service.dart';

/// `main()`da haqiqiy nusxa bilan almashtiriladi (override qilinadi).
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
  (Ref ref) => throw UnimplementedError(
    'sharedPreferencesProvider main() ichida override qilinishi kerak',
  ),
);

final Provider<FirebaseAuth> firebaseAuthProvider =
    Provider<FirebaseAuth>((Ref ref) => FirebaseAuth.instance);

final Provider<FirebaseFirestore> firestoreProvider =
    Provider<FirebaseFirestore>((Ref ref) => FirebaseFirestore.instance);

final Provider<AuthService> authServiceProvider = Provider<AuthService>(
  (Ref ref) => AuthService(ref.watch(firebaseAuthProvider)),
);

final Provider<ProfileService> profileServiceProvider =
    Provider<ProfileService>(
  (Ref ref) => ProfileService(ref.watch(firestoreProvider)),
);

final Provider<AttendanceService> attendanceServiceProvider =
    Provider<AttendanceService>(
  (Ref ref) => AttendanceService(ref.watch(firestoreProvider)),
);

final Provider<DebtService> debtServiceProvider = Provider<DebtService>(
  (Ref ref) => DebtService(ref.watch(firestoreProvider)),
);

final Provider<ImageService> imageServiceProvider =
    Provider<ImageService>((Ref ref) => ImageService());

final Provider<SpeechService> speechServiceProvider =
    Provider<SpeechService>((Ref ref) => SpeechService());

/// Kirish holati oqimi.
final StreamProvider<User?> authStateProvider = StreamProvider<User?>(
  (Ref ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// Joriy foydalanuvchi UID'si — kirilmagan bo'lsa `null`.
final Provider<String?> currentUserIdProvider = Provider<String?>(
  (Ref ref) => ref.watch(authStateProvider).value?.uid,
);

/// Ilova versiyasi (PROJECT.md 5.4) — `package_info_plus` orqali olinadi.
final FutureProvider<String> appVersionProvider =
    FutureProvider<String>((Ref ref) async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return 'v${info.version} (${info.buildNumber})';
});
