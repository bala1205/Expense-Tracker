import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXfByjUhLIi0QTv3gGlxU5wObODaoixBA',
    appId: '1:450820705072:android:71c58de17b67122866d6f5',
    messagingSenderId: '450820705072',
    projectId: 'expense-track-839af',
    storageBucket: 'expense-track-839af.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXfByjUhLIi0QTv3gGlxU5wObODaoixBA',
    appId: '1:450820705072:android:71c58de17b67122866d6f5',
    messagingSenderId: '450820705072',
    projectId: 'expense-track-839af',
    storageBucket: 'expense-track-839af.firebasestorage.app',
    iosBundleId: 'com.example.expenseTrack',
  );
}