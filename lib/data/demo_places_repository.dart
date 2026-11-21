import 'dart:async';

import '../models/category.dart';
import '../models/place.dart';
import '../models/review.dart';
import 'places_repository.dart';

/// بيانات تجريبية في الذاكرة، عشان تجرب التطبيق من غير Firebase.
/// أي حاجة بتضيفها بتتمسح لما تقفل التطبيق.
class DemoPlacesRepository implements PlacesRepository {
  DemoPlacesRepository({List<Place>? seed})
      : _places = List<Place>.of(seed ?? demoPlaces);

  final List<Place> _places;
  final List<Review> _reviews = <Review>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _nextId = 1000;

  void _notify() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<Place>> watchApproved() => _watch(
        () => _places
            .where((p) => p.status == PlaceStatus.approved)
            .toList(growable: false),
      );

  @override
  Stream<List<Place>> watchPending() => _watch(
        () => _places
            .where((p) => p.status == PlaceStatus.pending)
            .toList(growable: false),
      );

  @override
  Stream<List<Review>> watchReviews(String placeId) => _watch(() {
        final list = _reviews.where((r) => r.placeId == placeId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  @override
  Future<void> submitPlace(Place place) async {
    _places.add(place.copyWith(
      id: 'demo-${_nextId++}',
      status: PlaceStatus.pending,
    ));
    _notify();
  }

  @override
  Future<void> setStatus(String placeId, PlaceStatus status) async {
    final i = _places.indexWhere((p) => p.id == placeId);
    if (i == -1) return;
    _places[i] = _places[i].copyWith(status: status);
    _notify();
  }

  @override
  Future<void> addReview(Review review) async {
    final i = _places.indexWhere((p) => p.id == review.placeId);
    if (i == -1) return;
    _reviews.add(review);
    final p = _places[i];
    _places[i] = p.copyWith(
      ratingSum: p.ratingSum + review.rating,
      ratingCount: p.ratingCount + 1,
    );
    _notify();
  }
}

/// أماكن تجريبية (أسماء وأرقام وهمية) حوالين القاهرة.
final List<Place> demoPlaces = <Place>[
  const Place(
    id: 'd1',
    name: 'صيدلية الشفاء',
    category: PlaceCategory.pharmacy,
    area: 'مدينة نصر',
    address: 'شارع عباس العقاد',
    phone: '01000000001',
    whatsapp: '01000000001',
    lat: 30.0566,
    lng: 31.3300,
    workingHours: '24 ساعة',
    description: 'توصيل للمنازل',
    status: PlaceStatus.approved,
    ratingSum: 18,
    ratingCount: 4,
  ),
  const Place(
    id: 'd2',
    name: 'صيدلية النور',
    category: PlaceCategory.pharmacy,
    area: 'المعادي',
    address: 'شارع 9',
    phone: '01000000002',
    whatsapp: '',
    lat: 29.9602,
    lng: 31.2569,
    workingHours: '9 ص - 2 بعد نص الليل',
    status: PlaceStatus.approved,
    ratingSum: 8,
    ratingCount: 2,
  ),
  const Place(
    id: 'd3',
    name: 'ماركت الخير',
    category: PlaceCategory.supermarket,
    area: 'مدينة نصر',
    address: 'شارع مكرم عبيد',
    phone: '01000000003',
    whatsapp: '01000000003',
    lat: 30.0610,
    lng: 31.3420,
    workingHours: '8 ص - 12 بالليل',
    description: 'خضار وفاكهة ومنتجات ألبان',
    status: PlaceStatus.approved,
  ),
  const Place(
    id: 'd4',
    name: 'هايبر البركة',
    category: PlaceCategory.supermarket,
    area: 'المعادي',
    address: 'شارع اللاسلكي',
    phone: '01000000004',
    whatsapp: '01000000004',
    lat: 29.9700,
    lng: 31.2800,
    status: PlaceStatus.approved,
    ratingSum: 4,
    ratingCount: 1,
  ),
  const Place(
    id: 'd5',
    name: 'عيادة د. أحمد (باطنة)',
    category: PlaceCategory.doctor,
    area: 'مدينة نصر',
    address: 'الحي السابع',
    phone: '01000000005',
    whatsapp: '01000000005',
    lat: 30.0500,
    lng: 31.3500,
    workingHours: 'من 5 لـ 10 مساءً',
    description: 'بالحجز المسبق',
    status: PlaceStatus.approved,
    ratingSum: 14,
    ratingCount: 3,
  ),
  const Place(
    id: 'd6',
    name: 'عيادة د. منى (أطفال)',
    category: PlaceCategory.doctor,
    area: 'مصر الجديدة',
    address: 'شارع الميرغني',
    phone: '01000000006',
    whatsapp: '',
    lat: 30.0890,
    lng: 31.3240,
    status: PlaceStatus.approved,
  ),
  const Place(
    id: 'd7',
    name: 'مدرسة المستقبل للغات',
    category: PlaceCategory.school,
    area: 'مصر الجديدة',
    address: 'شارع الحجاز',
    phone: '01000000007',
    whatsapp: '',
    lat: 30.0950,
    lng: 31.3350,
    description: 'حضانة - ابتدائي - إعدادي',
    status: PlaceStatus.approved,
  ),
  const Place(
    id: 'd8',
    name: 'سنتر التفوق',
    category: PlaceCategory.tutoring,
    area: 'مدينة نصر',
    address: 'شارع الطيران',
    phone: '01000000008',
    whatsapp: '01000000008',
    lat: 30.0640,
    lng: 31.3200,
    description: 'ثانوية عامة - كل المواد',
    status: PlaceStatus.approved,
    ratingSum: 9,
    ratingCount: 2,
  ),
  const Place(
    id: 'd9',
    name: 'سنتر النجاح',
    category: PlaceCategory.tutoring,
    area: 'المعادي',
    address: 'دجلة',
    phone: '01000000009',
    whatsapp: '01000000009',
    lat: 29.9580,
    lng: 31.2700,
    status: PlaceStatus.pending,
  ),
];
