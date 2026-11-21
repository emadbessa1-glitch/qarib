import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../services/profile_service.dart';
import '../utils/contact.dart';
import 'admin_screen.dart';

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());

/// أول شاشة: الاسم والتليفون والإيميل قبل استخدام التطبيق.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;
  UserRole _role = UserRole.user;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ProfileService>().register(
            name: _name.text,
            phone: digitsOnly(_phone.text),
            email: _email.text,
            role: _role,
          );
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('معرفناش نحفظ بياناتك، اتأكد من النت وحاول تاني'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: 12);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              Icon(Icons.near_me, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('أهلاً بيك في قريب',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'سجّل بياناتك مرة واحدة عشان تبدأ تدوّر على الخدمات القريبة منك.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text('إنت مين؟', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.user,
                    icon: Icon(Icons.search),
                    label: Text('بدوّر على خدمة'),
                  ),
                  ButtonSegment(
                    value: UserRole.business,
                    icon: Icon(Icons.storefront),
                    label: Text('صاحب عمل'),
                  ),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                _role == UserRole.business
                    ? 'هتقدر تضيف مكانك، وترد على العملاء بالشات أو الواتساب.'
                    : 'هتقدر تدوّر على الخدمات القريبة منك وتتواصل معاهم.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'اكتب اسمك'
                    : null,
              ),
              gap,
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'رقم الموبايل',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) => (v != null && isValidEgyptianPhone(v))
                    ? null
                    : 'اكتب رقم موبايل صحيح',
              ),
              gap,
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'الإيميل',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) =>
                    (v != null && isValidEmail(v)) ? null : 'اكتب إيميل صحيح',
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Text(
                'بياناتك محفوظة ومحدش بيشوفها غير إدارة التطبيق.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ابدأ'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdminScreen()),
                ),
                child: const Text('دخول الإدارة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
