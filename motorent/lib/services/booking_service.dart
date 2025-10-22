import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking.dart';

class BookingService {
  // TODO: Replace with your actual backend API URL
  static const String baseUrl = 'https://your-api-url.com/api';

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required int userId,
    required int vehicleId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'vehicle_id': vehicleId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'total_price': totalPrice,
          'booking_status': 'pending',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'booking': Booking.fromJson(data['booking']),
          'message': 'Booking created successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create booking',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Fetch user's bookings
  Future<List<Booking>> fetchUserBookings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/user/$userId'),
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

  // Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Booking cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to cancel booking',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Check vehicle availability for dates
  Future<bool> checkAvailability({
    required int vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/$vehicleId/availability'
            '?start_date=${startDate.toIso8601String()}'
            '&end_date=${endDate.toIso8601String()}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['available'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Mock create booking for testing
  Future<Map<String, dynamic>> mockCreateBooking({
    required int userId,
    required int vehicleId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    String? userName,
    String? vehicleName,
    String? userPhone,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final newBooking = Booking(
      bookingId: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      bookingStatus: 'confirmed',
      createdAt: DateTime.now(),
      userName: userName,
      vehicleName: vehicleName,
      userPhone: userPhone,
    );

    return {
      'success': true,
      'booking': newBooking,
      'message': 'Booking created successfully',
    };
  }

  // Mock fetch user bookings
  Future<List<Booking>> mockFetchUserBookings(int userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return [
      Booking(
        bookingId: 1001,
        userId: userId,
        vehicleId: 1,
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        totalPrice: 360.00,
        bookingStatus: 'confirmed',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        userName: 'John Doe',
        vehicleName: 'Toyota Vios',
        userPhone: '0123456789',
      ),
      Booking(
        bookingId: 1002,
        userId: userId,
        vehicleId: 3,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().subtract(const Duration(days: 7)),
        totalPrice: 240.00,
        bookingStatus: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        userName: 'John Doe',
        vehicleName: 'Perodua Myvi',
        userPhone: '0123456789',
      ),
      Booking(
        bookingId: 1003,
        userId: userId,
        vehicleId: 2,
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 12)),
        totalPrice: 450.00,
        bookingStatus: 'pending',
        createdAt: DateTime.now(),
        userName: 'John Doe',
        vehicleName: 'Honda Civic',
        userPhone: '0123456789',
      ),
    ];
  }

  // Mock cancel booking
  Future<Map<String, dynamic>> mockCancelBooking(int bookingId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return {
      'success': true,
      'message': 'Booking cancelled successfully',
    };
  }
}