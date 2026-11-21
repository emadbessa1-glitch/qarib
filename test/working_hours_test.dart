import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qarib/models/place.dart';
import 'package:qarib/models/working_hours.dart';
import 'package:qarib/widgets/schedule_editor.dart';

void main() {
  // 2026-11-21 يوم سبت.
  DateTime at(int day, int h, [int m = 0]) => DateTime(2026, 11, 21 + day, h, m);

  test('formatMinutes', () {
    expect(formatMinutes(0), '12:00 ص');
    expect(formatMinutes(9 * 60 + 30), '9:30 ص');
    expect(formatMinutes(12 * 60), '12:00 م');
    expect(formatMinutes(23 * 60), '11:00 م');
    expect(formatMinutes(1440), '12:00 ص');
  });

  test('open now with normal, overnight and 24h ranges', () {
    expect(DateTime(2026, 11, 21).weekday, DateTime.saturday);
    final s = const WeeklySchedule()
        .withDay(DateTime.saturday, const [TimeRange(9 * 60, 22 * 60)])
        .withDay(DateTime.sunday, const [TimeRange(18 * 60, 2 * 60)])
        .withDay(DateTime.monday, const [TimeRange.fullDay]);
    expect(s.isOpenAt(at(0, 8, 59)), isFalse);
    expect(s.isOpenAt(at(0, 9)), isTrue);
    expect(s.isOpenAt(at(0, 22)), isFalse);
    expect(s.isOpenAt(at(1, 17)), isFalse); // الأحد قبل 6
    expect(s.isOpenAt(at(1, 23)), isTrue);
    expect(s.isOpenAt(at(2, 1)), isTrue); // بعد نص ليل الأحد
    expect(s.isOpenAt(at(3, 1)), isTrue); // الإثنين 24 ساعة يعدّي لحد 12
    expect(s.isOpenAt(at(3, 13)), isFalse); // الثلاثاء مقفول
    expect(s.isOpenAt(at(6, 12)), isFalse); // الجمعة مقفول
  });

  test('summary groups consecutive days', () {
    var s = const WeeklySchedule();
    for (final d in weekOrder.take(6)) {
      s = s.withDay(d, const [TimeRange(9 * 60, 23 * 60)]);
    }
    expect(s.summary(),
        'من السبت لـ الخميس: 9:00 ص – 11:00 م\nالجمعة: مقفول');
    var all = const WeeklySchedule();
    for (final d in weekOrder) {
      all = all.withDay(d, const [TimeRange.fullDay]);
    }
    expect(all.summary(), 'يومياً: 24 ساعة');
    expect(const WeeklySchedule().summary(), '');
  });

  test('round trip through Firestore map, rejects junk', () {
    final s = const WeeklySchedule()
        .withDay(DateTime.friday,
            const [TimeRange(10 * 60, 13 * 60), TimeRange(17 * 60, 1440)]);
    final back = WeeklySchedule.fromMap(s.toMap());
    expect(back.rangesOf(DateTime.friday), s.rangesOf(DateTime.friday));
    expect(back.isOpenDay(DateTime.saturday), isFalse);

    final junk = WeeklySchedule.fromMap({
      '9': [{'s': 1, 'e': 2}],
      '1': [{'s': -5, 'e': 2}, 'x'],
      '2': 'bad',
    });
    expect(junk.isEmpty, isTrue);
    expect(WeeklySchedule.fromMap(null).isEmpty, isTrue);

    final place = Place.fromMap('p', {
      'name': 'x',
      'schedule': s.toMap(),
    });
    expect(place.hasSchedule, isTrue);
    expect(Place.fromMap('q', {'name': 'y'}).hasSchedule, isFalse);
  });

  testWidgets('editor: tick a day, then copy to all days', (tester) async {
    var value = const WeeklySchedule();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => ScheduleEditor(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    ));
    expect(find.text('مقفول'), findsNWidgets(7));
    await tester.tap(find.byKey(const ValueKey('day-6')));
    await tester.pumpAndSettle();
    expect(value.dayLabel(DateTime.saturday), '9:00 ص – 10:00 م');
    expect(find.text('مقفول'), findsNWidgets(6));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نفس المواعيد لكل الأيام'));
    await tester.pumpAndSettle();
    expect(find.text('مقفول'), findsNothing);
    expect(value.summary(), 'يومياً: 9:00 ص – 10:00 م');
  });
}
