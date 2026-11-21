/// نوع الحساب: مستخدم عادي بيدوّر على خدمات، أو صاحب عمل بيعرض مكانه.
enum UserRole {
  user('user', 'مستخدم'),
  business('business', 'صاحب عمل');

  const UserRole(this.id, this.label);
  final String id;
  final String label;

  static UserRole fromId(String? id) =>
      UserRole.values.firstWhere((r) => r.id == id, orElse: () => UserRole.user);
}

/// بيانات المستخدم اللي بيسجلها أول مرة يفتح التطبيق.
/// بتتحفظ في Firestore وماحدش يشوفها غير الأدمن (والمستخدم نفسه).
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.role = UserRole.user,
  });

  final String uid;
  final String name;
  final String phone;
  final String email;
  final DateTime createdAt;
  final UserRole role;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.id,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: UserRole.fromId(map['role'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
