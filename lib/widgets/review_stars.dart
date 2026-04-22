import 'package:flutter/material.dart';

/// Affiche des étoiles de notation (1-5).
/// [rating] peut être un double (ex : 4.3 → 4 étoiles pleines).
class ReviewStars extends StatelessWidget {
  const ReviewStars({
    super.key,
    required this.rating,
    this.iconSize = 18,
    this.showLabel = false,
  });

  final double rating;
  final double iconSize;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final int full = rating.floor();
    final bool half = (rating - full) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < full) {
            return Icon(Icons.star_rounded,
                color: const Color(0xFFFFC107), size: iconSize);
          } else if (index == full && half) {
            return Icon(Icons.star_half_rounded,
                color: const Color(0xFFFFC107), size: iconSize);
          } else {
            return Icon(Icons.star_outline_rounded,
                color: Colors.grey.shade300, size: iconSize);
          }
        }),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
          ),
        ],
      ],
    );
  }
}
