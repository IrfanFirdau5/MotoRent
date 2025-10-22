class Booking {
  final int bookingId;
  final int userId;
  final int vehicleId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String bookingStatus; // pending, confirmed, cancelled, completed
  final DateTime createdAt;
  final String? userName;
  final String? vehicleName;
  final String? userPhone;

  Booking({
    required this.bookingId,
    required this.userId,
    required this.vehicleId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.bookingStatus,
    required this.createdAt,
    this.userName,
    this.vehicleName,
    this.userPhone,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      bookingStatus: json['booking_status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      userName: json['user_name'],
      vehicleName: json['vehicle_name'],
      userPhone: json['user_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_price': totalPrice,
      'booking_status': bookingStatus,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'vehicle_name': vehicleName,
      'user_phone': userPhone,
    };
  }

  int get duration => endDate.difference(startDate).inDays + 1;

  String get statusDisplay {
    switch (bookingStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return bookingStatus;
    }
  }
}