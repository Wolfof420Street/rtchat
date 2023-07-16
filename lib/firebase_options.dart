// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyDv7Q7_HDpx9Us4LAMObNPV7k8XyCmJQVA',
    appId: '1:832669896677:android:9a9d7b799cea587c60290c',
    messagingSenderId: '832669896677',
    projectId: 'rtchat-47692',
    databaseURL: 'https://rtchat-47692-default-rtdb.firebaseio.com',
    storageBucket: 'rtchat-47692.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBxXobwS3h1USRLIrhzyb_85CoRyPZHdoo',
    appId: '1:832669896677:ios:59504132193d3b4e60290c',
    messagingSenderId: '832669896677',
    projectId: 'rtchat-47692',
    databaseURL: 'https://rtchat-47692-default-rtdb.firebaseio.com',
    storageBucket: 'rtchat-47692.appspot.com',
    androidClientId:
        '832669896677-bsjr7u9hpn4m7fg2nl0mgb6uvrjudct1.apps.googleusercontent.com',
    iosClientId:
        '832669896677-30itsabb94b1i9qd2uoo601tp4d4tlks.apps.googleusercontent.com',
    iosBundleId: 'com.rtirl.chat',
  );
}
