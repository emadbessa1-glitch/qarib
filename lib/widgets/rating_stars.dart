import 'package:flutter/material.dart';

/// نجوم التقييم للعرض فقط.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (i) {
        final value = rating - i;
        final IconData icon;
        if (value >= 0.75) {
          icon = Icons.star;
        } else if (value >= 0.25) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Icon(icon, size: size, color: Colors.amber.shade700);
      }),
    );
  }
}

/// نجوم بتتداس لاختيار التقييم.
class RatingPicker extends StatelessWidget {
  const RatingPicker({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          tooltip: '$star',
          onPressed: () => onChanged(star),
          icon: Icon(
            star <= value ? Icons.star : Icons.star_border,
            color: Colors.amber.shade700,
            size: 32,
          ),
        );
      }),
    );
  }
}
