class Report {
  final int reportId;
  final int reporterId;
  final String reporterName;
  final String reportType; // user, vehicle, booking, other
  final int? relatedId; // ID of the reported entity
  final String subject;
  final String description;
  final String status; // pending, investigating, resolved, dismissed
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
      reportId: json['report_id'] ?? 0,
      reporterId: json['reporter_id'] ?? 0,
      reporterName: json['reporter_name'] ?? '',
      reportType: json['report_type'] ?? 'other',
      relatedId: json['related_id'],
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
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
}