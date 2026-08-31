class Creneau {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String prestataireId;
  final String? prestataireName;
  final String? appointmentStatus;
  final List<String> tags;

  Creneau({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.prestataireId,
    this.prestataireName,
    this.appointmentStatus,
    required this.tags,
  });

  factory Creneau.fromJson(Map<String, dynamic> json) {
    return Creneau(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      isAvailable: json['isAvailable'] as bool,
      prestataireId: json['prestataireId'] as String,
      prestataireName: json['prestataireName'] as String?,
      appointmentStatus: json['appointmentStatus'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}