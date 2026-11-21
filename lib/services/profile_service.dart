import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/places_repository.dart';
import '../data/users_repository.dart';
import '../models/app_user.dart';
import '../utils/contact.dart';
import 'auth_service.dart';

/// بيتابع هل المستخدم سجّل بياناته ولا لأ.
/// التسجيل بيتحفظ على الجهاز، فمش هيتطلب تاني غير لو مسح بيانات التطبيق.
class ProfileService extends ChangeNotifier {
  ProfileService({required this.auth, required this.users, this.places});

  final AuthService auth;
  final UsersRepository users;

  /// بيتستخدم لمسح أماكن صاحب العمل لما يمسح حسابه.
  final PlacesRepository? places;

  static const _kRegistered = 'profile.registered';
  static const _kName = 'profile.name';
  static const _kRole = 'profile.role';
  static const _kPhone = 'profile.phone';
  static const _kEmail = 'profile.email';

  bool _loaded = false;
  bool _registered = false;
  String _name = '';
  UserRole _role = UserRole.user;
  String _phone = '';
  String _email = '';

  bool get loaded => _loaded;
  bool get registered => _registered;

  /// اسم المستخدم المسجل (بيتكتب لوحده في التقييمات).
  String get name => _name;

  String get phone => _phone;
  String get email => _email;

  UserRole get role => _role;
  bool get isBusiness => _role == UserRole.business;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _registered = prefs.getBool(_kRegistered) ?? false;
    _name = prefs.getString(_kName) ?? '';
    _role = UserRole.fromId(prefs.getString(_kRole));
    _phone = prefs.getString(_kPhone) ?? '';
    _email = prefs.getString(_kEmail) ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    UserRole role = UserRole.user,
  }) async {
    await auth.ensureSignedIn();
    final uid = auth.userId;
    if (uid == null) {
      throw StateError('مش متسجل دخول');
    }
    await users.register(AppUser(
      uid: uid,
      name: name.trim(),
      phone: digitsOnly(phone),
      email: email.trim().toLowerCase(),
      role: role,
      createdAt: DateTime.now(),
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRegistered, true);
    await prefs.setString(_kName, name.trim());
    await prefs.setString(_kRole, role.id);
    await prefs.setString(_kPhone, digitsOnly(phone));
    await prefs.setString(_kEmail, email.trim().toLowerCase());
    _registered = true;
    _name = name.trim();
    _role = role;
    _phone = digitsOnly(phone);
    _email = email.trim().toLowerCase();
    notifyListeners();
  }

  /// مسح الحساب: البيانات، وحجز الرقم، وأماكن صاحب العمل. بعدها الجهاز بيرجع كأنه جديد.
  Future<void> deleteAccount() async {
    final uid = auth.userId;
    if (uid != null) {
      var phone = _phone;
      if (phone.isEmpty) {
        phone = (await users.getProfile(uid))?.phone ?? '';
      }
      if (_role == UserRole.business && places != null) {
        final mine = await places!.watchMine(uid).first;
        for (final p in mine) {
          await places!.deletePlace(p.id);
        }
      }
      await users.deleteUser(AppUser(
        uid: uid,
        name: _name,
        phone: phone,
        email: _email,
        role: _role,
        createdAt: DateTime.now(),
      ));
    }
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_kRegistered, _kName, _kRole, _kPhone, _kEmail]) {
      await prefs.remove(k);
    }
    _registered = false;
    _name = '';
    _phone = '';
    _email = '';
    _role = UserRole.user;
    await auth.signOut();
    notifyListeners();
  }
}
