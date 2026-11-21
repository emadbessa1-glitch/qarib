import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// طبقة خريطة OpenStreetMap مع حقوق النشر المطلوبة.
/// ملحوظة: سيرفر OSM المجاني للاستخدام الخفيف بس. لما التطبيق يكبر
/// غيّر urlTemplate لمزوّد خرايط (زي MapTiler أو Stadia) بمفتاح خاص بيك.
List<Widget> osmBaseLayers() => <Widget>[
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.qarib.app',
      ),
    ];

Widget osmAttribution() => RichAttributionWidget(
      attributions: [
        TextSourceAttribution('OpenStreetMap contributors'),
      ],
    );

/// علامة موقع المستخدم (نقطة زرقا).
Marker userMarker(LatLng point) => Marker(
      point: point,
      width: 22,
      height: 22,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
      ),
    );
