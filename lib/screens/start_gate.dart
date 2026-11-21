import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// بيقرر يفتح شاشة التسجيل ولا الرئيسية.
/// الأدمن المسجل دخول بيعدّي على طول.
class StartGate extends StatelessWidget {
  const StartGate({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>();
    final auth = context.watch<AuthService>();

    if (!profile.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (profile.registered || auth.isStaff) {
      return const HomeScreen();
    }
    return const RegisterScreen();
  }
}
