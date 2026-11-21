import 'package:flutter/material.dart';

import '../models/category.dart';

/// شريط فلترة بنوع الخدمة. null = الكل.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PlaceCategory? selected;
  final ValueChanged<PlaceCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('الكل'),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          for (final c in PlaceCategory.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                avatar: Icon(c.icon, size: 18, color: c.color),
                label: Text(c.label),
                selected: selected == c,
                onSelected: (_) => onChanged(c),
              ),
            ),
        ],
      ),
    );
  }
}
