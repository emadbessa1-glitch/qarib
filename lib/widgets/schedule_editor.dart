import 'package:flutter/material.dart';

import '../models/working_hours.dart';

/// صاحب العمل بيختار أيام الشغل وساعات كل يوم (فترة أو فترتين).
class ScheduleEditor extends StatelessWidget {
  const ScheduleEditor({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final WeeklySchedule value;
  final ValueChanged<WeeklySchedule> onChanged;
  final String? errorText;

  static const TimeRange _defaultRange = TimeRange(9 * 60, 22 * 60);

  Future<int?> _pickTime(BuildContext context, int minutes, String help) async {
    final m = minutes % 1440;
    final t = await showTimePicker(
      context: context,
      helpText: help,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (t == null) return null;
    return t.hour * 60 + t.minute;
  }

  void _setRanges(int day, List<TimeRange> ranges) =>
      onChanged(value.withDay(day, ranges));

  Future<void> _editStart(BuildContext context, int day, int index) async {
    final ranges = List<TimeRange>.of(value.rangesOf(day));
    final r = ranges[index];
    final v = await _pickTime(context, r.isFullDay ? 9 * 60 : r.start,
        'بيفتح الساعة كام؟ (${dayNames[day]})');
    if (v == null) return;
    ranges[index] = TimeRange(v, r.isFullDay ? 22 * 60 : r.end);
    _setRanges(day, ranges);
  }

  Future<void> _editEnd(BuildContext context, int day, int index) async {
    final ranges = List<TimeRange>.of(value.rangesOf(day));
    final r = ranges[index];
    final v = await _pickTime(context, r.isFullDay ? 22 * 60 : r.end,
        'بيقفل الساعة كام؟ (${dayNames[day]})');
    if (v == null) return;
    // قفل الساعة 12 بالليل = آخر اليوم.
    final end = v == 0 ? 1440 : v;
    ranges[index] = TimeRange(r.isFullDay ? 9 * 60 : r.start, end);
    _setRanges(day, ranges);
  }

  void _copyToAll(int day) {
    final ranges = value.rangesOf(day);
    var s = value;
    for (final d in weekOrder) {
      s = s.withDay(d, ranges);
    }
    onChanged(s);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'مواعيد العمل',
        helperText: 'علّم على الأيام اللي بتشتغل فيها وحدد الساعات',
        errorText: errorText,
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      ),
      child: Column(
        children: [
          for (final day in weekOrder) _dayRow(context, theme, day),
        ],
      ),
    );
  }

  Widget _dayRow(BuildContext context, ThemeData theme, int day) {
    final ranges = value.rangesOf(day);
    final open = ranges.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: CheckboxListTile(
              key: ValueKey('day-$day'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: open,
              title: Text(dayNames[day]!),
              onChanged: (v) => _setRanges(
                day,
                v == true ? const [_defaultRange] : const <TimeRange>[],
              ),
            ),
          ),
          Expanded(
            child: !open
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('مقفول',
                        style: TextStyle(color: theme.colorScheme.outline)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < ranges.length; i++)
                        _rangeRow(context, day, ranges, i),
                    ],
                  ),
          ),
          if (open)
            PopupMenuButton<String>(
              tooltip: 'خيارات اليوم',
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                switch (v) {
                  case 'all':
                    _copyToAll(day);
                  case '24':
                    _setRanges(day, const [TimeRange.fullDay]);
                  case 'add':
                    _setRanges(day, [...ranges, const TimeRange(17 * 60, 22 * 60)]);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'all', child: Text('نفس المواعيد لكل الأيام')),
                const PopupMenuItem(value: '24', child: Text('مفتوح 24 ساعة')),
                if (ranges.length < WeeklySchedule.maxRangesPerDay &&
                    !ranges.first.isFullDay)
                  const PopupMenuItem(
                      value: 'add', child: Text('إضافة فترة تانية')),
              ],
            ),
        ],
      ),
    );
  }

  Widget _rangeRow(
      BuildContext context, int day, List<TimeRange> ranges, int i) {
    final r = ranges[i];
    if (r.isFullDay) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: ActionChip(
          avatar: const Icon(Icons.all_inclusive, size: 18),
          label: const Text('24 ساعة'),
          onPressed: () => _setRanges(day, const [_defaultRange]),
          tooltip: 'تحديد ساعات',
        ),
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        ActionChip(
          label: Text('من ${formatMinutes(r.start)}'),
          onPressed: () => _editStart(context, day, i),
        ),
        ActionChip(
          label: Text('لـ ${formatMinutes(r.end)}'),
          onPressed: () => _editEnd(context, day, i),
        ),
        if (i > 0)
          IconButton(
            tooltip: 'شيل الفترة دي',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _setRanges(day, [...ranges]..removeAt(i)),
          ),
      ],
    );
  }
}

/// عرض المواعيد في صفحة المكان: مفتوح دلوقتي ولا لأ + جدول الأيام.
class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key, required this.schedule, this.now});

  final WeeklySchedule schedule;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final t = now ?? DateTime.now();
    final open = schedule.isOpenAt(t);
    final theme = Theme.of(context);
    final color = open ? Colors.green.shade700 : theme.colorScheme.error;
    return ExpansionTile(
      leading: const Icon(Icons.schedule),
      title: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(open ? 'مفتوح دلوقتي' : 'مقفول دلوقتي',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
      subtitle: Text('النهارده: ${schedule.dayLabel(t.weekday)}'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        for (final d in weekOrder)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    dayNames[d]!,
                    style: d == t.weekday
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                ),
                Expanded(
                  child: Text(
                    schedule.dayLabel(d),
                    style: TextStyle(
                      fontWeight: d == t.weekday ? FontWeight.bold : null,
                      color: schedule.isOpenDay(d)
                          ? null
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
