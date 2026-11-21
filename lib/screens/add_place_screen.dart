import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../data/places_repository.dart';
import '../models/category.dart';
import '../models/place.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../utils/contact.dart';
import 'location_picker_screen.dart';

/// صاحب المكان بيسجل مكانه. بيتبعت للأدمن للمراجعة قبل ما يظهر.
class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _hours = TextEditingController();
  final _description = TextEditingController();

  PlaceCategory _category = PlaceCategory.pharmacy;
  bool _whatsappEnabled = true;
  bool _whatsappSameAsPhone = true;
  LatLng? _location;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name, _area, _address, _phone, _whatsapp, _hours, _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    final service = context.read<LocationService>();
    await service.refresh();
    if (!mounted) return;
    if (service.position != null) {
      setState(() => _location = service.position);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(service.error ?? 'معرفناش نحدد موقعك'),
      ));
    }
  }

  Future<void> _pickOnMap() async {
    final start = _location ??
        context.read<LocationService>().position ??
        LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (_) => LocationPickerScreen(initial: start),
      ),
    );
    if (picked != null && mounted) setState(() => _location = picked);
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'مطلوب' : null;

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'مطلوب';
    return isValidEgyptianPhone(v) ? null : 'رقم مش صحيح';
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('حدد مكان المحل على الخريطة'),
      ));
      return;
    }

    setState(() => _saving = true);
    final repo = context.read<PlacesRepository>();
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      await auth.ensureSignedIn();
      final phone = digitsOnly(_phone.text);
      await repo.submitPlace(Place(
        id: '',
        name: _name.text.trim(),
        category: _category,
        area: _area.text.trim(),
        address: _address.text.trim(),
        phone: phone,
        whatsapp: !_whatsappEnabled
            ? ''
            : (_whatsappSameAsPhone ? phone : digitsOnly(_whatsapp.text)),
        lat: _location!.latitude,
        lng: _location!.longitude,
        workingHours: _hours.text.trim(),
        description: _description.text.trim(),
        ownerId: auth.userId,
        createdAt: DateTime.now(),
      ));
      messenger.showSnackBar(const SnackBar(
        content: Text('تم الإرسال! المكان هيظهر بعد مراجعة الإدارة'),
      ));
      nav.pop();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('حصلت مشكلة، اتأكد من النت وحاول تاني'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(title: const Text('أضف مكانك')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'سجّل بيانات محلك أو عيادتك، وهتظهر للناس بعد ما الإدارة تراجعها.',
            ),
            gap,
            DropdownButtonFormField<PlaceCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'نوع الخدمة'),
              items: [
                for (final c in PlaceCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (c) => setState(() => _category = c ?? _category),
            ),
            gap,
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسم المكان'),
              validator: _required,
            ),
            gap,
            TextFormField(
              controller: _area,
              decoration: const InputDecoration(
                labelText: 'المنطقة',
                hintText: 'مثلاً: مدينة نصر',
              ),
              validator: _required,
            ),
            gap,
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'العنوان بالتفصيل'),
              validator: _required,
            ),
            gap,
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'رقم التليفون'),
              validator: _phoneValidator,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _whatsappEnabled,
              onChanged: (v) => setState(() => _whatsappEnabled = v),
              title: const Text('تفعيل التواصل بالواتساب'),
              subtitle: Text(_whatsappEnabled
                  ? 'العملاء هيكلموك على الواتساب'
                  : 'العملاء هيكلموك بالشات جوه التطبيق'),
            ),
            if (_whatsappEnabled)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _whatsappSameAsPhone,
                onChanged: (v) =>
                    setState(() => _whatsappSameAsPhone = v ?? true),
                title: const Text('الواتساب على نفس رقم التليفون'),
              ),
            if (_whatsappEnabled && !_whatsappSameAsPhone) ...[
              TextFormField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'رقم الواتساب'),
                validator: _phoneValidator,
              ),
              gap,
            ],
            TextFormField(
              controller: _hours,
              decoration: const InputDecoration(
                labelText: 'مواعيد العمل (اختياري)',
                hintText: 'مثلاً: من 9 ص لـ 11 م',
              ),
            ),
            gap,
            TextFormField(
              controller: _description,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'وصف (اختياري)',
                hintText: 'خدمات، تخصص، توصيل...',
              ),
            ),
            gap,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _location == null
                          ? 'لسه محددتش مكان المحل'
                          : 'تم تحديد المكان ✓',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _useMyLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('أنا في المحل دلوقتي'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickOnMap,
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('اختار من الخريطة'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إرسال للمراجعة'),
            ),
          ],
        ),
      ),
    );
  }
}
