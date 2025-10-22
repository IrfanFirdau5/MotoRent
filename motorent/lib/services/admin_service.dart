import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/vehicle.dart';
import '../models/booking.dart';
import '../models/report.dart';

class AdminService {
  static const String baseUrl = 'https://your-api-url.com/api/admin';

  // Dashboard Statistics
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard stats: $e');
    }
  }

  // User Management
  Future<List<User>> fetchUsers({String? userType}) async {
    try {
      Map<String, String> queryParams = {};
      if (userType != null && userType != 'all') {
        queryParams['user_type'] = userType;
      }

      final uri = Uri.parse('$baseUrl/users').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<bool> suspendUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/suspend'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error suspending user: $e');
    }
  }

  Future<bool> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Vehicle Management
  Future<List<Vehicle>> fetchAllVehicles() async {
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

  Future<bool> disableVehicle(int vehicleId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles/$vehicleId/disable'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error disabling vehicle: $e');
    }
  }

  Future<bool> deleteVehicle(int vehicleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$vehicleId'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting vehicle: $e');
    }
  }

  // Booking Management
  Future<List<Booking>> fetchBookings({String? status}) async {
    try {
      Map<String, String> queryParams = {};
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/bookings').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  // Report Management
  Future<List<Report>> fetchReports({String? status}) async {
    try {
      Map<String, String> queryParams = {};
      if (status != null && status != 'all') {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/reports').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Report.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reports');
      }
    } catch (e) {
      throw Exception('Error fetching reports: $e');
    }
  }

  Future<bool> resolveReport(int reportId, String adminNotes) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports/$reportId/resolve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'admin_notes': adminNotes}),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error resolving report: $e');
    }
  }

  // Mock Data Methods
  Future<Map<String, dynamic>> fetchMockDashboardStats() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'total_users': 245,
      'total_vehicles': 89,
      'total_bookings': 523,
      'pending_reports': 12,
      'active_bookings': 34,
      'revenue_this_month': 45678.50,
      'new_users_this_week': 18,
      'booking_growth': 12.5, // percentage
    };
  }

  Future<List<User>> fetchMockUsers() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      User(
        userId: 1,
        name: 'Ahmad bin Abdullah',
        email: 'ahmad@example.com',
        phone: '+60123456789',
        address: 'Kuching, Sarawak',
        userType: 'customer',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
      ),
      User(
        userId: 2,
        name: 'Sarah Lim',
        email: 'sarah@example.com',
        phone: '+60198765432',
        address: 'Miri, Sarawak',
        userType: 'owner',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        isActive: true,
      ),
      User(
        userId: 3,
        name: 'Kumar Raj',
        email: 'kumar@example.com',
        phone: '+60187654321',
        address: 'Sibu, Sarawak',
        userType: 'driver',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        isActive: true,
      ),
      User(
        userId: 4,
        name: 'Fatimah Hassan',
        email: 'fatimah@example.com',
        phone: '+60176543210',
        address: 'Bintulu, Sarawak',
        userType: 'customer',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isActive: false,
      ),
    ];
  }

  Future<List<Booking>> fetchMockBookings() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Booking(
        bookingId: 1,
        userId: 1,
        vehicleId: 1,
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        totalPrice: 360.00,
        bookingStatus: 'confirmed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        userName: 'Ahmad bin Abdullah',
        vehicleName: 'Toyota Vios',
        userPhone: '+60123456789',
      ),
      Booking(
        bookingId: 2,
        userId: 2,
        vehicleId: 3,
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        totalPrice: 160.00,
        bookingStatus: 'pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        userName: 'Sarah Lim',
        vehicleName: 'Perodua Myvi',
        userPhone: '+60198765432',
      ),
      Booking(
        bookingId: 3,
        userId: 1,
        vehicleId: 2,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().subtract(const Duration(days: 2)),
        totalPrice: 450.00,
        bookingStatus: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        userName: 'Ahmad bin Abdullah',
        vehicleName: 'Honda Civic',
        userPhone: '+60123456789',
      ),
    ];
  }

  Future<List<Report>> fetchMockReports() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      Report(
        reportId: 1,
        reporterId: 1,
        reporterName: 'Ahmad bin Abdullah',
        reportType: 'vehicle',
        relatedId: 5,
        subject: 'Vehicle not as described',
        description: 'The vehicle had several scratches that were not mentioned in the listing.',
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Report(
        reportId: 2,
        reporterId: 4,
        reporterName: 'Fatimah Hassan',
        reportType: 'user',
        relatedId: 2,
        subject: 'Unprofessional behavior',
        description: 'The car owner was rude and unhelpful during pickup.',
        status: 'investigating',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Report(
        reportId: 3,
        reporterId: 2,
        reporterName: 'Sarah Lim',
        reportType: 'booking',
        relatedId: 15,
        subject: 'Customer did not return vehicle',
        description: 'Customer is 2 days late returning the vehicle and not responding to calls.',
        status: 'resolved',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 2)),
        adminNotes: 'Vehicle has been recovered. Customer suspended.',
      ),
    ];
  }
}