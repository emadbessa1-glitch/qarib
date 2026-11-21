/// بيانات المستخدم اللي بيسجلها أول مرة يفتح التطبيق.
/// بتتحفظ في Firestore وماحدش يشوفها غير الأدمن (والمستخدم نفسه).
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String phone;
  final String email;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'phone': phone,
        'email': email,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
