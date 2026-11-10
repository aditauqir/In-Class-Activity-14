import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAHis7hFZm770zjY-F56C2n-OkTySfnMwc',
    appId: '1:15229532858:web:879608ebc33ab0b290e083',
    messagingSenderId: '15229532858',
    projectId: 'inclass-13-dfe78',
    authDomain: 'inclass-13-dfe78.firebaseapp.com',
    storageBucket: 'inclass-13-dfe78.firebasestorage.app',
    measurementId: 'G-EW6NC2PXYW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0-eqHT4sLqGb4jRkOgBEyyoeYp4CYxXY',
    appId: '1:705627349691:android:7e8d2d01df837328453f9e',
    messagingSenderId: '705627349691',
    projectId: 'mad-inclass11',
    storageBucket: 'mad-inclass11.firebasestorage.app',
  );

  static const FirebaseOptions inclass13 = FirebaseOptions(
    apiKey: 'AIzaSyAgjcahQVnk_vCNz33KasXCYaTaYKwrfkE',
    appId: '1:15229532858:android:f825157e580b74e690e083',
    messagingSenderId: '15229532858',
    projectId: 'inclass-13-dfe78',
    storageBucket: 'inclass-13-dfe78.firebasestorage.app',
  );
}
