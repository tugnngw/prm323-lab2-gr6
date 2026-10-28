import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for use with `Firebase.initializeApp()`.
///
/// Configured for Android (Lab 3 requirement: Android-only mobile app).
/// Replace with values from your Firebase Console / FlutterFire CLI:
/// `flutterfire configure --project=<your-firebase-project-id>`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDV1qOOU77kxoE_eOrDZgKf2Sqr_qWwvr4',
    appId: '1:510519082861:android:4cf5b64c4e2e4487c46464',
    messagingSenderId: '510519082861',
    projectId: 'prm323-lab2-gr6',
    storageBucket: 'prm323-lab2-gr6.firebasestorage.app',
  );
}
