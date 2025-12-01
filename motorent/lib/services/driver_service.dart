import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/ride_request.dart';
import '../models/driver_job.dart';
import '../models/driver_earning.dart';

class DriverService {
  static const String baseUrl = 'https://your-api-url.com/api/driver';

  // Get driver availability status
  Future<bool> getDriverAvailability(int driverId) async {
    try {
      // When backend is ready:
      // final response = await http.get(
      //   Uri.parse('$baseUrl/$driverId/availability'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return data['is_available'] ?? false;
      // }
      
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
      return false;
    } catch (e) {
      throw Exception('Error fetching availability: $e');
    }
  }

  // Update driver availability
  Future<void> updateAvailability(int driverId, bool isAvailable) async {
    try {
      // When backend is ready:
      // await http.put(
      //   Uri.parse('$baseUrl/$driverId/availability'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'is_available': isAvailable}),
      // );
      
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Error updating availability: $e');
    }
  }

  // Fetch pending ride requests
  Future<List<RideRequest>> fetchPendingRequests(int driverId) async {
    try {
      // When backend is ready:
      // final response = await http.get(
      //   Uri.parse('$baseUrl/$driverId/requests/pending'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   return data.map((json) => RideRequest.fromJson(json)).toList();
      // }
      
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
      return [
        RideRequest(
          requestId: 1,
          driverId: driverId,
          bookingId: 101,
          customerName: 'Ahmad bin Abdullah',
          customerPhone: '+60123456789',
          vehicleName: 'Toyota Vios',
          pickupLocation: 'Kuching International Airport',
          pickupTime: DateTime.now().add(const Duration(hours: 2)),
          status: 'pending',
          createdAt: DateTime.now(),
        ),
        RideRequest(
          requestId: 2,
          driverId: driverId,
          bookingId: 102,
          customerName: 'Sarah Lim',
          customerPhone: '+60198765432',
          vehicleName: 'Honda Civic',
          pickupLocation: 'Vivacity Megamall, Kuching',
          pickupTime: DateTime.now().add(const Duration(hours: 4)),
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      throw Exception('Error fetching requests: $e');
    }
  }

  // Respond to ride request
  Future<void> respondToRequest(int requestId, bool accept) async {
    try {
      // When backend is ready:
      // await http.post(
      //   Uri.parse('$baseUrl/requests/$requestId/respond'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'accept': accept}),
      // );
      
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Error responding to request: $e');
    }
  }

  // Fetch driver statistics
  Future<Map<String, dynamic>> fetchDriverStats(int driverId) async {
    try {
      // When backend is ready:
      // final response = await http.get(
      //   Uri.parse('$baseUrl/$driverId/stats'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // if (response.statusCode == 200) {
      //   return json.decode(response.body);
      // }
      
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
      return {
        'completed_today': 2,
        'upcoming': 3,
        'total_jobs': 45,
        'total_earnings': 1250.50,
      };
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  // Fetch driver jobs
  Future<List<DriverJob>> fetchDriverJobs(int driverId) async {
    try {
      // When backend is ready:
      // final response = await http.get(
      //   Uri.parse('$baseUrl/$driverId/jobs'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   return data.map((json) => DriverJob.fromJson(json)).toList();
      // }
      
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
      return [
        DriverJob(
          jobId: 1,
          driverId: driverId,
          bookingId: 101,
          customerName: 'Ahmad bin Abdullah',
          customerPhone: '+60123456789',
          vehicleName: 'Toyota Vios',
          pickupLocation: 'Kuching International Airport',
          dropoffLocation: 'Hotel Grand Margherita',
          pickupTime: DateTime.now().add(const Duration(days: 1)),
          duration: 3,
          payment: 90.00,
          status: 'scheduled',
          createdAt: DateTime.now(),
        ),
        DriverJob(
          jobId: 2,
          driverId: driverId,
          bookingId: 102,
          customerName: 'Sarah Lim',
          customerPhone: '+60198765432',
          vehicleName: 'Honda Civic',
          pickupLocation: 'Vivacity Megamall',
          dropoffLocation: 'Borneo Convention Centre Kuching',
          pickupTime: DateTime.now().add(const Duration(days: 2)),
          duration: 2,
          payment: 60.00,
          status: 'scheduled',
          createdAt: DateTime.now(),
        ),
        DriverJob(
          jobId: 3,
          driverId: driverId,
          bookingId: 103,
          customerName: 'Kumar Raj',
          customerPhone: '+60187654321',
          vehicleName: 'Perodua Myvi',
          pickupLocation: 'Sarawak Cultural Village',
          dropoffLocation: 'Kuching Waterfront',
          pickupTime: DateTime.now().subtract(const Duration(days: 2)),
          duration: 1,
          payment: 40.00,
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        DriverJob(
          jobId: 4,
          driverId: driverId,
          bookingId: 104,
          customerName: 'Fatimah Hassan',
          customerPhone: '+60176543210',
          vehicleName: 'Proton X70',
          pickupLocation: 'Bako National Park',
          dropoffLocation: 'Kuching City Centre',
          pickupTime: DateTime.now().subtract(const Duration(days: 5)),
          duration: 2,
          payment: 80.00,
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ];
    } catch (e) {
      throw Exception('Error fetching jobs: $e');
    }
  }

  // Complete a job
  Future<void> completeJob(int jobId) async {
    try {
      // When backend is ready:
      // await http.post(
      //   Uri.parse('$baseUrl/jobs/$jobId/complete'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Error completing job: $e');
    }
  }

  // Fetch driver earnings
  Future<List<DriverEarning>> fetchEarnings(int driverId) async {
    try {
      // When backend is ready:
      // final response = await http.get(
      //   Uri.parse('$baseUrl/$driverId/earnings'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   return data.map((json) => DriverEarning.fromJson(json)).toList();
      // }
      
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
      return [
        DriverEarning(
          earningId: 1,
          driverId: driverId,
          jobId: 3,
          amount: 40.00,
          description: 'Sarawak Cultural Village to Kuching Waterfront',
          status: 'paid',
          date: DateTime.now().subtract(const Duration(days: 2)),
          paidAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        DriverEarning(
          earningId: 2,
          driverId: driverId,
          jobId: 4,
          amount: 80.00,
          description: 'Bako National Park to Kuching City Centre',
          status: 'paid',
          date: DateTime.now().subtract(const Duration(days: 5)),
          paidAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        DriverEarning(
          earningId: 3,
          driverId: driverId,
          jobId: 1,
          amount: 90.00,
          description: 'Kuching International Airport to Hotel Grand Margherita',
          status: 'pending',
          date: DateTime.now(),
        ),
        DriverEarning(
          earningId: 4,
          driverId: driverId,
          jobId: 2,
          amount: 60.00,
          description: 'Vivacity Megamall to Borneo Convention Centre',
          status: 'pending',
          date: DateTime.now(),
        ),
      ];
    } catch (e) {
      throw Exception('Error fetching earnings: $e');
    }
  }

  // Fetch available slots for driver
  Future<Map<DateTime, List<Map<String, dynamic>>>> fetchAvailableSlots(int driverId) async {
    try {
      // When backend is ready:
      // final response = await http.get(
      //   Uri.parse('$baseUrl/$driverId/availability/slots'),
      //   headers: {'Content-Type': 'application/json'},
      // );
      // if (response.statusCode == 200) {
      //   final Map<String, dynamic> data = json.decode(response.body);
      //   // Parse and return slots
      // }
      
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      
      return {
        DateTime(today.year, today.month, today.day): [
          {'start': '09:00', 'end': '12:00', 'booked': false},
          {'start': '14:00', 'end': '17:00', 'booked': false},
        ],
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day): [
          {'start': '08:00', 'end': '11:00', 'booked': true},
          {'start': '15:00', 'end': '18:00', 'booked': false},
        ],
      };
    } catch (e) {
      throw Exception('Error fetching slots: $e');
    }
  }

  // Add available time slot
  Future<void> addAvailableSlot(
    int driverId,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    try {
      // When backend is ready:
      // await http.post(
      //   Uri.parse('$baseUrl/$driverId/availability/slots'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({
      //     'date': date.toIso8601String(),
      //     'start_time': '${startTime.hour}:${startTime.minute}',
      //     'end_time': '${endTime.hour}:${endTime.minute}',
      //   }),
      // );
      
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Error adding slot: $e');
    }
  }

  // Remove available time slot
  Future<void> removeAvailableSlot(
    int driverId,
    DateTime date,
    int slotIndex,
  ) async {
    try {
      // When backend is ready:
      // await http.delete(
      //   Uri.parse('$baseUrl/$driverId/availability/slots/$slotIndex'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'date': date.toIso8601String()}),
      // );
      
      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Error removing slot: $e');
    }
  }
}