import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config.dart';

/// بيقارن رقم النسخة اللي على الموبايل بآخر نسخة اتنشرت،
/// ولو فيه أحدث بيظهر للمستخدم تنبيه "فيه تحديث جديد".
class UpdateService extends ChangeNotifier {
  int? _current;
  int? _latest;

  bool get hasUpdate =>
      _current != null && _latest != null && _latest! > _current!;

  /// بيطلع رقم النسخة من نص الـ Release، بالشكل build=123
  static int? parseBuild(String body) {
    final m = RegExp(r'build=(\d+)').firstMatch(body);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  /// مع --split-per-abi أندرويد بيزوّد رقم النسخة (ABI × 1000)،
  /// فبناخد آخر 3 أرقام عشان نقارن برقم البناء الحقيقي.
  static int? currentBuildFrom(String buildNumber) {
    final n = int.tryParse(buildNumber);
    return n == null ? null : n % 1000;
  }

  Future<void> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _current = currentBuildFrom(info.buildNumber);
      final res = await http
          .get(Uri.parse(AppConfig.latestReleaseApi))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final body = (jsonDecode(res.body) as Map<String, dynamic>)['body'];
      _latest = body is String ? parseBuild(body) : null;
      notifyListeners();
    } catch (_) {
      // من غير نت أو لو حصل أي خطأ: مفيش تنبيه، والتطبيق يكمّل عادي.
    }
  }
}
