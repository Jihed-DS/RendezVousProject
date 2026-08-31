class CategoryDemand {
  final String categoryName;
  final int bookingCount;

  CategoryDemand({required this.categoryName, required this.bookingCount});

  factory CategoryDemand.fromJson(Map<String, dynamic> json) {
    return CategoryDemand(
      categoryName: json['categoryName'] as String,
      bookingCount: json['bookingCount'] as int,
    );
  }
}

class TrendingPrestataire {
  final String id;
  final String? fullName;
  final String? categoryName;
  final String? photoUrl;
  final int bookingCount;
  final double ratingAvg;

  TrendingPrestataire({
    required this.id,
    this.fullName,
    this.categoryName,
    this.photoUrl,
    required this.bookingCount,
    required this.ratingAvg,
  });

  factory TrendingPrestataire.fromJson(Map<String, dynamic> json) {
    return TrendingPrestataire(
      id: json['id'] as String,
      fullName: json['fullName'] as String?,
      categoryName: json['categoryName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      bookingCount: json['bookingCount'] as int,
      ratingAvg: (json['ratingAvg'] as num).toDouble(),
    );
  }
}

class AdminDashboard {
  final int totalClients;
  final int totalPrestataires;
  final int totalCategories;
  final int totalRendezVous;
  final int rendezVousThisWeek;
  final int pendingRendezVousCount;
  final List<CategoryDemand> topCategories;
  final List<TrendingPrestataire> trendingPrestataires;
  final List<TrendingPrestataire> topRatedPrestataires;

  AdminDashboard({
    required this.totalClients,
    required this.totalPrestataires,
    required this.totalCategories,
    required this.totalRendezVous,
    required this.rendezVousThisWeek,
    required this.pendingRendezVousCount,
    required this.topCategories,
    required this.trendingPrestataires,
    required this.topRatedPrestataires,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      totalClients: json['totalClients'] as int,
      totalPrestataires: json['totalPrestataires'] as int,
      totalCategories: json['totalCategories'] as int,
      totalRendezVous: json['totalRendezVous'] as int,
      rendezVousThisWeek: json['rendezVousThisWeek'] as int,
      pendingRendezVousCount: json['pendingRendezVousCount'] as int,
      topCategories: (json['topCategories'] as List<dynamic>)
          .map((e) => CategoryDemand.fromJson(e as Map<String, dynamic>))
          .toList(),
      trendingPrestataires: (json['trendingPrestataires'] as List<dynamic>)
          .map((e) => TrendingPrestataire.fromJson(e as Map<String, dynamic>))
          .toList(),
      topRatedPrestataires: (json['topRatedPrestataires'] as List<dynamic>)
          .map((e) => TrendingPrestataire.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}