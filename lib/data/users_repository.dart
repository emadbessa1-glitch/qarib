import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// بيانات المستخدمين المسجلين.
abstract class UsersRepository {
  Future<void> saveProfile(AppUser user);

  /// كل المستخدمين (الأحدث الأول). للأدمن بس.
  Stream<List<AppUser>> watchAll();
}

class DemoUsersRepository implements UsersRepository {
  final List<AppUser> _users = <AppUser>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<AppUser> _sorted() => List<AppUser>.of(_users)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> saveProfile(AppUser user) async {
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
}

/// users/{uid} في Firestore. قواعد الأمان بتمنع أي حد غير الأدمن يقرا بيانات غيره.
class FirestoreUsersRepository implements UsersRepository {
  FirestoreUsersRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> saveProfile(AppUser user) {
    return _db.collection('users').doc(user.uid).set(user.toMap());
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
}
