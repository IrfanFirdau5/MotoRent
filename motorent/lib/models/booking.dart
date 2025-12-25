// FILE: lib/models/booking.dart
// ✅ UPDATED: Added payment tracking fields

class Booking {
  final dynamic bookingId;
  final String userId;
  final String vehicleId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String bookingStatus; // payment_pending, pending, confirmed, cancelled, completed, rejected
  final DateTime createdAt;
  final String? userName;
  final String? vehicleName;
  final String? userPhone;
  final bool needDriver;
  final double? driverPrice;
  final int? driverId;
  final String? driverName;
  
  // ✅ NEW: Payment tracking fields
  final String? paymentStatus; // pending, authorized, captured, cancelled, refunded
  final String? paymentIntentId; // Stripe Payment Intent ID

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

  // ✅ Check if payment is awaiting capture
  bool get isPaymentHeld => 
      paymentStatus?.toLowerCase() == 'authorized' && 
      bookingStatus.toLowerCase() == 'pending';

  // ✅ Check if payment was captured
  bool get isPaymentCaptured => 
      paymentStatus?.toLowerCase() == 'captured';

  // ✅ Check if booking can be approved (has authorized payment)
  bool get canBeApproved => 
      bookingStatus.toLowerCase() == 'pending' && 
      paymentStatus?.toLowerCase() == 'authorized';
}