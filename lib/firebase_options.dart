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
    apiKey: 'AIzaSyBKxPPAiKjKeLLxBQDILjj_8vDgJCZZFvY',
    appId: '1:190765752610:web:d9c534f987c6d21ee4c57b',
    messagingSenderId: '190765752610',
    projectId: 'appproject-b29eb',
    authDomain: 'appproject-b29eb.firebaseapp.com',
    storageBucket: 'appproject-b29eb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCcxetCUpDTI4lV7EZ-nas4JPaBIJcnDM8',
    appId: '1:190765752610:android:7bd5ef533d123ee1e4c57b',
    messagingSenderId: '190765752610',
    projectId: 'appproject-b29eb',
    storageBucket: 'appproject-b29eb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDuWCvbVqnsvEArBtgSZqn6fCADhFsYNKU',
    appId: '1:190765752610:ios:placeholder',
    messagingSenderId: '190765752610',
    projectId: 'appproject-b29eb',
    storageBucket: 'appproject-b29eb.firebasestorage.app',
    iosBundleId: 'com.example.gardenGenie',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDuWCvbVqnsvEArBtgSZqn6fCADhFsYNKU',
    appId: '1:190765752610:macos:placeholder',
    messagingSenderId: '190765752610',
    projectId: 'appproject-b29eb',
    storageBucket: 'appproject-b29eb.firebasestorage.app',
    iosBundleId: 'com.example.gardenGenie',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBKxPPAiKjKeLLxBQDILjj_8vDgJCZZFvY',
    appId: '1:190765752610:windows:placeholder',
    messagingSenderId: '190765752610',
    projectId: 'appproject-b29eb',
    storageBucket: 'appproject-b29eb.firebasestorage.app',
  );
}
