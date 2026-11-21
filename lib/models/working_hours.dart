/// مواعيد العمل الأسبوعية: لكل يوم فترة أو فترتين (أو مقفول).
///
/// الوقت بيتخزن بالدقايق من نص الليل (0..1440).
/// لو النهاية أصغر من أو تساوي البداية يبقى الفترة بتعدّي نص الليل
/// (مثلاً من 6 م لـ 2 ص). 0 → 1440 معناها 24 ساعة.
class TimeRange {
  const TimeRange(this.start, this.end);

  final int start;
  final int end;

  static const TimeRange fullDay = TimeRange(0, 1440);

  bool get isFullDay => start == 0 && end == 1440;
  bool get crossesMidnight => !isFullDay && end <= start;

  Map<String, int> toMap() => {'s': start, 'e': end};

  static TimeRange? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final s = raw['s'];
    final e = raw['e'];
    if (s is! num || e is! num) return null;
    final start = s.toInt();
    final end = e.toInt();
    if (start < 0 || start > 1439 || end < 0 || end > 1440) return null;
    return TimeRange(start, end);
  }

  String get label {
    if (isFullDay) return '24 ساعة';
    return '${formatMinutes(start)} – ${formatMinutes(end)}';
  }

  @override
  bool operator ==(Object other) =>
      other is TimeRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// "9:30 ص" / "11:00 م" / "12:00 م" للضهر / "12:00 ص" لنص الليل.
String formatMinutes(int minutes) {
  final m = minutes % 1440;
  final h24 = m ~/ 60;
  final min = m % 60;
  final suffix = h24 < 12 ? 'ص' : 'م';
  var h12 = h24 % 12;
  if (h12 == 0) h12 = 12;
  return '$h12:${min.toString().padLeft(2, '0')} $suffix';
}

/// أيام الأسبوع بترتيب مصر (السبت الأول). القيم زي DateTime.weekday.
const List<int> weekOrder = <int>[
  DateTime.saturday,
  DateTime.sunday,
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
];

const Map<int, String> dayNames = <int, String>{
  DateTime.saturday: 'السبت',
  DateTime.sunday: 'الأحد',
  DateTime.monday: 'الإثنين',
  DateTime.tuesday: 'الثلاثاء',
  DateTime.wednesday: 'الأربعاء',
  DateTime.thursday: 'الخميس',
  DateTime.friday: 'الجمعة',
};

class WeeklySchedule {
  const WeeklySchedule([this.days = const <int, List<TimeRange>>{}]);

  /// المفتاح: رقم اليوم (DateTime.weekday). يوم مش موجود أو فاضي = مقفول.
  final Map<int, List<TimeRange>> days;

  static const int maxRangesPerDay = 2;

  List<TimeRange> rangesOf(int weekday) =>
      days[weekday] ?? const <TimeRange>[];

  bool isOpenDay(int weekday) => rangesOf(weekday).isNotEmpty;

  bool get isEmpty => days.values.every((r) => r.isEmpty);

  WeeklySchedule withDay(int weekday, List<TimeRange> ranges) {
    final copy = Map<int, List<TimeRange>>.of(days);
    if (ranges.isEmpty) {
      copy.remove(weekday);
    } else {
      copy[weekday] = List<TimeRange>.unmodifiable(ranges);
    }
    return WeeklySchedule(Map<int, List<TimeRange>>.unmodifiable(copy));
  }

  /// مفتوح في الوقت ده؟ (بيحسب الفترات اللي بتعدّي نص الليل من امبارح).
  bool isOpenAt(DateTime t) {
    final m = t.hour * 60 + t.minute;
    for (final r in rangesOf(t.weekday)) {
      if (r.isFullDay) return true;
      if (r.crossesMidnight) {
        if (m >= r.start) return true;
      } else if (m >= r.start && m < r.end) {
        return true;
      }
    }
    final yesterday = t.weekday == DateTime.monday ? DateTime.sunday : t.weekday - 1;
    for (final r in rangesOf(yesterday)) {
      if (r.crossesMidnight && m < r.end) return true;
    }
    return false;
  }

  /// نص مواعيد يوم واحد.
  String dayLabel(int weekday) {
    final r = rangesOf(weekday);
    if (r.isEmpty) return 'مقفول';
    return r.map((x) => x.label).join(' و ');
  }

  /// ملخص للأسبوع كله، الأيام المتتالية اللي ليها نفس المواعيد بتتجمع.
  String summary() {
    if (isEmpty) return '';
    final labels = [for (final d in weekOrder) dayLabel(d)];
    if (labels.toSet().length == 1) return 'يومياً: ${labels.first}';
    final lines = <String>[];
    var i = 0;
    while (i < weekOrder.length) {
      var j = i;
      while (j + 1 < weekOrder.length && labels[j + 1] == labels[i]) {
        j++;
      }
      final from = dayNames[weekOrder[i]]!;
      final to = dayNames[weekOrder[j]]!;
      final days = i == j ? from : (j == i + 1 ? '$from و$to' : 'من $from لـ $to');
      lines.add('$days: ${labels[i]}');
      i = j + 1;
    }
    return lines.join('\n');
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        for (final e in days.entries)
          if (e.value.isNotEmpty)
            '${e.key}': [for (final r in e.value) r.toMap()],
      };

  factory WeeklySchedule.fromMap(Object? raw) {
    if (raw is! Map) return const WeeklySchedule();
    final days = <int, List<TimeRange>>{};
    raw.forEach((key, value) {
      final day = int.tryParse('$key');
      if (day == null || day < 1 || day > 7 || value is! List) return;
      final ranges = [
        for (final r in value.take(maxRangesPerDay)) TimeRange.fromMap(r),
      ].whereType<TimeRange>().toList();
      if (ranges.isNotEmpty) days[day] = List<TimeRange>.unmodifiable(ranges);
    });
    return WeeklySchedule(Map<int, List<TimeRange>>.unmodifiable(days));
  }
}
