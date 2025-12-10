class User {
  final dynamic userId; // Can be int or String (Firebase UID)
  final String name;
  final String email;
  final String phone;
  final String address;
  final String userType; // customer, owner, admin, driver
  final DateTime createdAt;
  final bool isActive;
  final String? profileImage;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.userType,
    required this.createdAt,
    this.isActive = true,
    this.profileImage,
  });

  // Factory constructor to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      userType: json['user_type'] ?? 'customer',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
      profileImage: json['profile_image'],
    );
  }

  // Method to convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'user_type': userType,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'profile_image': profileImage,
    };
  }

  String get userTypeDisplay {
    switch (userType.toLowerCase()) {
      case 'customer':
        return 'Customer';
      case 'owner':
        return 'Car Owner';
      case 'admin':
        return 'Administrator';
      case 'driver':
        return 'Driver';
      default:
        return userType;
    }
  }

  bool get isCustomer => userType.toLowerCase() == 'customer';
  bool get isOwner => userType.toLowerCase() == 'owner';
  bool get isDriver => userType.toLowerCase() == 'driver';
  bool get isAdmin => userType.toLowerCase() == 'admin';

  // Helper method to get user ID as String (useful for Firebase)
  String get userIdString => userId.toString();
}