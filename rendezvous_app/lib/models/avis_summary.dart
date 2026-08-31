class AvisSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distributionByStar;

  AvisSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.distributionByStar,
  });

  factory AvisSummary.fromJson(Map<String, dynamic> json) {
    final rawDist = json['distributionByStar'] as Map<String, dynamic>;
    return AvisSummary(
      averageRating: (json['averageRating'] as num).toDouble(),
      totalReviews: json['totalReviews'] as int,
      distributionByStar: rawDist.map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }
}