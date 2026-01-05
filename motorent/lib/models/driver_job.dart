// FILE: motorent/lib/models/driver_job.dart
// ✅ FIXED: Changed all IDs to String for Firebase compatibility
import 'package:cloud_firestore/cloud_firestore.dart';
class DriverJob {
  final String jobId; // ✅ Changed from int to String
  final String driverId; // ✅ Changed from int to String
  final String bookingId; // ✅ Changed from int to String
  final String customerName;
  final String customerPhone;
  final String vehicleName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime pickupTime;
  final int duration;
  final double payment;
  final String status; // scheduled, completed, cancelled
  final DateTime createdAt;

  DriverJob({
    required this.jobId,
    required this.driverId,
    required this.bookingId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupTime,
    required this.duration,
    required this.payment,
    required this.status,
    required this.createdAt,
  });

  factory DriverJob.fromJson(Map<String, dynamic> json) {
    return DriverJob(
      jobId: json['job_id']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      dropoffLocation: json['dropoff_location'] ?? '',
      pickupTime: json['pickup_time'] != null
          ? (json['pickup_time'] is String 
              ? DateTime.parse(json['pickup_time'])
              : (json['pickup_time'] as Timestamp).toDate())
          : DateTime.now(),
      duration: json['duration'] ?? 1,
      payment: (json['payment'] ?? 0).toDouble(),
      status: json['status'] ?? 'scheduled',
      createdAt: json['created_at'] != null
          ? (json['created_at'] is String
              ? DateTime.parse(json['created_at'])
              : (json['created_at'] as Timestamp).toDate())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'driver_id': driverId,
      'booking_id': bookingId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'vehicle_name': vehicleName,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'pickup_time': pickupTime.toIso8601String(),
      'duration': duration,
      'payment': payment,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
