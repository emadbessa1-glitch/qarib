import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';

/// تسجيل الدخول.
/// - الزوار وأصحاب الأماكن: دخول مجهول (Anonymous) تلقائي، عشان يقدروا يقيّموا ويضيفوا.
/// - الأدمن: إيميل وباسورد. في وضع Firebase الإيميل لازم يكون في collection اسمه admins،
///   وفي وضع التجربة لازم يكون في [AppConfig.adminEmails].
abstract class AuthService extends ChangeNotifier {
  String? get userId;
  String? get email;
  bool get isAdmin;

  Future<void> ensureSignedIn();
  Future<void> signInAdmin(String email, String password);
  Future<void> signOut();
}

/// وضع التجربة: مفيش سيرفر. الأدمن بيدخل بأي إيميل من القائمة وأي باسورد.
class DemoAuthService extends AuthService {
  String? _email;

  @override
  String? get userId => 'demo-user';

  @override
  String? get email => _email;

  @override
  bool get isAdmin =>
      _email != null && AppConfig.adminEmails.contains(_email!.toLowerCase());

  @override
  Future<void> ensureSignedIn() async {}

  @override
  Future<void> signInAdmin(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (!AppConfig.adminEmails.contains(e)) {
      throw Exception('الإيميل ده مش أدمن');
    }
    _email = e;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _email = null;
    notifyListeners();
  }
}

/// الأدمن في وضع Firebase متحددين في قاعدة البيانات نفسها:
/// collection اسمه `admins`، وكل document اسمه إيميل الأدمن (حروف صغيرة).
/// تضيف أو تشيل أدمن من Firebase Console على طول، من غير ما تعدّل الكود.
class FirebaseAuthService extends AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance {
    _auth.authStateChanges().listen((user) async {
      _isAdmin = await _checkAdmin(user);
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _isAdmin = false;

  Future<bool> _checkAdmin(User? user) async {
    final e = user?.email?.trim().toLowerCase();
    if (e == null || e.isEmpty) return false;
    try {
      final doc = await _db.collection('admins').doc(e).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  String? get userId => _auth.currentUser?.uid;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  bool get isAdmin => _isAdmin;

  @override
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  @override
  Future<void> signInAdmin(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    _isAdmin = await _checkAdmin(cred.user);
    if (!_isAdmin) {
      await _auth.signOut();
      await _auth.signInAnonymously();
      throw Exception('الإيميل ده مش أدمن');
    }
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _isAdmin = false;
    await _auth.signOut();
    await _auth.signInAnonymously();
  }
}
