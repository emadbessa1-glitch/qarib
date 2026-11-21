/// إعدادات التطبيق العامة.
class AppConfig {
  AppConfig._();

  /// false = وضع التجربة (بيانات تجريبية جوه التطبيق، من غير إنترنت ولا Firebase).
  /// true  = بيانات حقيقية على Firebase (لازم تعمل `flutterfire configure` الأول).
  static const bool useFirebase = true;

  /// إيميلات الأدمن في وضع التجربة بس.
  /// في وضع Firebase الأدمن بيتحددوا من collection اسمه `admins` في Firestore
  /// (كل document اسمه إيميل الأدمن بحروف صغيرة)، فمش محتاج تعدّل هنا.
  static const List<String> adminEmails = <String>[
    'admin@qarib.app',
  ];

  /// نقطة البداية على الخريطة لو الموقع مش متاح (وسط القاهرة).
  static const double defaultLat = 30.0444;
  static const double defaultLng = 31.2357;

  /// كود الدولة لأرقام الواتساب.
  static const String countryCode = '20';
}
