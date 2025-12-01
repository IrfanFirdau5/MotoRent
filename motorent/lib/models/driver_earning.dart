class DriverEarning {
  final int earningId;
  final int driverId;
  final int jobId;
  final double amount;
  final String description;
  final String status; // pending, paid, processing
  final DateTime date;
  final DateTime? paidAt;

  DriverEarning({
    required this.earningId,
    required this.driverId,
    required this.jobId,
    required this.amount,
    required this.description,
    required this.status,
    required this.date,
    this.paidAt,
  });

  factory DriverEarning.fromJson(Map<String, dynamic> json) {
    return DriverEarning(
      earningId: json['earning_id'] ?? 0,
      driverId: json['driver_id'] ?? 0,
      jobId: json['job_id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'earning_id': earningId,
      'driver_id': driverId,
      'job_id': jobId,
      'amount': amount,
      'description': description,
      'status': status,
      'date': date.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}