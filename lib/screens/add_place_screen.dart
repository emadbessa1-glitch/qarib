import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../data/egypt_locations.dart';
import '../data/places_repository.dart';
import '../models/category.dart';
import '../models/place.dart';
import '../models/working_hours.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../utils/contact.dart';
import '../widgets/schedule_editor.dart';
import 'location_picker_screen.dart';

/// صاحب المكان بيسجل مكانه. بيتبعت للأدمن للمراجعة قبل ما يظهر.
class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key, this.editing});

  /// لو مش null: الإدارة (أدمن أو مدير) بتعدّل بيانات مكان موجود.
  final Place? editing;

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _areaFocus = FocusNode();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _description = TextEditingController();

  WeeklySchedule _schedule = const WeeklySchedule();
  String? _scheduleError;

  /// مواعيد مكتوبة نص في الأماكن القديمة (قبل جدول المواعيد).
  String _legacyHours = '';

  PlaceCategory _category = PlaceCategory.pharmacy;
  String? _governorate;
  String? _city;

  /// المناطق اللي متسجلة قبل كده في كل مدينة، عشان صاحب العمل يختار منها.
  final Map<String, Set<String>> _knownAreas = <String, Set<String>>{};
  StreamSubscription<List<Place>>? _areasSub;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.name;
      _category = e.category;
      _governorate = governorates.contains(e.governorate) ? e.governorate : null;
      _city = _governorate != null && citiesOf(_governorate!).contains(e.city)
          ? e.city
          : null;
      _area.text = e.area;
      _address.text = e.address;
      _phone.text = e.phone;
      _whatsappEnabled = e.hasWhatsapp;
      _whatsappSameAsPhone = !e.hasWhatsapp || e.whatsapp == e.phone;
      _whatsapp.text = e.whatsapp;
      _schedule = e.schedule;
      if (!e.hasSchedule) _legacyHours = e.workingHours;
      _description.text = e.description;
      _location = e.location;
    }
    _areasSub = context.read<PlacesRepository>().watchApproved().listen((all) {
      final map = <String, Set<String>>{};
      for (final p in all) {
        if (p.city.isEmpty || p.area.isEmpty) continue;
        (map[p.city] ??= <String>{}).add(p.area);
      }
      if (mounted) {
        setState(() => _knownAreas
          ..clear()
          ..addAll(map));
      }
    }, onError: (_) {});
  }
  bool _whatsappEnabled = true;
  bool _whatsappSameAsPhone = true;
  LatLng? _location;
  bool _saving = false;

  @override
  void dispose() {
    _areasSub?.cancel();
    _areaFocus.dispose();
    for (final c in [
      _name, _area, _address, _phone, _whatsapp, _description,
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
    final formOk = _form.currentState!.validate();
    setState(() => _scheduleError =
        _schedule.isEmpty ? 'اختار يوم واحد على الأقل وحدد ساعاته' : null);
    if (!formOk || _scheduleError != null) return;
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
      final editing = widget.editing;
      final place = Place(
        id: editing?.id ?? '',
        name: _name.text.trim(),
        category: _category,
        area: _area.text.trim(),
        governorate: _governorate!,
        city: _city!,
        address: _address.text.trim(),
        phone: phone,
        whatsapp: !_whatsappEnabled
            ? ''
            : (_whatsappSameAsPhone ? phone : digitsOnly(_whatsapp.text)),
        lat: _location!.latitude,
        lng: _location!.longitude,
        workingHours: _schedule.summary(),
        schedule: _schedule,
        description: _description.text.trim(),
        ownerId: editing != null ? editing.ownerId : auth.userId,
        createdAt: editing?.createdAt ?? DateTime.now(),
        status: editing?.status ?? PlaceStatus.pending,
        ratingSum: editing?.ratingSum ?? 0,
        ratingCount: editing?.ratingCount ?? 0,
      );
      if (editing != null) {
        await repo.updatePlace(place);
        messenger.showSnackBar(
          const SnackBar(content: Text('اتحفظت التعديلات')),
        );
      } else {
        await repo.submitPlace(place);
        messenger.showSnackBar(const SnackBar(
          content: Text('تم الإرسال! المكان هيظهر بعد مراجعة الإدارة'),
        ));
      }
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
      appBar: AppBar(
        title: Text(widget.editing == null ? 'أضف مكانك' : 'تعديل بيانات المكان'),
      ),
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
            DropdownButtonFormField<String>(
              value: _governorate,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'المحافظة'),
              items: [
                for (final g in governorates)
                  DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (g) => setState(() {
                _governorate = g;
                _city = null;
              }),
              validator: (v) => v == null ? 'اختار المحافظة' : null,
            ),
            gap,
            DropdownButtonFormField<String>(
              key: ValueKey(_governorate),
              value: _city,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'المدينة / المركز / الحي',
              ),
              items: [
                for (final c in citiesOf(_governorate ?? ''))
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: _governorate == null
                  ? null
                  : (c) => setState(() => _city = c),
              validator: (v) => v == null ? 'اختار المدينة' : null,
            ),
            gap,
            RawAutocomplete<String>(
              textEditingController: _area,
              focusNode: _areaFocus,
              optionsBuilder: (value) {
                final options = _knownAreas[_city] ?? const <String>{};
                final q = value.text.trim();
                return options.where((a) => q.isEmpty || a.contains(q));
              },
              fieldViewBuilder: (context, controller, focus, onSubmit) {
                return TextFormField(
                  controller: controller,
                  focusNode: focus,
                  decoration: const InputDecoration(
                    labelText: 'المنطقة',
                    hintText: 'اختار من القايمة أو اكتب اسم منطقتك',
                  ),
                  validator: _required,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Material(
                    elevation: 4,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 220, maxWidth: 320),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          for (final o in options)
                            ListTile(
                              dense: true,
                              title: Text(o),
                              onTap: () => onSelected(o),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
            if (_legacyHours.isNotEmpty) ...[
              Text('المواعيد القديمة: $_legacyHours',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
            ],
            ScheduleEditor(
              value: _schedule,
              errorText: _scheduleError,
              onChanged: (s) => setState(() {
                _schedule = s;
                if (!s.isEmpty) _scheduleError = null;
              }),
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
                  : Text(widget.editing == null ? 'إرسال للمراجعة' : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}
