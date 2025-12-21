// FILE: motorent/lib/models/review.dart
// ✅ FIXED: Changed bookingId to String for Firebase compatibility

class Review {
  final dynamic reviewId; // Can be int or String (Firestore document ID)
  final String bookingId; // ✅ Changed to String for Firebase
  final String userId; // Changed to String for Firebase UID
  final String vehicleId;
  final String userName;
  final String? userProfileImage;
  final int rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;
  final String? vehicleName;

  Review({
    required this.reviewId,
    required this.bookingId,
    required this.userId,
    required this.vehicleId,
    required this.userName,
    this.userProfileImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.vehicleName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['review_id'] ?? '',
      bookingId: json['booking_id']?.toString() ?? '', // ✅ Ensure String
      userId: json['user_id']?.toString() ?? '',
      vehicleId: json['vehicle_id']?.toString() ?? '',
      userName: json['user_name'] ?? '',
      userProfileImage: json['user_profile_image'],
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null
          ? (json['created_at'] is String 
              ? DateTime.parse(json['created_at'])
              : DateTime.now())
          : DateTime.now(),
      vehicleName: json['vehicle_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'booking_id': bookingId,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'user_name': userName,
      'user_profile_image': userProfileImage,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'vehicle_name': vehicleName,
    };
  }

  // Helper method to get review ID as String
  String get reviewIdString => reviewId.toString();

  // Helper method to get star ratings
  List<bool> get starRatings {
    return List.generate(5, (index) => index < rating);
  }
}