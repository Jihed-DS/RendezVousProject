class Avis {
  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? clientName;

  Avis({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.clientName,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    return Avis(
      id: json['id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      clientName: json['clientName'] as String?,
    );
  }
}