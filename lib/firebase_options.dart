// إعدادات Firebase لمشروع qarib-78026 (تطبيق أندرويد com.qarib.qarib).
// القيم دي مش سرية: بتتحط جوه أي تطبيق Firebase، والحماية الحقيقية في firestore.rules.
// لو حبيت تضيف iOS أو ويب بعدين، شغّل `flutterfire configure` وهيكتب فوق الملف ده.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError('التطبيق متظبط على أندرويد بس لحد دلوقتي');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6--Gyh5uzoYjnWBnazXkcrl9qaMwU1Zs',
    appId: '1:956545867966:android:ba7bac66446b7f18d93eef',
    messagingSenderId: '956545867966',
    projectId: 'qarib-78026',
    storageBucket: 'qarib-78026.firebasestorage.app',
  );
}
