// FILE: motorent/lib/services/driver_service.dart
// REPLACE THE ENTIRE FILE

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/ride_request.dart';
import '../models/driver_job.dart';
import '../models/driver_earning.dart';
import 'firebase_driver_service.dart';

class DriverService {
  static const String baseUrl = 'https://your-api-url.com/api/driver';
  
  // Use Firebase service
  final FirebaseDriverService _firebaseService = FirebaseDriverService();
  final bool _useFirebase = true; // Set to true to use Firebase

  // ==================== AVAILABILITY ====================
  
  // Get driver availability status
  Future<bool> getDriverAvailability(dynamic driverId) async {
    if (_useFirebase) {
      return await _firebaseService.getDriverAvailability(driverId.toString());
    }
    
    // Legacy mock implementation
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return false;
    } catch (e) {
      throw Exception('Error fetching availability: $e');
    }
  }

  // Update driver availability
  Future<void> updateAvailability(dynamic driverId, bool isAvailable) async {
    if (_useFirebase) {
      await _firebaseService.updateAvailability(driverId.toString(), isAvailable);
      return;
    }
    
    // Legacy mock implementation
    try {
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Error updating availability: $e');
    }
  }

  // ==================== AVAILABILITY SLOTS ====================
  
  // Fetch available slots for driver
  Future<Map<DateTime, List<Map<String, dynamic>>>> fetchAvailableSlots(dynamic driverId) async {
    if (_useFirebase) {
      return await _firebaseService.fetchAvailableSlots(driverId.toString());
    }
    
    // Legacy mock implementation
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
  }

  // Add available time slot
  Future<void> addAvailableSlot(
    dynamic driverId,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    if (_useFirebase) {
      final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      
      await _firebaseService.addAvailableSlot(
        driverId.toString(),
        date,
        startStr,
        endStr,
      );
      return;
    }
    
    // Legacy mock implementation
    await Future.delayed(const Duration(seconds: 1));
  }

  // Remove available time slot
  Future<void> removeAvailableSlot(
    dynamic driverId,
    DateTime date,
    int slotIndex,
  ) async {
    if (_useFirebase) {
      await _firebaseService.removeAvailableSlot(
        driverId.toString(),
        date,
        slotIndex,
      );
      return;
    }
    
    // Legacy mock implementation
    await Future.delayed(const Duration(seconds: 1));
  }

  // ==================== PENDING REQUESTS ====================
  
  // Fetch pending ride requests
  Future<List<RideRequest>> fetchPendingRequests(dynamic driverId) async {
    if (_useFirebase) {
      return await _firebaseService.fetchPendingRequests(driverId.toString());
    }
    
    // Legacy mock implementation
    await Future.delayed(const Duration(seconds: 1));
    return [
      RideRequest(
        requestId: 1,
        driverId: int.tryParse(driverId.toString()) ?? 0,
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
        driverId: int.tryParse(driverId.toString()) ?? 0,
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
  }

  // Respond to ride request
  Future<void> respondToRequest(int requestId, bool accept) async {
    if (_useFirebase) {
      // Note: This needs the booking ID and driver ID
      // The calling code should be updated to pass these
      await _firebaseService.respondToRequestInt(requestId, accept);
      return;
    }
    
    // Legacy mock implementation
    await Future.delayed(const Duration(seconds: 1));
  }

  // ==================== DRIVER STATISTICS ====================
  
  // Fetch driver statistics
  Future<Map<String, dynamic>> fetchDriverStats(dynamic driverId) async {
    if (_useFirebase) {
      return await _firebaseService.fetchDriverStats(driverId.toString());
    }
    
    // Legacy mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'completed_today': 2,
      'upcoming': 3,
      'total_jobs': 45,
      'total_earnings': 1250.50,
    };
  }

  // ==================== DRIVER JOBS ====================
  
  // Fetch driver jobs
  Future<List<DriverJob>> fetchDriverJobs(dynamic driverId) async {
    if (_useFirebase) {
      return await _firebaseService.fetchDriverJobs(driverId.toString());
    }
    
    // Legacy mock implementation
    await Future.delayed(const Duration(seconds: 1));
    return [
      DriverJob(
        jobId: 1,
        driverId: int.tryParse(driverId.toString()) ?? 0,
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
        driverId: int.tryParse(driverId.toString()) ?? 0,
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
    ];
  }

  // Complete a job
  Future<void> completeJob(int jobId) async {
    if (_useFirebase) {
      await _firebaseService.completeJob(jobId.toString());
      return;
    }
    
    // Legacy mock implementation
    await Future.delayed(const Duration(seconds: 1));
  }

  // ==================== DRIVER EARNINGS ====================
  
  // Fetch driver earnings
  Future<List<DriverEarning>> fetchEarnings(dynamic driverId) async {
    if (_useFirebase) {
      return await _firebaseService.fetchEarnings(driverId.toString());
    }
    
    // Legacy mock implementation
    await Future.delayed(const Duration(seconds: 1));
    return [
      DriverEarning(
        earningId: 1,
        driverId: int.tryParse(driverId.toString()) ?? 0,
        jobId: 3,
        amount: 40.00,
        description: 'Sarawak Cultural Village to Kuching Waterfront',
        status: 'paid',
        date: DateTime.now().subtract(const Duration(days: 2)),
        paidAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DriverEarning(
        earningId: 2,
        driverId: int.tryParse(driverId.toString()) ?? 0,
        jobId: 4,
        amount: 80.00,
        description: 'Bako National Park to Kuching City Centre',
        status: 'paid',
        date: DateTime.now().subtract(const Duration(days: 5)),
        paidAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];
  }
}