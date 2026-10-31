// File generated for commandeappmain
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRZyAC1YWeASnIi1KcD2FrQlAA-xZkOSA',
    appId: '1:246389079131:android:84e29e0d0ba9627eab537e',
    messagingSenderId: '246389079131',
    projectId: 'commandeappmain',
    storageBucket: 'commandeappmain.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDRZyAC1YWeASnIi1KcD2FrQlAA-xZkOSA',
    appId: '1:246389079131:web:84e29e0d0ba9627eab537e',
    messagingSenderId: '246389079131',
    projectId: 'commandeappmain',
    authDomain: 'commandeappmain.firebaseapp.com',
    storageBucket: 'commandeappmain.firebasestorage.app',
  );
}
