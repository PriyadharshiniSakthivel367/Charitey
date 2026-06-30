// File corrected to use the verified API Key for project: charitey-37ce8
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
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
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
    apiKey: 'AIzaSyAQIj6th0aijxmeHmzkRGRekZPXhP63C08',
    appId: '1:49324937832:web:2483eb7807d59da3a561dd',
    messagingSenderId: '49324937832',
    projectId: 'charitey-37ce8',
    authDomain: 'charitey-37ce8.firebaseapp.com',
    storageBucket: 'charitey-37ce8.firebasestorage.app',
    measurementId: 'G-GG71PRX0JD',
    //clientId: '49324937832-amikmbcqkaigalqpvksu5m862qecinq7.apps.googleusercontent.com', // ← ADD THIS

  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBn9Tsy76rP_uJ1uUntzx1sjnuByzy0utk',
    appId: '1:49324937832:android:a09673ba5590f134a561dd',
    messagingSenderId: '49324937832',
    projectId: 'charitey-37ce8',
    storageBucket: 'charitey-37ce8.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCenzCJBwO65guRgFPyWNtOOROSxSPXtiw',
    appId: '1:49324937832:ios:23b1f8f0c522d7a7a561dd',
    messagingSenderId: '49324937832',
    projectId: 'charitey-37ce8',
    storageBucket: 'charitey-37ce8.firebasestorage.app',
    androidClientId: '49324937832-6057vsokoeh9l31tlno556l0p6lvkiiv.apps.googleusercontent.com',
    iosClientId: '49324937832-ge0p910ug1m27cktr3mkv8cnii6bs9vm.apps.googleusercontent.com',
    iosBundleId: 'com.example.charityApp',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCenzCJBwO65guRgFPyWNtOOROSxSPXtiw',
    appId: '1:49324937832:ios:23b1f8f0c522d7a7a561dd',
    messagingSenderId: '49324937832',
    projectId: 'charitey-37ce8',
    storageBucket: 'charitey-37ce8.firebasestorage.app',
    androidClientId: '49324937832-6057vsokoeh9l31tlno556l0p6lvkiiv.apps.googleusercontent.com',
    iosClientId: '49324937832-ge0p910ug1m27cktr3mkv8cnii6bs9vm.apps.googleusercontent.com',
    iosBundleId: 'com.example.charityApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAQIj6th0aijxmeHmzkRGRekZPXhP63C08',
    appId: '1:49324937832:web:67d90889762de811a561dd',
    messagingSenderId: '49324937832',
    projectId: 'charitey-37ce8',
    authDomain: 'charitey-37ce8.firebaseapp.com',
    storageBucket: 'charitey-37ce8.firebasestorage.app',
    measurementId: 'G-P3N76FDTT6',
  );
}
