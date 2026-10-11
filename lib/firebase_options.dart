// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase ulanish sozlamalari.
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
      'Firebase hali sozlanmagan ($platform).\n';

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIAJahvETOufGW7ics4z6A6aRbDIn36HE',
    appId: '1:787694668434:ios:70d7552c6bcaf6284bf44b',
    messagingSenderId: '787694668434',
    projectId: 'spendly-ef985',
    storageBucket: 'spendly-ef985.firebasestorage.app',
    iosBundleId: 'erkinovv.dev.spendly',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBIAJahvETOufGW7ics4z6A6aRbDIn36HE',
    appId: '1:787694668434:android:70d7552c6bcaf6284bf44b',
    messagingSenderId: '787694668434',
    projectId: 'spendly-ef985',
    storageBucket: 'spendly-ef985.firebasestorage.app',
  );
}
