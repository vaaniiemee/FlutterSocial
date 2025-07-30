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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDp417gjpF4JdPnVdXPplCEV1oruVeTFKQ',
    appId: '1:951197382156:web:4ca9cd0ef3f25ac3d2e029',
    messagingSenderId: '951197382156',
    projectId: 'meetplace-81e69',
    authDomain: 'meetplace-81e69.firebaseapp.com',
    storageBucket: 'meetplace-81e69.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDp417gjpF4JdPnVdXPplCEV1oruVeTFKQ',
    appId: '1:951197382156:android:4ca9cd0ef3f25ac3d2e029',
    messagingSenderId: '951197382156',
    projectId: 'meetplace-81e69',
    storageBucket: 'meetplace-81e69.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDp417gjpF4JdPnVdXPplCEV1oruVeTFKQ',
    appId: '1:951197382156:ios:4ca9cd0ef3f25ac3d2e029',
    messagingSenderId: '951197382156',
    projectId: 'meetplace-81e69',
    storageBucket: 'meetplace-81e69.firebasestorage.app',
    iosClientId: '951197382156-to6g4657i0ihnmj0giblckd6jv4aaavu.apps.googleusercontent.com',
    iosBundleId: 'com.example.Meetplace',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDp417gjpF4JdPnVdXPplCEV1oruVeTFKQ',
    appId: '1:951197382156:ios:4ca9cd0ef3f25ac3d2e029',
    messagingSenderId: '951197382156',
    projectId: 'meetplace-81e69',
    storageBucket: 'meetplace-81e69.firebasestorage.app',
    iosClientId: '951197382156-to6g4657i0ihnmj0giblckd6jv4aaavu.apps.googleusercontent.com',
    iosBundleId: 'com.example.Meetplace',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDp417gjpF4JdPnVdXPplCEV1oruVeTFKQ',
    appId: '1:951197382156:web:4ca9cd0ef3f25ac3d2e029',
    messagingSenderId: '951197382156',
    projectId: 'meetplace-81e69',
    storageBucket: 'meetplace-81e69.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDp417gjpF4JdPnVdXPplCEV1oruVeTFKQ',
    appId: '1:951197382156:web:4ca9cd0ef3f25ac3d2e029',
    messagingSenderId: '951197382156',
    projectId: 'meetplace-81e69',
    storageBucket: 'meetplace-81e69.firebasestorage.app',
  );
} 