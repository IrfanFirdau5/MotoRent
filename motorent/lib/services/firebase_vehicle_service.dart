// FILE: motorent/lib/services/firebase_vehicle_service.dart
// CREATE THIS NEW FILE

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';

class FirebaseVehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _vehiclesCollection = 'vehicles';

  // Add a new vehicle
  Future<Map<String, dynamic>> addVehicle({
    required String ownerId,
    required String ownerName,
    required String brand,
    required String model,
    required String licensePlate,
    required double pricePerDay,
    required String description,
    String? imageUrl,
  }) async {
    try {
      // Check if license plate already exists
      final existingVehicle = await _firestore
          .collection(_vehiclesCollection)
          .where('license_plate', isEqualTo: licensePlate.toUpperCase())
          .limit(1)
          .get();

      if (existingVehicle.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'A vehicle with this license plate already exists',
        };
      }

      // Create new vehicle document
      final vehicleData = {
        'owner_id': ownerId,
        'owner_name': ownerName,
        'brand': brand,
        'model': model,
        'license_plate': licensePlate.toUpperCase(),
        'price_per_day': pricePerDay,
        'description': description,
        'availability_status': 'available',
        'image_url': imageUrl ?? 'https://via.placeholder.com/300x200?text=$brand+$model',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'rating': null,
        'review_count': 0,
        'total_bookings': 0,
        'total_revenue': 0.0,
        'is_deleted': false,
        'approval_status': 'pending', // Add this - requires admin approval
        'approved_at': null, // Add this
        'rejection_reason': null, // Add this
      };

      final docRef = await _firestore.collection(_vehiclesCollection).add(vehicleData);

      return {
        'success': true,
        'vehicle_id': docRef.id,
        'message': 'Vehicle added successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add vehicle: $e',
      };
    }
  }

  Future<List<Vehicle>> fetchOwnerVehicles(String ownerId) async {
    try {
      
      final querySnapshot = await _firestore
          .collection(_vehiclesCollection)
          .where('owner_id', isEqualTo: ownerId)
          .where('is_deleted', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .get();


      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['vehicle_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        
        return Vehicle.fromJson(data);
      }).toList();
    } catch (e) {
      
      // If index error, return empty (don't crash)
      if (e.toString().contains('index')) {
        return [];
      }
      
      throw Exception('Failed to load vehicles: $e');
    }
  }

  // Fetch all available vehicles (for customers)
  Future<List<Vehicle>> fetchAvailableVehicles() async {
    try {
      final querySnapshot = await _firestore
          .collection(_vehiclesCollection)
          .where('availability_status', isEqualTo: 'available')
          .where('is_deleted', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['vehicle_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        
        return Vehicle.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load vehicles: $e');
    }
  }

  // Fetch single vehicle by ID
  Future<Vehicle?> fetchVehicleById(String vehicleId) async {
    try {
      final doc = await _firestore.collection(_vehiclesCollection).doc(vehicleId).get();
      
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['vehicle_id'] = doc.id;
      
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
      }
      
      return Vehicle.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // Update vehicle details
  Future<bool> updateVehicle({
    required String vehicleId,
    String? brand,
    String? model,
    String? licensePlate,
    double? pricePerDay,
    String? description,
    String? imageUrl,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (brand != null) updateData['brand'] = brand;
      if (model != null) updateData['model'] = model;
      if (licensePlate != null) updateData['license_plate'] = licensePlate.toUpperCase();
      if (pricePerDay != null) updateData['price_per_day'] = pricePerDay;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['image_url'] = imageUrl;

      await _firestore.collection(_vehiclesCollection).doc(vehicleId).update(updateData);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update vehicle availability status
  Future<bool> updateAvailabilityStatus(String vehicleId, String status) async {
    try {
      await _firestore.collection(_vehiclesCollection).doc(vehicleId).update({
        'availability_status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Soft delete vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      await _firestore.collection(_vehiclesCollection).doc(vehicleId).update({
        'is_deleted': true,
        'availability_status': 'unavailable',
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Fetch filtered vehicles
  Future<List<Vehicle>> fetchFilteredVehicles({
    String? brand,
    double? minPrice,
    double? maxPrice,
    String? availabilityStatus,
  }) async {
    try {
      Query query = _firestore
          .collection(_vehiclesCollection)
          .where('is_deleted', isEqualTo: false);

      if (brand != null && brand != 'All') {
        query = query.where('brand', isEqualTo: brand);
      }

      if (availabilityStatus != null && availabilityStatus != 'All') {
        query = query.where('availability_status', isEqualTo: availabilityStatus.toLowerCase());
      }

      final querySnapshot = await query.orderBy('created_at', descending: true).get();

      List<Vehicle> vehicles = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['vehicle_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        
        return Vehicle.fromJson(data);
      }).toList();

      // Apply price filters (client-side since Firestore doesn't support range queries with other filters)
      if (minPrice != null) {
        vehicles = vehicles.where((v) => v.pricePerDay >= minPrice).toList();
      }
      if (maxPrice != null) {
        vehicles = vehicles.where((v) => v.pricePerDay <= maxPrice).toList();
      }

      return vehicles;
    } catch (e) {
      throw Exception('Failed to load vehicles: $e');
    }
  }

  // Update vehicle statistics after booking
  Future<void> updateVehicleStats(String vehicleId, double bookingAmount) async {
    try {
      await _firestore.collection(_vehiclesCollection).doc(vehicleId).update({
        'total_bookings': FieldValue.increment(1),
        'total_revenue': FieldValue.increment(bookingAmount),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
    }
  }

  // Stream owner's vehicles for real-time updates
  Stream<List<Vehicle>> streamOwnerVehicles(String ownerId) {
    return _firestore
        .collection(_vehiclesCollection)
        .where('owner_id', isEqualTo: ownerId)
        .where('is_deleted', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['vehicle_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        
        return Vehicle.fromJson(data);
      }).toList();
    });
  }

  // Get vehicle statistics
  Future<Map<String, dynamic>> getVehicleStatistics(String vehicleId) async {
    try {
      final vehicle = await fetchVehicleById(vehicleId);
      if (vehicle == null) {
        return {
          'total_bookings': 0,
          'total_revenue': 0.0,
          'average_rating': 0.0,
          'review_count': 0,
        };
      }

      return {
        'total_bookings': vehicle.reviewCount ?? 0,
        'total_revenue': 0.0, // Calculate from bookings
        'average_rating': vehicle.rating ?? 0.0,
        'review_count': vehicle.reviewCount ?? 0,
      };
    } catch (e) {
      return {
        'total_bookings': 0,
        'total_revenue': 0.0,
        'average_rating': 0.0,
        'review_count': 0,
      };
    }
  }
}