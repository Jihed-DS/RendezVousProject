class Prestataire {
  final String id;
  final String? bio;
  final String? photoUrl;
  final double ratingAvg;
  final int totalReviews;
  final String? fullName;
  final String? email;
  final String? categorieName;
  final String? city;
  final List<String> subcategories;

  Prestataire({
    required this.id,
    this.bio,
    this.photoUrl,
    required this.ratingAvg,
    required this.totalReviews,
    this.fullName,
    this.email,
    this.categorieName,
    this.city,
    required this.subcategories,
  });

  factory Prestataire.fromJson(Map<String, dynamic> json) {
    return Prestataire(
      id: json['id'] as String,
      bio: json['bio'] as String?,
      photoUrl: json['photoUrl'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      categorieName: json['categorieName'] as String?,
      city: json['city'] as String?,
      subcategories: (json['subcategories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }
}