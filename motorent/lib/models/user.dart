class User {
  final int userId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String userType; // 'customer', 'owner', 'driver', 'admin'
  final DateTime createdAt;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.userType,
    required this.createdAt,
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
    };
  }

  bool get isCustomer => userType.toLowerCase() == 'customer';
  bool get isOwner => userType.toLowerCase() == 'owner';
  bool get isDriver => userType.toLowerCase() == 'driver';
  bool get isAdmin => userType.toLowerCase() == 'admin';
}