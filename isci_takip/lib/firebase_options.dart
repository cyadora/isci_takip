// File generated by FlutterFire CLI.
// Contains Firebase configuration options for your app
// This is a placeholder file - you'll need to replace this with your actual Firebase configuration

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDSowLQsB5XyTA5bKk7P8ZnQ3ZyHsUn1n4',
    appId: '1:109074765498:web:1d854975771a576d595483',
    messagingSenderId: '109074765498',
    projectId: 'isci-takip',
    storageBucket: 'isci-takip.appspot.com',
    authDomain: 'isci-takip.firebaseapp.com',
    measurementId: 'G-RTXC2X0PPP',
  );
  
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDSowLQsB5XyTA5bKk7P8ZnQ3ZyHsUn1n4',
    appId: '1:109074765498:web:1d854975771a576d595483',
    messagingSenderId: '109074765498',
    projectId: 'isci-takip',
    storageBucket: 'isci-takip.appspot.com',
    authDomain: 'isci-takip.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSowLQsB5XyTA5bKk7P8ZnQ3ZyHsUn1n4',
    appId: '1:109074765498:android:1d854975771a576d595483',
    messagingSenderId: '109074765498',
    projectId: 'isci-takip',
    storageBucket: 'isci-takip.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDSowLQsB5XyTA5bKk7P8ZnQ3ZyHsUn1n4',
    appId: '1:109074765498:ios:1d854975771a576d595483',
    messagingSenderId: '109074765498',
    projectId: 'isci-takip',
    storageBucket: 'isci-takip.appspot.com',
    iosBundleId: 'com.example.isciTakip',
  );
}
