import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/users_repository.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

/// بيتابع هل المستخدم سجّل بياناته ولا لأ.
/// التسجيل بيتحفظ على الجهاز، فمش هيتطلب تاني غير لو مسح بيانات التطبيق.
class ProfileService extends ChangeNotifier {
  ProfileService({required this.auth, required this.users});

  final AuthService auth;
  final UsersRepository users;

  static const _kRegistered = 'profile.registered';
  static const _kName = 'profile.name';

  bool _loaded = false;
  bool _registered = false;
  String _name = '';

  bool get loaded => _loaded;
  bool get registered => _registered;

  /// اسم المستخدم المسجل (بيتكتب لوحده في التقييمات).
  String get name => _name;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _registered = prefs.getBool(_kRegistered) ?? false;
    _name = prefs.getString(_kName) ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
  }) async {
    await auth.ensureSignedIn();
    final uid = auth.userId;
    if (uid == null) {
      throw StateError('مش متسجل دخول');
    }
    await users.saveProfile(AppUser(
      uid: uid,
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRegistered, true);
    await prefs.setString(_kName, name.trim());
    _registered = true;
    _name = name.trim();
    notifyListeners();
  }
}
