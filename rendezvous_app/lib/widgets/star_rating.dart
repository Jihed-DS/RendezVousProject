import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final double size;

  const StarRating({
    super.key,
    required this.rating,
    required this.totalReviews,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final threshold = i + 1;
          IconData icon;
          if (rating >= threshold) {
            icon = Icons.star;
          } else if (rating >= threshold - 0.5) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          return Icon(icon, size: size, color: Colors.amber);
        }),
        const SizedBox(width: 6),
        Text(
          '($totalReviews)',
          style: TextStyle(fontSize: size * 0.75, color: Colors.black45),
        ),
      ],
    );
  }
}