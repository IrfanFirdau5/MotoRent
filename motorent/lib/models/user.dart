class User {
  final int userId;
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
}