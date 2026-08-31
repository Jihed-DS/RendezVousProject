class Categorie {
  final String id;
  final String name;
  final String? description;

  Categorie({required this.id, required this.name, this.description});

  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}