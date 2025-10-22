class Review {
  final int reviewId;
  final int bookingId;
  final int userId;
  final int vehicleId;
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime createdAt;
  final String? userName;
  final String? userProfileImage;

  Review({
    required this.reviewId,
    required this.bookingId,
    required this.userId,
    required this.vehicleId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userName,
    this.userProfileImage,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['review_id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      userName: json['user_name'],
      userProfileImage: json['user_profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'booking_id': bookingId,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'user_profile_image': userProfileImage,
    };
  }

  String get ratingDisplay => rating.toStringAsFixed(1);
  
  int get fullStars => rating.floor();
  bool get hasHalfStar => (rating - rating.floor()) >= 0.5;
  int get emptyStars => 5 - fullStars - (hasHalfStar ? 1 : 0);
}