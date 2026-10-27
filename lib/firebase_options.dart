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
    apiKey: 'AIzaSyPlaceholderAndroidKeyForLab3PRM323',
    appId: '1:123456789000:android:abcdef1234567890abcdef',
    messagingSenderId: '123456789000',
    projectId: 'prm323-lab3-fptu-brain',
    storageBucket: 'prm323-lab3-fptu-brain.appspot.com',
  );
}
