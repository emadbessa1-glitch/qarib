import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/osm_map.dart';

/// اختيار مكان على الخريطة بلمسة. بيرجع LatLng.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, required this.initial});

  final LatLng initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _point = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حدد مكانك على الخريطة')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.initial,
              initialZoom: 15,
              onTap: (_, point) => setState(() => _point = point),
            ),
            children: [
              ...osmBaseLayers(),
              MarkerLayer(markers: [
                Marker(
                  point: _point,
                  width: 48,
                  height: 48,
                  child: const Icon(Icons.location_on,
                      size: 48, color: Colors.red),
                ),
              ]),
              osmAttribution(),
            ],
          ),
          const Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('اضغط على الخريطة في مكان المحل بالظبط'),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_point),
              icon: const Icon(Icons.check),
              label: const Text('تأكيد المكان'),
            ),
          ),
        ],
      ),
    );
  }
}
