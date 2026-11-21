import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/place.dart';

/// يشيل أي حاجة غير الأرقام، ويحوّل الأرقام العربية (٠١٢) لإنجليزي.
String digitsOnly(String input) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    final i = arabic.indexOf(ch);
    if (i != -1) {
      buffer.write(i);
    } else if (RegExp(r'[0-9]').hasMatch(ch)) {
      buffer.write(ch);
    }
  }
  return buffer.toString();
}

/// يحوّل الرقم المصري لصيغة دولية للواتساب: 01012345678 → 201012345678
String toInternational(String phone) {
  var d = digitsOnly(phone);
  if (d.startsWith('00')) d = d.substring(2);
  if (d.startsWith(AppConfig.countryCode)) return d;
  if (d.startsWith('0')) d = d.substring(1);
  return '${AppConfig.countryCode}$d';
}

/// رقم موبايل مصري صحيح: 11 رقم ويبدأ بـ 010/011/012/015، أو رقم أرضي من 7 لـ 10 أرقام يبدأ بصفر.
bool isValidEgyptianPhone(String phone) {
  final d = digitsOnly(phone);
  if (RegExp(r'^01[0125][0-9]{8}$').hasMatch(d)) return true;
  return RegExp(r'^0[2-9][0-9]{6,9}$').hasMatch(d);
}

Future<bool> callPhone(String phone) {
  return launchUrl(Uri(scheme: 'tel', path: digitsOnly(phone)));
}

Future<bool> openWhatsapp(String phone, {String message = ''}) {
  final uri = Uri.https('wa.me', '/${toInternational(phone)}',
      message.isEmpty ? null : <String, String>{'text': message});
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// يفتح الاتجاهات في خرائط جوجل.
Future<bool> openDirections(Place place) {
  final uri = Uri.https('www.google.com', '/maps/dir/', <String, String>{
    'api': '1',
    'destination': '${place.lat},${place.lng}',
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
