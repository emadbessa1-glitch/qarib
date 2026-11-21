import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../data/places_repository.dart';
import '../data/reports_repository.dart';
import '../data/users_repository.dart';
import '../models/app_user.dart';
import '../models/place.dart';
import '../services/auth_service.dart';
import '../utils/contact.dart';
import 'add_place_screen.dart';
import 'place_details_screen.dart';

/// لوحة الأدمن: مراجعة الأماكن الجديدة والموافقة أو الرفض.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(auth.isStaff
            ? 'لوحة الإدارة (${auth.staffRole.label})'
            : 'لوحة الإدارة'),
        actions: [
          if (auth.isStaff)
            IconButton(
              tooltip: 'خروج',
              icon: const Icon(Icons.logout),
              onPressed: auth.signOut,
            ),
        ],
      ),
      body: auth.isStaff
          ? _AdminTabs(isAdmin: auth.isAdmin)
          : const _AdminLogin(),
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
  bool _firstTime = false;
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
    final auth = context.read<AuthService>();
    try {
      if (_firstTime) {
        if (_password.text.length < 8) {
          setState(() => _error = 'الباسورد لازم يكون 8 حروف على الأقل');
          return;
        }
        await auth.createStaffPassword(_email.text, _password.text);
      } else {
        await auth.signInAdmin(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = _firstTime
            ? 'معرفناش نعمل الحساب: اتأكد إن الأدمن ضاف إيميلك، أو إن الإيميل مالوش باسورد قبل كده'
            : 'الدخول فشل: اتأكد من الإيميل والباسورد');
      }
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
          child: Text(_firstTime ? 'اعمل الباسورد وادخل' : 'دخول'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _firstTime = !_firstTime;
            _error = null;
          }),
          child: Text(_firstTime
              ? 'عندي باسورد بالفعل'
              : 'أول مرة؟ (مدير جديد) اعمل باسورد لإيميلك'),
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
                    Text('${p.category.label} • ${p.locationLabel} • ${p.governorate}'),
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
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AddPlaceScreen(editing: p),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('تعديل'),
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
  const _AdminTabs({required this.isAdmin});

  /// الأدمن بيشوف كمان المستخدمين والإدارة. المدير لأ.
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: isAdmin ? 4 : 2,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              const Tab(icon: Icon(Icons.fact_check_outlined), text: 'أماكن للمراجعة'),
              const Tab(icon: Icon(Icons.flag_outlined), text: 'البلاغات'),
              if (isAdmin) ...const [
                Tab(icon: Icon(Icons.people_outline), text: 'المستخدمين'),
                Tab(icon: Icon(Icons.badge_outlined), text: 'الإدارة'),
              ],
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const _PendingList(),
                const _ReportsList(),
                if (isAdmin) ...const [_UsersList(), _StaffList()],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// الأدمن بيضيف أو يشيل مديرين.
class _StaffList extends StatefulWidget {
  const _StaffList();

  @override
  State<_StaffList> createState() => _StaffListState();
}

class _StaffListState extends State<_StaffList> {
  late final Stream<List<StaffMember>> _staff;
  final _email = TextEditingController();

  @override
  void initState() {
    super.initState();
    _staff = context.read<StaffRepository>().watchAll();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final email = _email.text.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب إيميل صحيح')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<StaffRepository>().addManager(email);
      _email.clear();
      messenger.showSnackBar(SnackBar(
        content: Text('اتضاف $email كمدير. يفتح لوحة الإدارة ويدوس "أول مرة؟" ويعمل باسورد.'),
      ));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('الإضافة فشلت، حاول تاني')),
      );
    }
  }

  Future<void> _remove(StaffMember m) async {
    final repo = context.read<StaffRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('شيل المدير؟'),
        content: Text('${m.email} مش هيقدر يدخل لوحة الإدارة تاني.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('شيل'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.removeManager(m.email);
      messenger.showSnackBar(SnackBar(content: Text('اتشال ${m.email}')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('العملية فشلت، حاول تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'إيميل المدير الجديد',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: const Text('إضافة مدير')),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'المدير بيقدر يتابع البلاغات، ويوافق على الأماكن، ويعدّل بياناتها. '
            'مش بيشوف بيانات المستخدمين.',
          ),
        ),
        Expanded(
          child: StreamBuilder<List<StaffMember>>(
            stream: _staff,
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(child: Text('حصلت مشكلة في التحميل'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final staff = snap.data!;
              return ListView(
                children: [
                  for (final m in staff)
                    ListTile(
                      leading: Icon(m.role == StaffRole.admin
                          ? Icons.admin_panel_settings
                          : Icons.badge_outlined),
                      title: Text(m.email, textDirection: TextDirection.ltr),
                      subtitle: Text(m.role.label),
                      trailing: m.role == StaffRole.manager
                          ? IconButton(
                              tooltip: 'شيل',
                              icon: const Icon(Icons.person_remove_outlined),
                              onPressed: () => _remove(m),
                            )
                          : null,
                    ),
                ],
              );
            },
          ),
        ),
      ],
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

  Future<void> _confirmDelete(AppUser u) async {
    final repo = context.read<UsersRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح المستخدم؟'),
        content: Text(
          'هيتمسح ${u.name} (${u.phone})، والرقم هيقدر يتسجل تاني '
          'كـ${u.role.label}. مش هينفع ترجّعه بعد المسح.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.deleteUser(u);
      messenger.showSnackBar(SnackBar(content: Text('اتمسح ${u.name}')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('المسح فشل، حاول تاني')),
      );
    }
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
                          title: Text('${u.name} • ${u.role.label}'),
                          subtitle: Text(
                            '${u.phone}\n${u.email}\nسجّل: ${_date(u.createdAt)}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'اتصال',
                                icon: const Icon(Icons.call),
                                onPressed: () => callPhone(u.phone),
                              ),
                              IconButton(
                                tooltip: 'مسح المستخدم',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(u),
                              ),
                            ],
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

/// البلاغات: الأدمن يمسح المحتوى المسيء أو يقفل البلاغ.
class _ReportsList extends StatefulWidget {
  const _ReportsList();

  @override
  State<_ReportsList> createState() => _ReportsListState();
}

class _ReportsListState extends State<_ReportsList> {
  late final Stream<List<Report>> _reports;

  @override
  void initState() {
    super.initState();
    _reports = context.read<ReportsRepository>().watchOpen();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('العملية فشلت، حاول تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ReportsRepository>();
    final places = context.read<PlacesRepository>();
    return StreamBuilder<List<Report>>(
      stream: _reports,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('حصلت مشكلة في التحميل'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snap.data!;
        if (reports.isEmpty) {
          return const Center(child: Text('مفيش بلاغات 👌'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: reports.length,
          itemBuilder: (context, i) {
            final r = reports[i];
            final d = r.createdAt;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('بلاغ عن ${r.target.label} • ${r.reason}',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text('${d.day}/${d.month}/${d.year}',
                        style: Theme.of(context).textTheme.bodySmall),
                    if (r.excerpt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Text(r.excerpt),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (r.target == ReportTarget.review)
                          FilledButton.tonal(
                            onPressed: () => _run(() async {
                              await repo.deleteReview(r.placeId, r.itemId);
                              await repo.dismiss(r.id);
                            }, 'اتمسح التقييم'),
                            child: const Text('مسح التقييم'),
                          ),
                        if (r.target == ReportTarget.message)
                          FilledButton.tonal(
                            onPressed: () => _run(() async {
                              await repo.deleteMessage(r.chatId, r.itemId);
                              await repo.dismiss(r.id);
                            }, 'اتمسحت الرسالة'),
                            child: const Text('مسح الرسالة'),
                          ),
                        if (r.target == ReportTarget.place && r.placeId.isNotEmpty)
                          FilledButton.tonal(
                            onPressed: () => _run(() async {
                              await places.setStatus(
                                  r.placeId, PlaceStatus.rejected);
                              await repo.dismiss(r.id);
                            }, 'المكان اتشال من التطبيق'),
                            child: const Text('إخفاء المكان'),
                          ),
                        OutlinedButton(
                          onPressed: () =>
                              _run(() => repo.dismiss(r.id), 'اتقفل البلاغ'),
                          child: const Text('تجاهل البلاغ'),
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
