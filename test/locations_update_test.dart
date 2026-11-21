import 'package:flutter_test/flutter_test.dart';
import 'package:qarib/data/egypt_locations.dart';
import 'package:qarib/models/category.dart';
import 'package:qarib/models/place.dart';
import 'package:qarib/services/update_service.dart';

void main() {
  test('27 governorates, each with cities', () {
    expect(governorates.length, 27);
    for (final g in governorates) {
      expect(citiesOf(g), isNotEmpty, reason: g);
    }
    expect(citiesOf('القاهرة'), contains('مدينة نصر'));
    expect(citiesOf('مش موجودة'), isEmpty);
  });

  test('parse build number from release notes', () {
    expect(UpdateService.parseBuild('نسخة جديدة\n\nbuild=42'), 42);
    expect(UpdateService.parseBuild('no number'), isNull);
    expect(UpdateService.currentBuildFrom('2018'), 18);
    expect(UpdateService.currentBuildFrom('17'), 17);
  });

  test('new categories exist', () {
    expect(PlaceCategory.fromId('crafts'), PlaceCategory.crafts);
    expect(PlaceCategory.fromId('public_figure'), PlaceCategory.publicFigure);
    expect(PlaceCategory.fromId('company'), PlaceCategory.company);
  });

  test('place location label and round-trip of governorate/city', () {
    const p = Place(
      id: 'x',
      name: 'ن',
      category: PlaceCategory.crafts,
      area: 'الحي السابع',
      city: 'مدينة نصر',
      governorate: 'القاهرة',
      address: 'ع',
      phone: '01000000000',
      whatsapp: '',
      lat: 30,
      lng: 31,
    );
    expect(p.locationLabel, 'الحي السابع، مدينة نصر');
    final back = Place.fromMap('x', p.toMap());
    expect(back.governorate, 'القاهرة');
    expect(back.city, 'مدينة نصر');
  });
}
