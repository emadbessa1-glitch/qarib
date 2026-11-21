import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// رقم الموبايل متسجل قبل كده بنفس نوع الحساب.
class PhoneTakenException implements Exception {
  const PhoneTakenException();
  @override
  String toString() => 'الرقم ده متسجل قبل كده';
}

/// كل رقم موبايل بيتسجل مرة واحدة كمستخدم، ومرة واحدة كصاحب عمل.
String phoneClaimId(UserRole role, String phone) => '${role.id}_$phone';

/// بيانات المستخدمين المسجلين.
abstract class UsersRepository {
  /// بيسجل المستخدم. بيرمي [PhoneTakenException] لو الرقم متسجل لحساب تاني بنفس النوع.
  Future<void> register(AppUser user);

  /// كل المستخدمين (الأحدث الأول). للأدمن بس.
  Stream<List<AppUser>> watchAll();

  /// الأدمن (أو المستخدم نفسه) بيمسح الحساب، والرقم بيتحرر ويقدر يتسجل تاني.
  Future<void> deleteUser(AppUser user);

  /// بيانات مستخدم معين (المستخدم نفسه أو الأدمن).
  Future<AppUser?> getProfile(String uid);
}

class DemoUsersRepository implements UsersRepository {
  final List<AppUser> _users = <AppUser>[];
  final Map<String, String> _claims = <String, String>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<AppUser> _sorted() => List<AppUser>.of(_users)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> register(AppUser user) async {
    final claim = phoneClaimId(user.role, user.phone);
    final owner = _claims[claim];
    if (owner != null && owner != user.uid) {
      throw const PhoneTakenException();
    }
    _claims[claim] = user.uid;
    _users
      ..removeWhere((u) => u.uid == user.uid)
      ..add(user);
    _changes.add(null);
  }

  @override
  Stream<List<AppUser>> watchAll() async* {
    yield _sorted();
    yield* _changes.stream.map((_) => _sorted());
  }

  @override
  Future<AppUser?> getProfile(String uid) async {
    for (final u in _users) {
      if (u.uid == uid) return u;
    }
    return null;
  }

  @override
  Future<void> deleteUser(AppUser user) async {
    _users.removeWhere((u) => u.uid == user.uid);
    _claims.removeWhere((_, uid) => uid == user.uid);
    _changes.add(null);
  }
}

/// Firestore:
///   users/{uid}                      ← بيانات المستخدم (للأدمن بس)
///   phoneClaims/{role_phone}         ← بيحجز الرقم لحساب واحد من كل نوع
class FirestoreUsersRepository implements UsersRepository {
  FirestoreUsersRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> register(AppUser user) async {
    final claimRef =
        _db.collection('phoneClaims').doc(phoneClaimId(user.role, user.phone));
    final userRef = _db.collection('users').doc(user.uid);
    try {
      await _db.runTransaction((tx) async {
        final claim = await tx.get(claimRef);
        if (claim.exists && claim.data()?['uid'] != user.uid) {
          throw const PhoneTakenException();
        }
        if (!claim.exists) {
          tx.set(claimRef, <String, dynamic>{
            'uid': user.uid,
            'role': user.role.id,
            'phone': user.phone,
          });
        }
        tx.set(userRef, user.toMap());
      });
    } on FirebaseException catch (e) {
      // قواعد الأمان بترفض قراءة رقم محجوز لحساب تاني، فده معناه إن الرقم متسجل.
      if (e.code == 'permission-denied') throw const PhoneTakenException();
      rethrow;
    }
  }

  @override
  Stream<List<AppUser>> watchAll() => _db
      .collection('users')
      .orderBy('createdAt', descending: true)
      .limit(500)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => AppUser.fromMap(d.id, d.data()))
          .toList(growable: false));

  @override
  Future<AppUser?> getProfile(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    return d.exists ? AppUser.fromMap(d.id, d.data()!) : null;
  }

  @override
  Future<void> deleteUser(AppUser user) {
    final batch = _db.batch()
      ..delete(_db.collection('users').doc(user.uid))
      ..delete(_db
          .collection('phoneClaims')
          .doc(phoneClaimId(user.role, user.phone)));
    return batch.commit();
  }
}
