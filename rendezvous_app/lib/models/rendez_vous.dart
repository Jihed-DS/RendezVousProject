class RendezVousItem {
  final String id;
  final String prestataireId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final String? notes;
  final List<String> selectedTags;
  final String? clientName;
  final String? prestataireName;
  final bool hasReview;

  RendezVousItem({
    required this.id,
    required this.prestataireId,
    this.startTime,
    this.endTime,
    required this.status,
    this.notes,
    this.selectedTags= const [],
    this.clientName,
    this.prestataireName,
    required this.hasReview,
  });

  factory RendezVousItem.fromJson(Map<String, dynamic> json) {
    return RendezVousItem(
      id: json['id'] as String,
      prestataireId: json['prestataireId'] as String,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      selectedTags: (json['selectedTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      clientName: json['clientName'] as String?,
      prestataireName: json['prestataireName'] as String?,
      hasReview: json['hasReview'] as bool,
    );
  }
}