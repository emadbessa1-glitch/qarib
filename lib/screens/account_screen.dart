import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/profile_service.dart';
import 'legal_screen.dart';

/// حسابي: البيانات، والسياسات، ومسح الحساب.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _deleting = false;

  Future<void> _delete() async {
    final profile = context.read<ProfileService>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح حسابي؟'),
        content: Text(
          profile.isBusiness
              ? 'هتتمسح بياناتك والأماكن اللي ضفتها، ورقمك هيتحرر. مش هينفع ترجّعهم.'
              : 'هتتمسح بياناتك ورقمك هيتحرر. مش هينفع ترجّعها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('مسح نهائي'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await profile.deleteAccount();
      nav.popUntil((r) => r.isFirst);
      messenger.showSnackBar(
        const SnackBar(content: Text('اتمسح حسابك')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('المسح فشل، اتأكد من النت وحاول تاني')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>();
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(profile.name.isEmpty ? '—' : profile.name),
            subtitle: Text(profile.role.label),
          ),
          if (profile.phone.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(profile.phone, textDirection: TextDirection.ltr),
            ),
          if (profile.email.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(profile.email, textDirection: TextDirection.ltr),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('سياسة الخصوصية'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const LegalScreen.privacy(),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('شروط الاستخدام'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const LegalScreen.terms(),
            )),
          ),
          const Divider(),
          if (profile.registered)
            ListTile(
              leading: Icon(Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error),
              title: Text('مسح حسابي',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              trailing: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _deleting ? null : _delete,
            ),
        ],
      ),
    );
  }
}
