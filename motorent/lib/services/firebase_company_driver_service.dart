// FILE: motorent/lib/services/firebase_company_driver_service.dart
// CREATE THIS NEW FILE

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseCompanyDriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _driversCollection = 'company_drivers';

  // Add a new company driver
  Future<Map<String, dynamic>> addCompanyDriver({
    required String ownerId,
    required String name,
    required String email,
    required String phone,
    required String licenseNumber,
    required String address,
    String? userId, // Optional: if driver has a user account
  }) async {
    try {
      // Check if email already exists
      final existingDriver = await _firestore
          .collection(_driversCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingDriver.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'A driver with this email already exists',
        };
      }

      // Create driver document
      final driverData = {
        'owner_id': ownerId,
        'user_id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'license_number': licenseNumber.toUpperCase(),
        'address': address,
        'status': 'available',
        'is_active': true,
        'total_jobs': 0,
        'rating': null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_driversCollection).add(driverData);

      return {
        'success': true,
        'driver_id': docRef.id,
        'message': 'Company driver added successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add driver: $e',
      };
    }
  }

  // Fetch owner's company drivers
// Fetch owner's company drivers
Future<List<CompanyDriver>> fetchOwnerDrivers(String ownerId) async {
  try {
    
    final querySnapshot = await _firestore
        .collection(_driversCollection)
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: true)
        .get();


    if (querySnapshot.docs.isEmpty) {
      return [];
    }

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['driver_id'] = doc.id;
      
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp).toDate();
      }
      if (data['updated_at'] is Timestamp) {
        data['updated_at'] = (data['updated_at'] as Timestamp).toDate();
      }
      
      return CompanyDriver.fromJson(data);
    }).toList();
  } catch (e) {
    
    // If index error, return empty
    if (e.toString().contains('index')) {
      return [];
    }
    
    throw Exception('Failed to load drivers: $e');
  }
}

  // Update driver status
  Future<bool> updateDriverStatus(String driverId, String status) async {
    try {
      await _firestore.collection(_driversCollection).doc(driverId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Toggle driver active status
  Future<bool> toggleDriverActiveStatus(String driverId, bool isActive) async {
    try {
      await _firestore.collection(_driversCollection).doc(driverId).update({
        'is_active': isActive,
        'status': isActive ? 'available' : 'offline',
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update driver details
  Future<bool> updateDriverDetails({
    required String driverId,
    String? name,
    String? email,
    String? phone,
    String? licenseNumber,
    String? address,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (licenseNumber != null) updateData['license_number'] = licenseNumber.toUpperCase();
      if (address != null) updateData['address'] = address;

      await _firestore.collection(_driversCollection).doc(driverId).update(updateData);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete driver
  Future<bool> deleteDriver(String driverId) async {
    try {
      await _firestore.collection(_driversCollection).doc(driverId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get driver by ID
  Future<CompanyDriver?> getDriverById(String driverId) async {
    try {
      final doc = await _firestore.collection(_driversCollection).doc(driverId).get();
      
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['driver_id'] = doc.id;
      
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp).toDate();
      }
      if (data['updated_at'] is Timestamp) {
        data['updated_at'] = (data['updated_at'] as Timestamp).toDate();
      }
      
      return CompanyDriver.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // Stream owner's drivers for real-time updates
  Stream<List<CompanyDriver>> streamOwnerDrivers(String ownerId) {
    return _firestore
        .collection(_driversCollection)
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['driver_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate();
        }
        if (data['updated_at'] is Timestamp) {
          data['updated_at'] = (data['updated_at'] as Timestamp).toDate();
        }
        
        return CompanyDriver.fromJson(data);
      }).toList();
    });
  }

  // Get driver statistics
  Future<Map<String, dynamic>> getDriverStats(String ownerId) async {
    try {
      final drivers = await fetchOwnerDrivers(ownerId);
      
      int total = drivers.length;
      int available = drivers.where((d) => d.status == 'available' && d.isActive).length;
      int onJob = drivers.where((d) => d.status == 'on_job').length;
      int offline = drivers.where((d) => d.status == 'offline' || !d.isActive).length;

      return {
        'total': total,
        'available': available,
        'on_job': onJob,
        'offline': offline,
      };
    } catch (e) {
      return {
        'total': 0,
        'available': 0,
        'on_job': 0,
        'offline': 0,
      };
    }
  }

  // Update driver job count and rating
  Future<void> updateDriverPerformance(String driverId, {
    int? jobIncrement,
    double? newRating,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (jobIncrement != null) {
        updateData['total_jobs'] = FieldValue.increment(jobIncrement);
      }

      if (newRating != null) {
        updateData['rating'] = newRating;
      }

      await _firestore.collection(_driversCollection).doc(driverId).update(updateData);
    } catch (e) {
    }
  }
}

// Company Driver Model Class
class CompanyDriver {
  final String driverId;
  final String ownerId;
  final String? userId;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final String address;
  final String status;
  final bool isActive;
  final int totalJobs;
  final double? rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyDriver({
    required this.driverId,
    required this.ownerId,
    this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.address,
    required this.status,
    required this.isActive,
    required this.totalJobs,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyDriver.fromJson(Map<String, dynamic> json) {
    return CompanyDriver(
      driverId: json['driver_id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      userId: json['user_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? 'available',
      isActive: json['is_active'] ?? true,
      totalJobs: json['total_jobs'] ?? 0,
      rating: json['rating']?.toDouble(),
      createdAt: json['created_at'] is DateTime 
          ? json['created_at'] 
          : DateTime.now(),
      updatedAt: json['updated_at'] is DateTime 
          ? json['updated_at'] 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'owner_id': ownerId,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'license_number': licenseNumber,
      'address': address,
      'status': status,
      'is_active': isActive,
      'total_jobs': totalJobs,
      'rating': rating,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}