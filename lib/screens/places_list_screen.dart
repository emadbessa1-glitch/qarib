import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../utils/geo.dart';
import '../widgets/approved_places_builder.dart';
import '../widgets/category_chips.dart';
import '../widgets/place_card.dart';
import 'map_screen.dart';

/// قائمة الأماكن مع بحث وفلترة بالنوع والمنطقة، ومترتبة بالأقرب.
class PlacesListScreen extends StatefulWidget {
  const PlacesListScreen({
    super.key,
    this.initialCategory,
    this.initialQuery = '',
  });

  final PlaceCategory? initialCategory;
  final String initialQuery;

  @override
  State<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends State<PlacesListScreen> {
  late PlaceCategory? _category = widget.initialCategory;
  late final TextEditingController _search =
      TextEditingController(text: widget.initialQuery);
  String? _area;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Place> _filter(List<Place> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((p) {
      if (_category != null && p.category != _category) return false;
      if (_area != null && p.area != _area) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.area.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.category.label.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = context.watch<LocationService>().position;

    return Scaffold(
      appBar: AppBar(
        title: Text(_category?.label ?? 'كل الخدمات'),
        actions: [
          IconButton(
            tooltip: 'عرض على الخريطة',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MapScreen(initialCategory: _category),
              ),
            ),
          ),
        ],
      ),
      body: ApprovedPlacesBuilder(
        builder: (context, all) {
          final areas = all.map((p) => p.area).where((a) => a.isNotEmpty).toSet().toList()
            ..sort();
          final places = sortPlaces(_filter(all), userLocation);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'بحث بالاسم أو العنوان',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _search.clear()),
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String?>(
                      value: areas.contains(_area) ? _area : null,
                      hint: const Text('كل المناطق'),
                      onChanged: (v) => setState(() => _area = v),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('كل المناطق'),
                        ),
                        for (final a in areas)
                          DropdownMenuItem<String?>(value: a, child: Text(a)),
                      ],
                    ),
                  ],
                ),
              ),
              CategoryChips(
                selected: _category,
                onChanged: (c) => setState(() => _category = c),
              ),
              Expanded(
                child: places.isEmpty
                    ? const Center(child: Text('مفيش نتايج'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: places.length,
                        itemBuilder: (context, i) => PlaceCard(
                          place: places[i],
                          userLocation: userLocation,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
