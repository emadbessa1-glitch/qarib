import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/places_repository.dart';
import '../models/place.dart';
import '../services/auth_service.dart';
import '../utils/contact.dart';
import 'add_place_screen.dart';

/// صاحب العمل: أماكنه وحالتها، وتفعيل/قفل التواصل بالواتساب.
class MyPlacesScreen extends StatefulWidget {
  const MyPlacesScreen({super.key});

  @override
  State<MyPlacesScreen> createState() => _MyPlacesScreenState();
}

class _MyPlacesScreenState extends State<MyPlacesScreen> {
  Stream<List<Place>>? _mine;
  String? _forUser;

  Future<void> _editWhatsapp(Place place) async {
    final repo = context.read<PlacesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _WhatsappDialog(place: place),
    );
    if (result == null) return;
    try {
      await repo.updateWhatsapp(place.id, result);
      messenger.showSnackBar(SnackBar(
        content: Text(result.isEmpty
            ? 'تم. العملاء هيكلموك بالشات جوه التطبيق'
            : 'تم تفعيل الواتساب'),
      ));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('التعديل فشل، حاول تاني')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthService>().userId;
    if (myId != null && myId != _forUser) {
      _forUser = myId;
      _mine = context.read<PlacesRepository>().watchMine(myId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('أماكني')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddPlaceScreen()),
        ),
        icon: const Icon(Icons.add_business),
        label: const Text('أضف مكان'),
      ),
      body: _mine == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Place>>(
              stream: _mine,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('حصلت مشكلة في التحميل'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final places = snap.data!;
                if (places.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'لسه ماضفتش أماكن. دوس "أضف مكان" عشان تبدأ.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: places.length,
                  itemBuilder: (context, i) {
                    final p = places[i];
                    final statusColor = switch (p.status) {
                      PlaceStatus.approved => Colors.green,
                      PlaceStatus.pending => Colors.orange,
                      PlaceStatus.rejected => Colors.red,
                    };
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                ),
                                Chip(
                                  label: Text(p.status.label),
                                  side: BorderSide(color: statusColor),
                                ),
                              ],
                            ),
                            Text('${p.locationLabel} • ${p.address}'),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                p.hasWhatsapp ? Icons.chat : Icons.forum,
                                color: p.hasWhatsapp
                                    ? const Color(0xFF25D366)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(p.hasWhatsapp
                                  ? 'العملاء بيكلموك واتساب'
                                  : 'العملاء بيكلموك بالشات جوه التطبيق'),
                              subtitle: p.hasWhatsapp
                                  ? Text(p.whatsapp,
                                      textDirection: TextDirection.ltr)
                                  : null,
                              trailing: TextButton(
                                onPressed: () => _editWhatsapp(p),
                                child: const Text('تغيير'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _WhatsappDialog extends StatefulWidget {
  const _WhatsappDialog({required this.place});

  final Place place;

  @override
  State<_WhatsappDialog> createState() => _WhatsappDialogState();
}

class _WhatsappDialogState extends State<_WhatsappDialog> {
  late bool _enabled = widget.place.hasWhatsapp;
  late final _number = TextEditingController(
    text: widget.place.hasWhatsapp ? widget.place.whatsapp : widget.place.phone,
  );
  String? _error;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  void _save() {
    if (!_enabled) {
      Navigator.of(context).pop('');
      return;
    }
    if (!isValidEgyptianPhone(_number.text)) {
      setState(() => _error = 'رقم مش صحيح');
      return;
    }
    Navigator.of(context).pop(digitsOnly(_number.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('طريقة تواصل العملاء'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: const Text('تفعيل الواتساب'),
            subtitle: Text(_enabled
                ? 'العملاء هيكلموك على الواتساب'
                : 'العملاء هيكلموك بالشات جوه التطبيق'),
          ),
          if (_enabled)
            TextField(
              controller: _number,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'رقم الواتساب',
                errorText: _error,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _save, child: const Text('حفظ')),
      ],
    );
  }
}
