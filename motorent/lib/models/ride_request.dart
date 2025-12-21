// FILE PATH: motorent/lib/models/ride_request.dart
// ✅ FIXED: Changed all IDs to String to match other models (Booking, Vehicle, User, etc.)

class RideRequest {
  final String requestId; // ✅ Changed from int to String
  final String driverId; // ✅ Changed from int to String
  final String bookingId; // ✅ Changed from int to String (Firestore doc ID)
  final String customerName;
  final String customerPhone;
  final String vehicleName;
  final String pickupLocation;
  final DateTime pickupTime;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  RideRequest({
    required this.requestId,
    required this.driverId,
    required this.bookingId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleName,
    required this.pickupLocation,
    required this.pickupTime,
    required this.status,
    required this.createdAt,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      requestId: json['request_id']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? '',
      bookingId: json['booking_id']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      vehicleName: json['vehicle_name'] ?? '',
      pickupLocation: json['pickup_location'] ?? '',
      pickupTime: json['pickup_time'] != null
          ? DateTime.parse(json['pickup_time'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'driver_id': driverId,
      'booking_id': bookingId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'vehicle_name': vehicleName,
      'pickup_location': pickupLocation,
      'pickup_time': pickupTime.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}