import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'data/chat_repository.dart';
import 'data/demo_places_repository.dart';
import 'data/firestore_places_repository.dart';
import 'data/places_repository.dart';
import 'data/reports_repository.dart';
import 'data/users_repository.dart';
import 'firebase_options.dart';
import 'screens/start_gate.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/profile_service.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final PlacesRepository repository;
  final UsersRepository users;
  final ChatRepository chats;
  final ReportsRepository reports;
  final AuthService auth;

  if (AppConfig.useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    repository = FirestorePlacesRepository();
    users = FirestoreUsersRepository();
    chats = FirestoreChatRepository();
    reports = FirestoreReportsRepository();
    auth = FirebaseAuthService();
    try {
      await auth.ensureSignedIn();
    } catch (_) {
      // من غير إنترنت التطبيق هيفتح، والتقييم/الإضافة هيحاولوا تاني بعدين.
    }
  } else {
    repository = DemoPlacesRepository();
    users = DemoUsersRepository();
    chats = DemoChatRepository();
    reports = DemoReportsRepository();
    auth = DemoAuthService();
  }

  final profile =
      ProfileService(auth: auth, users: users, places: repository);
  await profile.load();

  runApp(QaribApp(
    repository: repository,
    users: users,
    chats: chats,
    reports: reports,
    auth: auth,
    profile: profile,
  ));
}

class QaribApp extends StatelessWidget {
  const QaribApp({
    super.key,
    required this.repository,
    required this.users,
    required this.chats,
    required this.reports,
    required this.auth,
    required this.profile,
  });

  final PlacesRepository repository;
  final UsersRepository users;
  final ChatRepository chats;
  final ReportsRepository reports;
  final AuthService auth;
  final ProfileService profile;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PlacesRepository>.value(value: repository),
        Provider<UsersRepository>.value(value: users),
        Provider<ChatRepository>.value(value: chats),
        Provider<ReportsRepository>.value(value: reports),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<ProfileService>.value(value: profile),
        ChangeNotifierProvider<UpdateService>(
          create: (_) => UpdateService()..check(),
        ),
        ChangeNotifierProvider<LocationService>(
          create: (_) => LocationService()..refresh(),
        ),
      ],
      child: MaterialApp(
        title: 'قريب',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF00897B),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const StartGate(),
      ),
    );
  }
}
