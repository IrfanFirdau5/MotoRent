// FILE: motorent/lib/services/vehicle_service.dart
// REPLACE THE ENTIRE FILE WITH THIS

import '../models/vehicle.dart';
import 'firebase_vehicle_service.dart';

class VehicleService {
  final FirebaseVehicleService _firebaseService = FirebaseVehicleService();

  // Fetch all available vehicles (delegates to Firebase)
  Future<List<Vehicle>> fetchAvailableVehicles() async {
    return await _firebaseService.fetchAvailableVehicles();
  }

  // Fetch owner's vehicles (delegates to Firebase)
  Future<List<Vehicle>> fetchOwnerVehicles(String ownerId) async {
    return await _firebaseService.fetchOwnerVehicles(ownerId);
  }

  // Fetch vehicle by ID (delegates to Firebase)
  Future<Vehicle?> fetchVehicleById(String vehicleId) async {
    return await _firebaseService.fetchVehicleById(vehicleId);
  }

  // Fetch filtered vehicles (delegates to Firebase)
  Future<List<Vehicle>> fetchFilteredVehicles({
    String? brand,
    double? minPrice,
    double? maxPrice,
    String? availabilityStatus,
  }) async {
    return await _firebaseService.fetchFilteredVehicles(
      brand: brand,
      minPrice: minPrice,
      maxPrice: maxPrice,
      availabilityStatus: availabilityStatus,
    );
  }

  // Add a new vehicle (delegates to Firebase)
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
    return await _firebaseService.addVehicle(
      ownerId: ownerId,
      ownerName: ownerName,
      brand: brand,
      model: model,
      licensePlate: licensePlate,
      pricePerDay: pricePerDay,
      description: description,
      imageUrl: imageUrl,
    );
  }

  // Update vehicle details (delegates to Firebase)
  Future<bool> updateVehicle({
    required String vehicleId,
    String? brand,
    String? model,
    String? licensePlate,
    double? pricePerDay,
    String? description,
    String? imageUrl,
  }) async {
    return await _firebaseService.updateVehicle(
      vehicleId: vehicleId,
      brand: brand,
      model: model,
      licensePlate: licensePlate,
      pricePerDay: pricePerDay,
      description: description,
      imageUrl: imageUrl,
    );
  }

  // Update vehicle availability status (delegates to Firebase)
  Future<bool> updateAvailabilityStatus(String vehicleId, String status) async {
    return await _firebaseService.updateAvailabilityStatus(vehicleId, status);
  }

  // Delete vehicle (delegates to Firebase)
  Future<bool> deleteVehicle(String vehicleId) async {
    return await _firebaseService.deleteVehicle(vehicleId);
  }

  // Get vehicle statistics (delegates to Firebase)
  Future<Map<String, dynamic>> getVehicleStatistics(String vehicleId) async {
    return await _firebaseService.getVehicleStatistics(vehicleId);
  }

  // Stream owner's vehicles for real-time updates (delegates to Firebase)
  Stream<List<Vehicle>> streamOwnerVehicles(String ownerId) {
    return _firebaseService.streamOwnerVehicles(ownerId);
  }

  // MOCK DATA METHODS (for backward compatibility during transition)
  // These can be removed once all components use Firebase

  Future<List<Vehicle>> fetchMockVehicles() async {
    // For backward compatibility, delegate to Firebase
    return await fetchAvailableVehicles();
  }

  Future<Map<String, dynamic>> mockAddVehicle({
    required String ownerId,
    required String ownerName,
    required String brand,
    required String model,
    required String licensePlate,
    required double pricePerDay,
    required String description,
    String? imageUrl,
  }) async {
    return await addVehicle(
      ownerId: ownerId,
      ownerName: ownerName,
      brand: brand,
      model: model,
      licensePlate: licensePlate,
      pricePerDay: pricePerDay,
      description: description,
      imageUrl: imageUrl,
    );
  }

  Future<bool> mockUpdateVehicle({
    required String vehicleId,
    String? brand,
    String? model,
    String? licensePlate,
    double? pricePerDay,
    String? description,
    String? imageUrl,
  }) async {
    return await updateVehicle(
      vehicleId: vehicleId,
      brand: brand,
      model: model,
      licensePlate: licensePlate,
      pricePerDay: pricePerDay,
      description: description,
      imageUrl: imageUrl,
    );
  }

  Future<bool> mockDeleteVehicle(String vehicleId) async {
    return await deleteVehicle(vehicleId);
  }

  Future<bool> mockUpdateAvailability(String vehicleId, String status) async {
    return await updateAvailabilityStatus(vehicleId, status);
  }
}