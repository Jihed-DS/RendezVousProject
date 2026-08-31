import 'package:flutter/material.dart';
import '../models/avis_summary.dart';

class RatingDistributionBar extends StatelessWidget {
  final AvisSummary summary;

  const RatingDistributionBar({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.totalReviews == 0) {
      return const Text('Aucun avis pour le moment.', style: TextStyle(color: Colors.black54));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Score global à gauche
          Column(
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = summary.averageRating >= i + 1;
                  final half = !filled && summary.averageRating >= i + 0.5;
                  return Icon(
                    filled ? Icons.star : (half ? Icons.star_half : Icons.star_border),
                    size: 14,
                    color: Colors.amber,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.totalReviews} avis',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Barres par étoile à droite
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i; // affiche 5★ en haut, 1★ en bas
                final count = summary.distributionByStar[star] ?? 0;
                final ratio = summary.totalReviews > 0 ? count / summary.totalReviews : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 11, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: Colors.black.withValues(alpha: 0.06),
                            valueColor: const AlwaysStoppedAnimation(Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text('$count', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}