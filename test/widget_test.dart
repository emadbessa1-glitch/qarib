import 'package:flutter_test/flutter_test.dart';
import 'package:qarib/data/chat_repository.dart';
import 'package:qarib/data/demo_places_repository.dart';
import 'package:qarib/data/users_repository.dart';
import 'package:qarib/main.dart';
import 'package:qarib/models/app_user.dart';
import 'package:qarib/services/auth_service.dart';
import 'package:qarib/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<QaribApp> _app() async {
  final auth = DemoAuthService();
  final users = DemoUsersRepository();
  final profile = ProfileService(auth: auth, users: users);
  await profile.load();
  return QaribApp(
    repository: DemoPlacesRepository(),
    users: users,
    chats: DemoChatRepository(),
    auth: auth,
    profile: profile,
  );
}

void main() {
  testWidgets('New user sees the registration screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(await _app());
    await tester.pump();

    expect(find.text('أهلاً بيك في قريب'), findsOneWidget);
    expect(find.text('صاحب عمل'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ابدأ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ابدأ'), findsOneWidget);
    expect(find.textContaining('مشفّرة'), findsOneWidget);
  });

  testWidgets('Registered user goes to home', (tester) async {
    SharedPreferences.setMockInitialValues({'profile.registered': true});
    await tester.pumpWidget(await _app());
    await tester.pump();

    expect(find.text('قريب'), findsOneWidget);
    expect(find.text('صيدليات'), findsOneWidget);
    // المستخدم العادي مالوش زرار إضافة مكان.
    expect(find.text('أضف مكانك'), findsNothing);
  });

  testWidgets('Business owner sees add-place button', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'profile.registered': true, 'profile.role': 'business'});
    await tester.pumpWidget(await _app());
    await tester.pump();

    expect(find.text('أضف مكانك'), findsOneWidget);
  });

  test('register saves profile and marks device registered', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = DemoAuthService();
    final users = DemoUsersRepository();
    final profile = ProfileService(auth: auth, users: users);
    await profile.load();
    expect(profile.registered, isFalse);

    await profile.register(
      name: 'أحمد',
      phone: '01012345678',
      email: 'Ahmed@Example.com',
      role: UserRole.business,
    );

    expect(profile.registered, isTrue);
    expect(profile.name, 'أحمد');
    expect(profile.isBusiness, isTrue);
    final saved = await users.watchAll().first;
    expect(saved.single.email, 'ahmed@example.com');
    expect(saved.single.phone, '01012345678');
    expect(saved.single.role, UserRole.business);
  });
}
