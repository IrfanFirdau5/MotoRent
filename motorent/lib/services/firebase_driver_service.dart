// FILE: motorent/lib/services/firebase_driver_service.dart
// REPLACE THE ENTIRE FILE WITH THIS

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_request.dart';
import '../models/driver_job.dart';
import '../models/driver_earning.dart';

class FirebaseDriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  final String _usersCollection = 'users';
  final String _driverJobsCollection = 'driver_jobs';
  final String _bookingsCollection = 'bookings';

  // ==================== AVAILABILITY ====================
  
  // Get driver availability status
  Future<bool> getDriverAvailability(String driverId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(driverId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      return data['is_available'] ?? false;
    } catch (e) {
      print('Error fetching driver availability: $e');
      return false;
    }
  }

  // Update driver availability
  Future<void> updateAvailability(String driverId, bool isAvailable) async {
    try {
      await _firestore.collection(_usersCollection).doc(driverId).update({
        'is_available': isAvailable,
        'availability_updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating availability: $e');
      throw Exception('Failed to update availability: $e');
    }
  }

  // ==================== AVAILABILITY SLOTS ====================
  
  // Fetch available slots for driver
  Future<Map<DateTime, List<Map<String, dynamic>>>> fetchAvailableSlots(String driverId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(driverId).get();
      
      if (!doc.exists || doc.data()?['availability_slots'] == null) {
        return {};
      }

      final slotsData = doc.data()!['availability_slots'] as Map<String, dynamic>;
      Map<DateTime, List<Map<String, dynamic>>> slots = {};

      slotsData.forEach((dateStr, slotsJson) {
        final date = DateTime.parse(dateStr);
        final slotsList = (slotsJson as List).map((slot) => {
          'start': slot['start'],
          'end': slot['end'],
          'booked': slot['booked'] ?? false,
        }).toList();
        
        slots[date] = List<Map<String, dynamic>>.from(slotsList);
      });

      return slots;
    } catch (e) {
      print('Error fetching slots: $e');
      return {};
    }
  }

  // Add available time slot
  Future<void> addAvailableSlot(
    String driverId,
    DateTime date,
    String startTime,
    String endTime,
  ) async {
    try {
      final dateKey = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
      
      final doc = await _firestore.collection(_usersCollection).doc(driverId).get();
      Map<String, dynamic> currentSlots = {};
      
      if (doc.exists && doc.data()?['availability_slots'] != null) {
        currentSlots = Map<String, dynamic>.from(doc.data()!['availability_slots']);
      }

      List<dynamic> daySlots = currentSlots[dateKey] ?? [];
      daySlots.add({
        'start': startTime,
        'end': endTime,
        'booked': false,
      });

      currentSlots[dateKey] = daySlots;

      await _firestore.collection(_usersCollection).doc(driverId).update({
        'availability_slots': currentSlots,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding slot: $e');
      throw Exception('Failed to add time slot: $e');
    }
  }

  // Remove available time slot
  Future<void> removeAvailableSlot(
    String driverId,
    DateTime date,
    int slotIndex,
  ) async {
    try {
      final dateKey = DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];
      
      final doc = await _firestore.collection(_usersCollection).doc(driverId).get();
      
      if (!doc.exists || doc.data()?['availability_slots'] == null) {
        throw Exception('No slots found');
      }

      Map<String, dynamic> currentSlots = Map<String, dynamic>.from(doc.data()!['availability_slots']);
      List<dynamic> daySlots = currentSlots[dateKey] ?? [];

      if (slotIndex < 0 || slotIndex >= daySlots.length) {
        throw Exception('Invalid slot index');
      }

      daySlots.removeAt(slotIndex);
      
      if (daySlots.isEmpty) {
        currentSlots.remove(dateKey);
      } else {
        currentSlots[dateKey] = daySlots;
      }

      await _firestore.collection(_usersCollection).doc(driverId).update({
        'availability_slots': currentSlots,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing slot: $e');
      throw Exception('Failed to remove time slot: $e');
    }
  }

  // ==================== PENDING REQUESTS ====================
  
  // Fetch pending ride requests for driver - WITH DEBUG LOGGING
  Future<List<RideRequest>> fetchPendingRequests(String driverId) async {
    try {
      print('🔍 Fetching pending requests for driver: $driverId');
      
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('need_driver', isEqualTo: true)
          .where('driver_request_status', isEqualTo: 'pending')
          .where('booking_status', isEqualTo: 'confirmed')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      print('✅ Found ${querySnapshot.docs.length} pending requests');
      
      final requests = querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        print('   ✓ Booking ID: ${doc.id}'); // ✅ Should show the real Firestore ID
        
        return RideRequest(
          requestId: '', // ✅ Empty string
          driverId: driverId, // ✅ String
          bookingId: doc.id, // ✅ CRITICAL: Firestore document ID
          customerName: data['user_name'] ?? '',
          customerPhone: data['user_phone'] ?? '',
          vehicleName: data['vehicle_name'] ?? '',
          pickupLocation: data['pickup_location'] ?? 'Location not specified',
          pickupTime: (data['start_date'] as Timestamp).toDate(),
          status: data['driver_request_status'] ?? 'pending',
          createdAt: (data['created_at'] as Timestamp).toDate(),
        );
      }).toList();
      
      return requests;
    } catch (e) {
      print('❌ Error fetching pending requests: $e');
      return [];
    }
  }

  // Respond to ride request (accept/reject) - overload for int
  Future<void> respondToRequestInt(int requestId, bool accept) async {
    // This is kept for backward compatibility but should use string version
    await respondToRequest(requestId.toString(), '', accept);
  }

  // Respond to ride request (accept/reject)
  Future<void> respondToRequest(String bookingId, String driverId, bool accept) async {
    try {
      print('🔵 Driver responding to request');
      print('   Firestore Booking ID: $bookingId'); // ✅ Should now be the real ID
      print('   Accept: $accept');
      print('   Driver ID: $driverId');
      
      // ✅ VALIDATION: Check if bookingId looks valid
      if (bookingId.isEmpty || bookingId == '0' || bookingId == 'null') {
        print('❌ ERROR: Invalid booking ID: "$bookingId"');
        throw Exception('Invalid booking ID. This should be the Firestore document ID.');
      }
      
      if (accept) {
        // Accept the request
        await _firestore.collection(_bookingsCollection).doc(bookingId).update({
          'driver_id': driverId,
          'driver_request_status': 'accepted',
          'updated_at': FieldValue.serverTimestamp(),
        });

        print('   ✅ Booking updated with driver ID');

        // Create a driver job entry
        final bookingDoc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
        
        if (!bookingDoc.exists) {
          print('   ❌ ERROR: Booking document not found after update!');
          throw Exception('Booking not found');
        }
        
        final bookingData = bookingDoc.data()!;

        final jobData = {
          'driver_id': driverId,
          'booking_id': bookingId, // ✅ Store the actual Firestore document ID
          'customer_name': bookingData['user_name'],
          'customer_phone': bookingData['user_phone'],
          'vehicle_name': bookingData['vehicle_name'],
          'pickup_location': bookingData['pickup_location'] ?? 'Not specified',
          'dropoff_location': bookingData['dropoff_location'] ?? 'Not specified',
          'pickup_time': bookingData['start_date'],
          'return_time': bookingData['end_date'],
          'duration': _calculateDays(
            (bookingData['start_date'] as Timestamp).toDate(),
            (bookingData['end_date'] as Timestamp).toDate(),
          ),
          'payment': bookingData['driver_price'] ?? 0.0,
          'status': 'scheduled',
          'created_at': FieldValue.serverTimestamp(),
        };

        final jobRef = await _firestore.collection(_driverJobsCollection).add(jobData);
        
        print('   ✅ Driver job created: ${jobRef.id}');
        print('   Payment: RM ${jobData['payment']}');
        
      } else {
        // Reject the request
        await _firestore.collection(_bookingsCollection).doc(bookingId).update({
          'driver_request_status': 'rejected',
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        print('   ✅ Request rejected');
      }
    } catch (e) {
      print('❌ Error responding to request: $e');
      print('   Booking ID was: $bookingId');
      print('   Driver ID was: $driverId');
      throw Exception('Failed to respond to request: $e');
    }
  }

  // ==================== DRIVER STATISTICS ====================
  
  // Fetch driver statistics
  Future<Map<String, dynamic>> fetchDriverStats(String driverId) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      // Get today's completed jobs
      final completedTodaySnapshot = await _firestore
          .collection(_driverJobsCollection)
          .where('driver_id', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .where('pickup_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('pickup_time', isLessThan: Timestamp.fromDate(endOfToday))
          .get();

      // Get upcoming jobs
      final upcomingSnapshot = await _firestore
          .collection(_driverJobsCollection)
          .where('driver_id', isEqualTo: driverId)
          .where('status', isEqualTo: 'scheduled')
          .where('pickup_time', isGreaterThan: Timestamp.fromDate(now))
          .get();

      // Get all completed jobs
      final allCompletedSnapshot = await _firestore
          .collection(_driverJobsCollection)
          .where('driver_id', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalEarnings = 0.0;
      for (var doc in allCompletedSnapshot.docs) {
        totalEarnings += (doc.data()['payment'] ?? 0.0).toDouble();
      }

      return {
        'completed_today': completedTodaySnapshot.docs.length,
        'upcoming': upcomingSnapshot.docs.length,
        'total_jobs': allCompletedSnapshot.docs.length,
        'total_earnings': totalEarnings,
      };
    } catch (e) {
      print('Error fetching driver stats: $e');
      return {
        'completed_today': 0,
        'upcoming': 0,
        'total_jobs': 0,
        'total_earnings': 0.0,
      };
    }
  }

  // ==================== DRIVER JOBS ====================
  
  // Fetch driver jobs
  Future<List<DriverJob>> fetchDriverJobs(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_driverJobsCollection)
          .where('driver_id', isEqualTo: driverId)
          .orderBy('pickup_time', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        return DriverJob(
          jobId: int.tryParse(doc.id) ?? 0,
          driverId: int.tryParse(driverId) ?? 0,
          bookingId: int.tryParse(data['booking_id']?.toString() ?? '0') ?? 0,
          customerName: data['customer_name'] ?? '',
          customerPhone: data['customer_phone'] ?? '',
          vehicleName: data['vehicle_name'] ?? '',
          pickupLocation: data['pickup_location'] ?? '',
          dropoffLocation: data['dropoff_location'] ?? '',
          pickupTime: (data['pickup_time'] as Timestamp).toDate(),
          duration: data['duration'] ?? 1,
          payment: (data['payment'] ?? 0.0).toDouble(),
          status: data['status'] ?? 'scheduled',
          createdAt: (data['created_at'] as Timestamp).toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error fetching driver jobs: $e');
      return [];
    }
  }

  // Complete a job
  Future<void> completeJob(String jobId) async {
    try {
      await _firestore.collection(_driverJobsCollection).doc(jobId).update({
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Also update the corresponding booking
      final jobDoc = await _firestore.collection(_driverJobsCollection).doc(jobId).get();
      final bookingId = jobDoc.data()?['booking_id'];
      
      if (bookingId != null) {
        await _firestore.collection(_bookingsCollection).doc(bookingId.toString()).update({
          'driver_job_status': 'completed',
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error completing job: $e');
      throw Exception('Failed to complete job: $e');
    }
  }

  // ==================== DRIVER EARNINGS ====================
  
  // Fetch driver earnings
  Future<List<DriverEarning>> fetchEarnings(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_driverJobsCollection)
          .where('driver_id', isEqualTo: driverId)
          .where('status', whereIn: ['completed', 'scheduled'])
          .orderBy('pickup_time', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final isCompleted = data['status'] == 'completed';
        
        return DriverEarning(
          earningId: int.tryParse(doc.id) ?? 0,
          driverId: int.tryParse(driverId) ?? 0,
          jobId: int.tryParse(data['booking_id']?.toString() ?? '0') ?? 0,
          amount: (data['payment'] ?? 0.0).toDouble(),
          description: '${data['pickup_location']} to ${data['dropoff_location']}',
          status: isCompleted ? 'paid' : 'pending',
          date: (data['pickup_time'] as Timestamp).toDate(),
          paidAt: isCompleted && data['completed_at'] != null
              ? (data['completed_at'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error fetching earnings: $e');
      return [];
    }
  }

  // ==================== HELPER METHODS ====================
  
  int _calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  // Stream driver stats for real-time updates
  Stream<Map<String, dynamic>> streamDriverStats(String driverId) {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      return await fetchDriverStats(driverId);
    });
  }

  // Stream pending requests for real-time updates
  Stream<List<RideRequest>> streamPendingRequests(String driverId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('need_driver', isEqualTo: true)
        .where('driver_request_status', isEqualTo: 'pending')
        .where('booking_status', isEqualTo: 'confirmed')
        .orderBy('created_at', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // ✅ CRITICAL FIX: This was probably still using int.tryParse!
        return RideRequest(
          requestId: '', // ✅ Empty string (not 0!)
          driverId: driverId, // ✅ String
          bookingId: doc.id, // ✅ CRITICAL: Firestore document ID as String
          customerName: data['user_name'] ?? '',
          customerPhone: data['user_phone'] ?? '',
          vehicleName: data['vehicle_name'] ?? '',
          pickupLocation: data['pickup_location'] ?? 'Location not specified',
          pickupTime: (data['start_date'] as Timestamp).toDate(),
          status: data['driver_request_status'] ?? 'pending',
          createdAt: (data['created_at'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  // Get driver profile data
  Future<Map<String, dynamic>?> getDriverProfile(String driverId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(driverId).get();
      
      if (!doc.exists) return null;
      
      return doc.data();
    } catch (e) {
      print('Error fetching driver profile: $e');
      return null;
    }
  }

  // Update driver profile
  Future<void> updateDriverProfile({
    required String driverId,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(driverId).update({
        'name': name,
        'phone': phone,
        'address': address,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating driver profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
}