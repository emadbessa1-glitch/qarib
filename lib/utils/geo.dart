import 'package:latlong2/latlong.dart';

import '../models/place.dart';

final Distance _distance = Distance();

/// المسافة بالمتر بين نقطتين.
double metersBetween(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

/// نص المسافة بالعربي: "350 م" أو "2.4 كم".
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} م';
  }
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} كم';
}

/// ترتيب الأماكن من الأقرب للأبعد. لو مفيش موقع، بالتقييم ثم بالاسم.
List<Place> sortPlaces(List<Place> places, LatLng? from) {
  final list = List<Place>.of(places);
  if (from != null) {
    list.sort((a, b) => metersBetween(from, a.location)
        .compareTo(metersBetween(from, b.location)));
  } else {
    list.sort((a, b) {
      final byRating = b.rating.compareTo(a.rating);
      return byRating != 0 ? byRating : a.name.compareTo(b.name);
    });
  }
  return list;
}
