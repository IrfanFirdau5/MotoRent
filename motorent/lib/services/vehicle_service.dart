import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle.dart';

class VehicleService {
  // TODO: Replace with your actual backend API URL
  static const String baseUrl = 'https://your-api-url.com/api';
  
  // Fetch all vehicles
  Future<List<Vehicle>> fetchVehicles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  // Fetch vehicles with filters
  Future<List<Vehicle>> fetchFilteredVehicles({
    String? brand,
    double? minPrice,
    double? maxPrice,
    String? availabilityStatus,
  }) async {
    try {
      Map<String, String> queryParams = {};
      
      if (brand != null && brand.isNotEmpty) {
        queryParams['brand'] = brand;
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }
      if (availabilityStatus != null && availabilityStatus.isNotEmpty) {
        queryParams['availability_status'] = availabilityStatus;
      }

      final uri = Uri.parse('$baseUrl/vehicles').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load filtered vehicles');
      }
    } catch (e) {
      throw Exception('Error fetching filtered vehicles: $e');
    }
  }

  // Fetch single vehicle details
  Future<Vehicle> fetchVehicleById(int vehicleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/$vehicleId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Vehicle.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load vehicle details');
      }
    } catch (e) {
      throw Exception('Error fetching vehicle: $e');
    }
  }

  // Mock data for testing (remove when backend is ready)
  Future<List<Vehicle>> fetchMockVehicles() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      Vehicle(
        vehicleId: 1,
        ownerId: 101,
        brand: 'Toyota',
        model: 'Vios',
        licensePlate: 'QA1234A',
        pricePerDay: 120.00,
        description: 'Comfortable sedan perfect for city driving and short trips.',
        availabilityStatus: 'available',
        imageUrl: 'https://via.placeholder.com/300x200?text=Toyota+Vios',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ownerName: 'Ahmad Rentals',
        rating: 4.5,
        reviewCount: 23,
      ),
      Vehicle(
        vehicleId: 2,
        ownerId: 102,
        brand: 'Honda',
        model: 'Civic',
        licensePlate: 'QB5678B',
        pricePerDay: 150.00,
        description: 'Sporty and fuel-efficient. Great for long distance travel.',
        availabilityStatus: 'available',
        imageUrl: 'https://via.placeholder.com/300x200?text=Honda+Civic',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ownerName: 'Sarawak Motors',
        rating: 4.8,
        reviewCount: 45,
      ),
      Vehicle(
        vehicleId: 3,
        ownerId: 103,
        brand: 'Perodua',
        model: 'Myvi',
        licensePlate: 'QC9012C',
        pricePerDay: 80.00,
        description: 'Affordable and reliable. Perfect for budget travelers.',
        availabilityStatus: 'available',
        imageUrl: 'https://via.placeholder.com/300x200?text=Perodua+Myvi',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ownerName: 'Budget Cars',
        rating: 4.2,
        reviewCount: 67,
      ),
      Vehicle(
        vehicleId: 4,
        ownerId: 104,
        brand: 'Proton',
        model: 'X70',
        licensePlate: 'QD3456D',
        pricePerDay: 180.00,
        description: 'Spacious SUV ideal for family trips and group travel.',
        availabilityStatus: 'available',
        imageUrl: 'https://via.placeholder.com/300x200?text=Proton+X70',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ownerName: 'Family Rentals',
        rating: 4.6,
        reviewCount: 34,
      ),
      Vehicle(
        vehicleId: 5,
        ownerId: 105,
        brand: 'Toyota',
        model: 'Hilux',
        licensePlate: 'QE7890E',
        pricePerDay: 220.00,
        description: 'Powerful pickup truck suitable for rough terrain.',
        availabilityStatus: 'unavailable',
        imageUrl: 'https://via.placeholder.com/300x200?text=Toyota+Hilux',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ownerName: 'Adventure Rides',
        rating: 4.9,
        reviewCount: 12,
      ),
      Vehicle(
        vehicleId: 6,
        ownerId: 106,
        brand: 'Nissan',
        model: 'Almera',
        licensePlate: 'QF2468F',
        pricePerDay: 110.00,
        description: 'Modern sedan with excellent fuel economy.',
        availabilityStatus: 'available',
        imageUrl: 'https://via.placeholder.com/300x200?text=Nissan+Almera',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ownerName: 'City Rentals',
        rating: 4.3,
        reviewCount: 28,
      ),
    ];
  }
}