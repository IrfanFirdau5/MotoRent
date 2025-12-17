class Report {
  final dynamic reportId; // Changed from int to dynamic
  final String reporterId; // Changed from int to String
  final String reporterName;
  final String reportType;
  final String? relatedId; // Changed from int? to String?
  final String subject;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNotes;

  Report({
    required this.reportId,
    required this.reporterId,
    required this.reporterName,
    required this.reportType,
    this.relatedId,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.adminNotes,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: json['report_id'] ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      reporterName: json['reporter_name'] ?? '',
      reportType: json['report_type'] ?? 'other',
      relatedId: json['related_id']?.toString(),
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? (json['created_at'] is String 
              ? DateTime.parse(json['created_at'])
              : DateTime.now())
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? (json['resolved_at'] is String
              ? DateTime.parse(json['resolved_at'])
              : null)
          : null,
      adminNotes: json['admin_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_id': reportId,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'report_type': reportType,
      'related_id': relatedId,
      'subject': subject,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'admin_notes': adminNotes,
    };
  }

  // Helper method to get report ID as String
  String get reportIdString => reportId.toString();
}