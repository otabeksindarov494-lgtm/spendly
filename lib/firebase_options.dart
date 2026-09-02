// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase ulanish sozlamalari.
///
/// **Bu fayl hali generatsiya qilinmagan.** Uni yaratish uchun:
///
/// ```sh
/// dart pub global activate flutterfire_cli
/// flutterfire configure --project=<sizning-firebase-loyihangiz>
/// ```
///
/// Buyruq shu faylni haqiqiy kalitlar bilan qayta yozadi hamda
/// `android/app/google-services.json` va
/// `ios/Runner/GoogleService-Info.plist` fayllarini qo'shadi.
///
/// Kalitlar generatsiya qilingan faylda saqlanadi va git'ga tushmasligi
/// uchun `.gitignore`ga qo'shilgan — hech qachon qo'lda hardcode qilinmaydi.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(_message('Web'));
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(_message(defaultTargetPlatform.name));
    }
  }

  static String _message(String platform) =>
      'Firebase hali sozlanmagan ($platform).\n'
      'Terminalda quyidagini bajaring:\n'
      '  dart pub global activate flutterfire_cli\n'
      '  flutterfire configure\n'
      'Bu buyruq lib/firebase_options.dart faylini qayta yozadi.';

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBjcy-sFeDd6bN_ytFNs7ugb0IEmLuJ-yo',
    appId: '1:1023910729280:ios:93d5ba753fb07d9574b1a5',
    messagingSenderId: '1023910729280',
    projectId: 'spendly-68d5a',
    storageBucket: 'spendly-68d5a.firebasestorage.app',
    iosBundleId: 'erkinovv.dev.spendly',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWVb50BIX1w5iTUyavR5Nwh2pjww_HRwE',
    appId: '1:1023910729280:android:bb0e16fb1f17b51d74b1a5',
    messagingSenderId: '1023910729280',
    projectId: 'spendly-68d5a',
    storageBucket: 'spendly-68d5a.firebasestorage.app',
  );
}
