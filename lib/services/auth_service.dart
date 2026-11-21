import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';

/// صلاحيات الإدارة.
/// - [admin]: كل حاجة، ومنها بيانات المستخدمين وإضافة المديرين.
/// - [manager] (مدير): البلاغات، والموافقة على الأماكن، وتعديل بيانات الأماكن.
///   مش بيشوف بيانات المستخدمين.
enum StaffRole {
  none('none', ''),
  manager('manager', 'مدير'),
  admin('admin', 'أدمن');

  const StaffRole(this.id, this.label);
  final String id;
  final String label;

  static StaffRole fromId(String? id) => switch (id) {
        'admin' => StaffRole.admin,
        'manager' => StaffRole.manager,
        _ => StaffRole.none,
      };
}

/// عضو في الإدارة.
class StaffMember {
  const StaffMember(this.email, this.role);
  final String email;
  final StaffRole role;
}

/// تسجيل الدخول.
/// - الزوار وأصحاب الأماكن: دخول مجهول (Anonymous) تلقائي.
/// - الإدارة: إيميل وباسورد. الإيميل لازم يكون في collection اسمه `admins`
///   ومعاه role = admin أو manager. في وضع التجربة القايمة في [AppConfig].
abstract class AuthService extends ChangeNotifier {
  String? get userId;
  String? get email;
  StaffRole get staffRole;

  /// أدمن كامل الصلاحيات.
  bool get isAdmin => staffRole == StaffRole.admin;

  /// أدمن أو مدير.
  bool get isStaff => staffRole != StaffRole.none;

  Future<void> ensureSignedIn();
  Future<void> signInAdmin(String email, String password);

  /// أول مرة لمدير اتضاف من الأدمن: بيعمل باسورد لإيميله.
  Future<void> createStaffPassword(String email, String password);
  Future<void> signOut();
}

/// وضع التجربة: مفيش سيرفر. أي باسورد بيشتغل.
class DemoAuthService extends AuthService {
  DemoAuthService()
      : staff = <String, StaffRole>{
          for (final e in AppConfig.adminEmails) e: StaffRole.admin,
        };

  /// قايمة الإدارة في الذاكرة (بيشاركها [DemoStaffRepository]).
  final Map<String, StaffRole> staff;
  String? _email;

  @override
  String? get userId => 'demo-user';

  @override
  String? get email => _email;

  @override
  StaffRole get staffRole => staff[_email] ?? StaffRole.none;

  @override
  Future<void> ensureSignedIn() async {}

  @override
  Future<void> signInAdmin(String email, String password) async {
    final e = email.trim().toLowerCase();
    if (!staff.containsKey(e)) {
      throw Exception('الإيميل ده مش من الإدارة');
    }
    _email = e;
    notifyListeners();
  }

  @override
  Future<void> createStaffPassword(String email, String password) =>
      signInAdmin(email, password);

  /// بيتنادى لما قايمة الإدارة تتغير.
  void staffChanged() => notifyListeners();

  @override
  Future<void> signOut() async {
    _email = null;
    notifyListeners();
  }
}

/// الإدارة متسجلة في Firestore: admins/{email} وفيه role.
class FirebaseAuthService extends AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance {
    _auth.authStateChanges().listen((user) async {
      _role = await _checkRole(user);
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  StaffRole _role = StaffRole.none;

  Future<StaffRole> _checkRole(User? user) async {
    final e = user?.email?.trim().toLowerCase();
    if (e == null || e.isEmpty) return StaffRole.none;
    try {
      final doc = await _db.collection('admins').doc(e).get();
      if (!doc.exists) return StaffRole.none;
      // الـ documents القديمة من غير role بتتحسب أدمن.
      final role = doc.data()?['role'] as String?;
      return role == null ? StaffRole.admin : StaffRole.fromId(role);
    } catch (_) {
      return StaffRole.none;
    }
  }

  @override
  String? get userId => _auth.currentUser?.uid;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  StaffRole get staffRole => _role;

  @override
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<void> _afterStaffSignIn(User? user) async {
    _role = await _checkRole(user);
    if (_role == StaffRole.none) {
      await _auth.signOut();
      await _auth.signInAnonymously();
      throw Exception('الإيميل ده مش من الإدارة');
    }
    notifyListeners();
  }

  @override
  Future<void> signInAdmin(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _afterStaffSignIn(cred.user);
  }

  @override
  Future<void> createStaffPassword(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final role = await _checkRole(cred.user);
    if (role == StaffRole.none) {
      // الإيميل مش متضاف للإدارة: نمسح الحساب اللي لسه معمول.
      await cred.user?.delete();
      await _auth.signInAnonymously();
      throw Exception('الإيميل ده مش من الإدارة');
    }
    await _afterStaffSignIn(cred.user);
  }

  @override
  Future<void> signOut() async {
    _role = StaffRole.none;
    await _auth.signOut();
    await _auth.signInAnonymously();
  }
}

/// إدارة المديرين (للأدمن بس).
abstract class StaffRepository {
  Stream<List<StaffMember>> watchAll();
  Future<void> addManager(String email);
  Future<void> removeManager(String email);
}

class DemoStaffRepository implements StaffRepository {
  DemoStaffRepository(this.auth);
  final DemoAuthService auth;

  List<StaffMember> _list() => auth.staff.entries
      .map((e) => StaffMember(e.key, e.value))
      .toList()
    ..sort((a, b) => a.email.compareTo(b.email));

  @override
  Stream<List<StaffMember>> watchAll() async* {
    yield _list();
    yield* Stream<void>.multi((c) {
      void l() => c.add(null);
      auth.addListener(l);
      c.onCancel = () => auth.removeListener(l);
    }).map((_) => _list());
  }

  @override
  Future<void> addManager(String email) async {
    auth.staff.putIfAbsent(email.trim().toLowerCase(), () => StaffRole.manager);
    auth.staffChanged();
  }

  @override
  Future<void> removeManager(String email) async {
    final e = email.trim().toLowerCase();
    if (auth.staff[e] == StaffRole.manager) auth.staff.remove(e);
    auth.staffChanged();
  }
}

class FirestoreStaffRepository implements StaffRepository {
  FirestoreStaffRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  @override
  Stream<List<StaffMember>> watchAll() =>
      _db.collection('admins').snapshots().map((s) => s.docs
          .map((d) => StaffMember(
                d.id,
                d.data()['role'] == null
                    ? StaffRole.admin
                    : StaffRole.fromId(d.data()['role'] as String?),
              ))
          .toList()
        ..sort((a, b) => a.email.compareTo(b.email)));

  @override
  Future<void> addManager(String email) => _db
      .collection('admins')
      .doc(email.trim().toLowerCase())
      .set(<String, dynamic>{'role': 'manager'});

  @override
  Future<void> removeManager(String email) =>
      _db.collection('admins').doc(email.trim().toLowerCase()).delete();
}
