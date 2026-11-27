// Firebase options for VIGÍA (HU-24), as `flutterfire configure --platforms=android`
// writes them, taken from android/app/google-services.json. Only Android is
// registered: on the other platforms the app runs without push notifications.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Whether this platform has a Firebase app registered.
  static bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static FirebaseOptions get currentPlatform {
    if (!isSupported) {
      throw UnsupportedError('Firebase is only configured for Android in VIGÍA.');
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9m2VSLaspuQqfNn_8__p4_Jgl0wyTgSo',
    appId: '1:961937143935:android:4947e7191fefb6d8c5674a',
    messagingSenderId: '961937143935',
    projectId: 'vigia-596ec',
    storageBucket: 'vigia-596ec.firebasestorage.app',
  );
}
