// FILE: lib/models/booking.dart
// ✅ UPDATED: Added location coordinates for map integration

class Booking {
  final dynamic bookingId;
  final String userId;
  final String vehicleId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String bookingStatus;
  final DateTime createdAt;
  final String? userName;
  final String? vehicleName;
  final String? userPhone;
  final bool needDriver;
  final double? driverPrice;
  final int? driverId;
  final String? driverName;
  
  // Payment tracking fields
  final String? paymentStatus;
  final String? paymentIntentId;
  
  // ✅ NEW: Location fields with coordinates
  final String? pickupLocation;
  final String? dropoffLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;

  Booking({
    required this.bookingId,
    required this.userId,
    required this.vehicleId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.bookingStatus,
    required this.createdAt,
    this.userName,
    this.vehicleName,
    this.userPhone,
    this.needDriver = false,
    this.driverPrice,
    this.driverId,
    this.driverName,
    this.paymentStatus,
    this.paymentIntentId,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? 0,
      userId: json['user_id']?.toString() ?? '0',
      vehicleId: json['vehicle_id']?.toString() ?? '0',
      ownerId: json['owner_id']?.toString() ?? '0',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      bookingStatus: json['booking_status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      userName: json['user_name']?.toString(),
      vehicleName: json['vehicle_name']?.toString(),
      userPhone: json['user_phone']?.toString(),
      needDriver: json['need_driver'] ?? false,
      driverPrice: json['driver_price'] != null 
          ? (json['driver_price'] as num).toDouble() 
          : null,
      driverId: json['driver_id'] != null 
          ? (json['driver_id'] is int ? json['driver_id'] : int.tryParse(json['driver_id'].toString()))
          : null,
      driverName: json['driver_name']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      paymentIntentId: json['payment_intent_id']?.toString(),
      pickupLocation: json['pickup_location']?.toString(),
      dropoffLocation: json['dropoff_location']?.toString(),
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
      dropoffLatitude: (json['dropoff_latitude'] as num?)?.toDouble(),
      dropoffLongitude: (json['dropoff_longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'owner_id': ownerId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_price': totalPrice,
      'booking_status': bookingStatus,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'vehicle_name': vehicleName,
      'user_phone': userPhone,
      'need_driver': needDriver,
      'driver_price': driverPrice,
      'driver_id': driverId,
      'driver_name': driverName,
      'payment_status': paymentStatus,
      'payment_intent_id': paymentIntentId,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'dropoff_latitude': dropoffLatitude,
      'dropoff_longitude': dropoffLongitude,
    };
  }

  int get duration => endDate.difference(startDate).inDays + 1;

  String get statusDisplay {
    switch (bookingStatus.toLowerCase()) {
      case 'payment_pending':
        return 'Payment Pending';
      case 'pending':
        return 'Pending Approval';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return bookingStatus;
    }
  }

  String get paymentStatusDisplay {
    switch (paymentStatus?.toLowerCase()) {
      case 'pending':
        return 'Payment Pending';
      case 'authorized':
        return 'Payment Authorized';
      case 'captured':
        return 'Payment Completed';
      case 'cancelled':
        return 'Payment Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  double get vehiclePrice {
    if (needDriver && driverPrice != null) {
      return totalPrice - driverPrice!;
    }
    return totalPrice;
  }

  bool get isPaymentHeld => 
      paymentStatus?.toLowerCase() == 'authorized' && 
      bookingStatus.toLowerCase() == 'pending';

  bool get isPaymentCaptured => 
      paymentStatus?.toLowerCase() == 'captured';

  bool get canBeApproved => 
      bookingStatus.toLowerCase() == 'pending' && 
      paymentStatus?.toLowerCase() == 'authorized';
  
  // ✅ NEW: Check if location data is complete
  bool get hasCompleteLocationData => 
      pickupLocation != null && 
      pickupLatitude != null && 
      pickupLongitude != null;
  
  bool get hasCompleteDriverLocationData => 
      hasCompleteLocationData &&
      dropoffLocation != null &&
      dropoffLatitude != null &&
      dropoffLongitude != null;
}