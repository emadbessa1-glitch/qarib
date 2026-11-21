import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:qarib/data/demo_places_repository.dart';
import 'package:qarib/models/category.dart';
import 'package:qarib/models/place.dart';
import 'package:qarib/models/review.dart';
import 'package:qarib/utils/contact.dart';
import 'package:qarib/utils/geo.dart';

void main() {
  group('contact', () {
    test('digitsOnly converts Arabic digits and strips symbols', () {
      expect(digitsOnly('٠١٠ ١٢٣-٤٥٦٧٨'), '01012345678');
      expect(digitsOnly('+20 (10) 123'), '2010123');
    });

    test('toInternational for Egyptian mobiles', () {
      expect(toInternational('01012345678'), '201012345678');
      expect(toInternational('+201012345678'), '201012345678');
      expect(toInternational('00201012345678'), '201012345678');
    });

    test('isValidEgyptianPhone', () {
      expect(isValidEgyptianPhone('01012345678'), isTrue);
      expect(isValidEgyptianPhone('01512345678'), isTrue);
      expect(isValidEgyptianPhone('0221234567'), isTrue);
      expect(isValidEgyptianPhone('01312345678'), isFalse);
      expect(isValidEgyptianPhone('123'), isFalse);
    });
  });

  group('geo', () {
    test('formatDistance', () {
      expect(formatDistance(350), '350 م');
      expect(formatDistance(2400), '2.4 كم');
      expect(formatDistance(15200), '15 كم');
    });

    test('sortPlaces orders by distance when location known', () {
      final near = _place('a', 30.0001, 31.0001);
      final far = _place('b', 30.1, 31.1);
      final sorted = sortPlaces([far, near], LatLng(30, 31));
      expect(sorted.map((p) => p.id), ['a', 'b']);
    });

    test('sortPlaces orders by rating when location unknown', () {
      final low = _place('low', 30, 31, ratingSum: 2, ratingCount: 1);
      final high = _place('high', 30, 31, ratingSum: 5, ratingCount: 1);
      expect(sortPlaces([low, high], null).first.id, 'high');
    });
  });

  group('DemoPlacesRepository', () {
    test('submitted place is pending until approved', () async {
      final repo = DemoPlacesRepository(seed: []);
      await repo.submitPlace(_place('', 30, 31));
      final pending = await repo.watchPending().first;
      expect(pending, hasLength(1));
      expect(await repo.watchApproved().first, isEmpty);

      await repo.setStatus(pending.single.id, PlaceStatus.approved);
      expect(await repo.watchApproved().first, hasLength(1));
      expect(await repo.watchPending().first, isEmpty);
    });

    test('addReview updates the average rating', () async {
      final repo = DemoPlacesRepository(
        seed: [_place('p', 30, 31, status: PlaceStatus.approved)],
      );
      for (final r in [5, 3]) {
        await repo.addReview(Review(
          id: '',
          placeId: 'p',
          authorName: 'x',
          rating: r,
          comment: '',
          createdAt: DateTime.now(),
        ));
      }
      final place = (await repo.watchApproved().first).single;
      expect(place.ratingCount, 2);
      expect(place.rating, 4);
      expect(await repo.watchReviews('p').first, hasLength(2));
    });
  });

  test('Place map round-trip', () {
    final p = _place('id1', 30.5, 31.5, status: PlaceStatus.approved);
    final back = Place.fromMap('id1', p.toMap());
    expect(back.name, p.name);
    expect(back.category, p.category);
    expect(back.status, PlaceStatus.approved);
    expect(back.lat, 30.5);
  });
}

Place _place(
  String id,
  double lat,
  double lng, {
  int ratingSum = 0,
  int ratingCount = 0,
  PlaceStatus status = PlaceStatus.pending,
}) {
  return Place(
    id: id,
    name: 'مكان $id',
    category: PlaceCategory.pharmacy,
    area: 'منطقة',
    address: 'عنوان',
    phone: '01000000000',
    whatsapp: '',
    lat: lat,
    lng: lng,
    status: status,
    ratingSum: ratingSum,
    ratingCount: ratingCount,
  );
}
