import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// موقع المستخدم الحالي. لو رفض الإذن أو الـ GPS مقفول، [position] بتفضل null
/// والتطبيق بيشتغل عادي من غير ترتيب بالمسافة.
class LocationService extends ChangeNotifier {
  LatLng? _position;
  String? _error;
  bool _loading = false;

  LatLng? get position => _position;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _error = 'خدمة الموقع (GPS) مقفولة';
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _error = 'مفيش إذن للوصول للموقع';
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _position = LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      _error = 'معرفناش نحدد موقعك';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
