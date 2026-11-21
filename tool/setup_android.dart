// بيظبط ملفات أندرويد بعد `flutter create`:
//   - صلاحيات الإنترنت والموقع
//   - السماح بفتح الاتصال والواتساب والخرايط (url_launcher)
//   - minSdk = 23 (مطلوب لـ Firebase)
//
// التشغيل (من فولدر المشروع):  dart run tool/setup_android.dart
import 'dart:io';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('مش لاقي android/. شغّل الأول: flutter create . --platforms android --org com.qarib');
    exit(1);
  }

  var xml = manifest.readAsStringSync();

  const permissions = '''
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
''';
  if (!xml.contains('ACCESS_FINE_LOCATION')) {
    xml = xml.replaceFirst('<application', '$permissions    <application');
  }

  const queries = '''
        <intent>
            <action android:name="android.intent.action.DIAL"/>
            <data android:scheme="tel"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>
''';
  if (!xml.contains('android:scheme="tel"')) {
    if (xml.contains('<queries>')) {
      xml = xml.replaceFirst('<queries>', '<queries>\n$queries');
    } else {
      xml = xml.replaceFirst(
          '</manifest>', '    <queries>\n$queries    </queries>\n</manifest>');
    }
  }

  // اسم التطبيق على الموبايل
  xml = xml.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="قريب"');
  manifest.writeAsStringSync(xml);
  stdout.writeln('✓ AndroidManifest.xml');

  for (final path in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
    final f = File(path);
    if (!f.existsSync()) continue;
    var gradle = f.readAsStringSync();
    gradle = gradle
        .replaceAll('minSdk = flutter.minSdkVersion', 'minSdk = 23')
        .replaceAll('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 23');
    f.writeAsStringSync(gradle);
    stdout.writeln('✓ $path (minSdk 23)');
  }

  stdout.writeln('خلصنا. شغّل: flutter run');
}
