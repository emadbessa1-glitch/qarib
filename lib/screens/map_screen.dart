import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/category.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../utils/contact.dart';
import '../utils/geo.dart';
import '../widgets/approved_places_builder.dart';
import '../widgets/category_chips.dart';
import '../widgets/osm_map.dart';
import '../widgets/rating_stars.dart';
import 'place_details_screen.dart';

/// الخريطة: كل الأماكن كعلامات، وزرار "أقرب مكان".
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialCategory});

  final PlaceCategory? initialCategory;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _map = MapController();
  late PlaceCategory? _category = widget.initialCategory;

  List<Place> _visible(List<Place> all) => _category == null
      ? all
      : all.where((p) => p.category == _category).toList();

  void _showPlace(Place place, LatLng? user) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _PlaceSheet(place: place, user: user),
    );
  }

  void _goToNearest(List<Place> places, LatLng? user) {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('فعّل الموقع الأول عشان نعرف الأقرب ليك'),
      ));
      context.read<LocationService>().refresh();
      return;
    }
    if (places.isEmpty) return;
    final nearest = sortPlaces(places, user).first;
    _map.move(nearest.location, 16);
    _showPlace(nearest, user);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LocationService>().position;
    final center =
        user ?? LatLng(AppConfig.defaultLat, AppConfig.defaultLng);

    return Scaffold(
      appBar: AppBar(title: const Text('الخريطة')),
      body: ApprovedPlacesBuilder(
        builder: (context, all) {
          final places = _visible(all);
          return Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: user == null ? 11 : 14,
                ),
                children: [
                  ...osmBaseLayers(),
                  MarkerLayer(
                    markers: [
                      for (final p in places)
                        Marker(
                          point: p.location,
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => _showPlace(p, user),
                            child: Icon(
                              Icons.location_on,
                              size: 44,
                              color: p.category.color,
                            ),
                          ),
                        ),
                      if (user != null) userMarker(user),
                    ],
                  ),
                  osmAttribution(),
                ],
              ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: CategoryChips(
                    selected: _category,
                    onChanged: (c) => setState(() => _category = c),
                  ),
                ),
              ),
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _goToNearest(places, user),
                        icon: const Icon(Icons.near_me),
                        label: Text(_category == null
                            ? 'أقرب مكان ليا'
                            : 'أقرب ${_category!.label}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'موقعي',
                      onPressed: user == null
                          ? () => context.read<LocationService>().refresh()
                          : () => _map.move(user, 15),
                      icon: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  const _PlaceSheet({required this.place, required this.user});

  final Place place;
  final LatLng? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text([
              place.category.label,
              place.area,
              if (user != null)
                formatDistance(metersBetween(user!, place.location)),
            ].join(' • ')),
            const SizedBox(height: 4),
            RatingStars(rating: place.rating),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => callPhone(place.phone),
                  icon: const Icon(Icons.call),
                  label: const Text('اتصال'),
                ),
                if (place.hasWhatsapp)
                  OutlinedButton.icon(
                    onPressed: () => openWhatsapp(place.whatsapp),
                    icon: const Icon(Icons.chat),
                    label: const Text('واتساب'),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    nav.push(MaterialPageRoute<void>(
                      builder: (_) => PlaceDetailsScreen(place: place),
                    ));
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('التفاصيل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
