import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAcGTlBmPV_x4n3k2SNxZsffj5ao2Nnj34',
    appId: '1:876041819479:web:d1979bdaf67bd250ef1a12',
    messagingSenderId: '876041819479',
    projectId: 'tusai-2fb30',
    authDomain: 'tusai-2fb30.firebaseapp.com',
    storageBucket: 'tusai-2fb30.firebasestorage.app',
    measurementId: 'G-9V9N8J6Z5L',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-cH6EL52vJzaSX2pxxBSf894WkkYag38',
    appId: '1:876041819479:android:825febdc34cbe8d4ef1a12',
    messagingSenderId: '876041819479',
    projectId: 'tusai-2fb30',
    storageBucket: 'tusai-2fb30.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-cH6EL52vJzaSX2pxxBSf894WkkYag38',
    appId: '1:876041819479:android:825febdc34cbe8d4ef1a12',
    messagingSenderId: '876041819479',
    projectId: 'tusai-2fb30',
    storageBucket: 'tusai-2fb30.firebasestorage.app',
  );
}
