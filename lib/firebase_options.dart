// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDERo2-Nyit1b3UTqWWKNUutkALGBauxuc',
    appId: '1:975716064608:android:c1a4889c2863e014749205',
    messagingSenderId: '975716064608',
    projectId: 'doctak-322cc',
    databaseURL: 'https://doctak-322cc-default-rtdb.firebaseio.com',
    storageBucket: 'doctak-322cc.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmX3-mlp3rXJwbbPIoF09p3EjJEbOAg0g',
    appId: '1:975716064608:ios:ac7a51c1bd0561a5749205',
    messagingSenderId: '975716064608',
    projectId: 'doctak-322cc',
    databaseURL: 'https://doctak-322cc-default-rtdb.firebaseio.com',
    storageBucket: 'doctak-322cc.appspot.com',
    androidClientId: '975716064608-6tevbjue75th1mga8ukejcggh9nbf9da.apps.googleusercontent.com',
    iosClientId: '975716064608-d2ff219g0j77e33vdmaft9euhn8nqlad.apps.googleusercontent.com',
    iosBundleId: 'com.doctak.ios',
  );
}
