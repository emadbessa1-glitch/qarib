import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../data/places_repository.dart';
import '../data/users_repository.dart';
import '../models/app_user.dart';
import '../models/place.dart';
import '../services/auth_service.dart';
import '../utils/contact.dart';
import 'place_details_screen.dart';

/// لوحة الأدمن: مراجعة الأماكن الجديدة والموافقة أو الرفض.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الأدمن'),
        actions: [
          if (auth.isAdmin)
            IconButton(
              tooltip: 'خروج',
              icon: const Icon(Icons.logout),
              onPressed: auth.signOut,
            ),
        ],
      ),
      body: auth.isAdmin ? const _AdminTabs() : const _AdminLogin(),
    );
  }
}

class _AdminLogin extends StatefulWidget {
  const _AdminLogin();

  @override
  State<_AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<_AdminLogin> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthService>().signInAdmin(
            _email.text,
            _password.text,
          );
    } catch (e) {
      if (mounted) setState(() => _error = 'الدخول فشل: اتأكد من الإيميل والباسورد');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.admin_panel_settings, size: 64),
        const SizedBox(height: 16),
        if (!AppConfig.useFirebase)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'وضع التجربة: ادخل بإيميل الأدمن المكتوب في config.dart وأي باسورد.',
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'الإيميل'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'الباسورد'),
          onSubmitted: (_) => _login(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _login,
          child: const Text('دخول'),
        ),
      ],
    );
  }
}

class _PendingList extends StatefulWidget {
  const _PendingList();

  @override
  State<_PendingList> createState() => _PendingListState();
}

class _PendingListState extends State<_PendingList> {
  late final Stream<List<Place>> _pending;

  @override
  void initState() {
    super.initState();
    _pending = context.read<PlacesRepository>().watchPending();
  }

  Future<void> _decide(Place place, PlaceStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PlacesRepository>().setStatus(place.id, status);
      messenger.showSnackBar(SnackBar(
        content: Text('${place.name}: ${status.label}'),
      ));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('العملية فشلت، حاول تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Place>>(
      stream: _pending,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('حصلت مشكلة في التحميل'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final places = snap.data!;
        if (places.isEmpty) {
          return const Center(child: Text('مفيش أماكن مستنية مراجعة 👌'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: places.length,
          itemBuilder: (context, i) {
            final p = places[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(p.category.icon, color: p.category.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p.name,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${p.category.label} • ${p.area}'),
                    Text(p.address),
                    Text(p.phone, textDirection: TextDirection.ltr),
                    if (p.description.isNotEmpty) Text(p.description),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _decide(p, PlaceStatus.approved),
                          icon: const Icon(Icons.check),
                          label: const Text('موافقة'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _decide(p, PlaceStatus.rejected),
                          icon: const Icon(Icons.close),
                          label: const Text('رفض'),
                        ),
                        TextButton.icon(
                          onPressed: () => callPhone(p.phone),
                          icon: const Icon(Icons.call),
                          label: const Text('اتصل للتأكد'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlaceDetailsScreen(place: p),
                            ),
                          ),
                          child: const Text('معاينة'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminTabs extends StatelessWidget {
  const _AdminTabs();

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'أماكن للمراجعة'),
              Tab(icon: Icon(Icons.people_outline), text: 'المستخدمين'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_PendingList(), _UsersList()],
            ),
          ),
        ],
      ),
    );
  }
}

/// بيانات المستخدمين المسجلين. بتظهر للأدمن بس.
class _UsersList extends StatefulWidget {
  const _UsersList();

  @override
  State<_UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<_UsersList> {
  late final Stream<List<AppUser>> _users;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _users = context.read<UsersRepository>().watchAll();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _date(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: _users,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('حصلت مشكلة في التحميل'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = _search.text.trim().toLowerCase();
        final all = snap.data!;
        final users = q.isEmpty
            ? all
            : all
                .where((u) =>
                    u.name.toLowerCase().contains(q) ||
                    u.phone.contains(q) ||
                    u.email.contains(q))
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الرقم أو الإيميل',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  helperText: 'العدد: ${all.length}',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? const Center(child: Text('مفيش مستخدمين'))
                  : ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final u = users[i];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(u.name),
                          subtitle: Text(
                            '${u.phone}\n${u.email}\nسجّل: ${_date(u.createdAt)}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            tooltip: 'اتصال',
                            icon: const Icon(Icons.call),
                            onPressed: () => callPhone(u.phone),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
