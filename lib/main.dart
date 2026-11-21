import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'data/demo_places_repository.dart';
import 'data/firestore_places_repository.dart';
import 'data/places_repository.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final PlacesRepository repository;
  final AuthService auth;

  if (AppConfig.useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    repository = FirestorePlacesRepository();
    auth = FirebaseAuthService();
    try {
      await auth.ensureSignedIn();
    } catch (_) {
      // من غير إنترنت التطبيق هيفتح، والتقييم/الإضافة هيحاولوا تاني بعدين.
    }
  } else {
    repository = DemoPlacesRepository();
    auth = DemoAuthService();
  }

  runApp(QaribApp(repository: repository, auth: auth));
}

class QaribApp extends StatelessWidget {
  const QaribApp({super.key, required this.repository, required this.auth});

  final PlacesRepository repository;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PlacesRepository>.value(value: repository),
        ChangeNotifierProvider<AuthService>.value(value: auth),
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
        home: const HomeScreen(),
      ),
    );
  }
}
