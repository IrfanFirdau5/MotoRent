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
  final String? approvalStatus;
  final String? rejectionReason; 
  final bool isLicenseVerified;
  final String? licenseNumber;
  final String? licenseImageUrl;
  final String? licenseVerificationStatus; // pending, approved, rejected

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
    this.approvalStatus,
    this.rejectionReason,
    this.isLicenseVerified = false,
    this.licenseNumber,
    this.licenseImageUrl,
    this.licenseVerificationStatus,
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
      approvalStatus: json['approval_status'], 
      rejectionReason: json['rejection_reason'], 
      isLicenseVerified: json['is_license_verified'] ?? false,
      licenseNumber: json['license_number'],
      licenseImageUrl: json['license_image_url'],
      licenseVerificationStatus: json['license_verification_status'],
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
      'approval_status': approvalStatus, // Add this
      'rejection_reason': rejectionReason, // Add this
      'is_license_verified': isLicenseVerified,
      'license_number': licenseNumber,
      'license_image_url': licenseImageUrl,
      'license_verification_status': licenseVerificationStatus,
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
  bool get isPending => approvalStatus?.toLowerCase() == 'pending';
  bool get isApproved => approvalStatus?.toLowerCase() == 'approved';
  bool get isRejected => approvalStatus?.toLowerCase() == 'rejected';

  // Check if user can book vehicles
  bool get canBookVehicles => isCustomer && isLicenseVerified;
  
  // Get verification status display text
  String get licenseStatusDisplay {
    if (isLicenseVerified) return 'Verified';
    if (licenseVerificationStatus == null) return 'Not Submitted';
    switch (licenseVerificationStatus?.toLowerCase()) {
      case 'pending':
        return 'Pending Verification';
      case 'approved':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Not Submitted';
    }
  }
}