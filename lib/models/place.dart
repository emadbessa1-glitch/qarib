import 'package:latlong2/latlong.dart';

import 'category.dart';

/// حالة المكان: صاحب المكان بيضيفه فيبقى "قيد المراجعة" لحد ما الأدمن يوافق.
enum PlaceStatus {
  pending('pending', 'قيد المراجعة'),
  approved('approved', 'متوافق عليه'),
  rejected('rejected', 'مرفوض');

  const PlaceStatus(this.id, this.label);
  final String id;
  final String label;

  static PlaceStatus fromId(String? id) {
    return PlaceStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => PlaceStatus.pending,
    );
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.lat,
    required this.lng,
    this.description = '',
    this.workingHours = '',
    this.status = PlaceStatus.pending,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.ownerId,
    this.createdAt,
  });

  final String id;
  final String name;
  final PlaceCategory category;

  /// المنطقة أو الحي (مثلاً: مدينة نصر، المعادي).
  final String area;
  final String address;
  final String phone;

  /// رقم الواتساب (ممكن يكون فاضي).
  final String whatsapp;
  final double lat;
  final double lng;
  final String description;
  final String workingHours;
  final PlaceStatus status;
  final int ratingSum;
  final int ratingCount;
  final String? ownerId;
  final DateTime? createdAt;

  LatLng get location => LatLng(lat, lng);

  /// متوسط التقييم من 5 (صفر لو مفيش تقييمات).
  double get rating => ratingCount == 0 ? 0 : ratingSum / ratingCount;

  bool get hasWhatsapp => whatsapp.trim().isNotEmpty;

  Place copyWith({
    String? id,
    PlaceStatus? status,
    int? ratingSum,
    int? ratingCount,
  }) {
    return Place(
      id: id ?? this.id,
      name: name,
      category: category,
      area: area,
      address: address,
      phone: phone,
      whatsapp: whatsapp,
      lat: lat,
      lng: lng,
      description: description,
      workingHours: workingHours,
      status: status ?? this.status,
      ratingSum: ratingSum ?? this.ratingSum,
      ratingCount: ratingCount ?? this.ratingCount,
      ownerId: ownerId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'category': category.id,
      'area': area,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'lat': lat,
      'lng': lng,
      'description': description,
      'workingHours': workingHours,
      'status': status.id,
      'ratingSum': ratingSum,
      'ratingCount': ratingCount,
      'ownerId': ownerId,
      'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  factory Place.fromMap(String id, Map<String, dynamic> map) {
    final created = map['createdAt'];
    return Place(
      id: id,
      name: (map['name'] ?? '') as String,
      category: PlaceCategory.fromId((map['category'] ?? '') as String),
      area: (map['area'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      whatsapp: (map['whatsapp'] ?? '') as String,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      description: (map['description'] ?? '') as String,
      workingHours: (map['workingHours'] ?? '') as String,
      status: PlaceStatus.fromId(map['status'] as String?),
      ratingSum: (map['ratingSum'] as num?)?.toInt() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      ownerId: map['ownerId'] as String?,
      createdAt: created is int
          ? DateTime.fromMillisecondsSinceEpoch(created)
          : null,
    );
  }
}
