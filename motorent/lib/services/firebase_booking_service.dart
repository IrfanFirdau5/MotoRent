// FILE: motorent/lib/services/firebase_booking_service.dart
// CREATE THIS NEW FILE

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class FirebaseBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _bookingsCollection = 'bookings';

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String userName,
    required String userPhone,
    required String userEmail,
    required String vehicleId,
    required String vehicleName,
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    bool needDriver = false,
    double? driverPrice,
    String? driverId,
    String? driverName,
  }) async {
    try {
      // Check vehicle availability for the dates
      final isAvailable = await checkAvailability(
        vehicleId: vehicleId,
        startDate: startDate,
        endDate: endDate,
      );

      if (!isAvailable) {
        return {
          'success': false,
          'message': 'Vehicle is not available for the selected dates',
        };
      }

      // Create booking document
      final bookingData = {
        'user_id': userId,
        'user_name': userName,
        'user_phone': userPhone,
        'user_email': userEmail,
        'vehicle_id': vehicleId,
        'vehicle_name': vehicleName,
        'owner_id': ownerId,
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'total_price': totalPrice,
        'booking_status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'need_driver': needDriver,
        'driver_price': driverPrice,
        'driver_id': driverId,
        'driver_name': driverName,
      };

      final docRef = await _firestore.collection(_bookingsCollection).add(bookingData);

      return {
        'success': true,
        'booking_id': docRef.id,
        'message': 'Booking created successfully!',
      };
    } catch (e) {
      print('Error creating booking: $e');
      return {
        'success': false,
        'message': 'Failed to create booking: $e',
      };
    }
  }

  // Fetch owner's bookings (all bookings for their vehicles)
  Future<List<Booking>> fetchOwnerBookings(String ownerId, {String? status}) async {
    try {
      Query query = _firestore
          .collection(_bookingsCollection)
          .where('owner_id', isEqualTo: ownerId);

      if (status != null && status != 'all') {
        query = query.where('booking_status', isEqualTo: status);
      }

      final querySnapshot = await query.orderBy('created_at', descending: true).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['booking_id'] = doc.id;
        
        // Handle Timestamp conversions
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        if (data['start_date'] is Timestamp) {
          data['start_date'] = (data['start_date'] as Timestamp).toDate().toIso8601String();
        }
        if (data['end_date'] is Timestamp) {
          data['end_date'] = (data['end_date'] as Timestamp).toDate().toIso8601String();
        }
        
        return Booking.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching owner bookings: $e');
      throw Exception('Failed to load bookings: $e');
    }
  }

  // Fetch user's bookings
  Future<List<Booking>> fetchUserBookings(String userId, {String? status}) async {
    try {
      Query query = _firestore
          .collection(_bookingsCollection)
          .where('user_id', isEqualTo: userId);

      if (status != null && status != 'all') {
        query = query.where('booking_status', isEqualTo: status);
      }

      final querySnapshot = await query.orderBy('created_at', descending: true).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['booking_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        if (data['start_date'] is Timestamp) {
          data['start_date'] = (data['start_date'] as Timestamp).toDate().toIso8601String();
        }
        if (data['end_date'] is Timestamp) {
          data['end_date'] = (data['end_date'] as Timestamp).toDate().toIso8601String();
        }
        
        return Booking.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching user bookings: $e');
      throw Exception('Failed to load bookings: $e');
    }
  }

  // Update booking status (approve/reject by owner)
  Future<bool> updateBookingStatus(
    String bookingId,
    String newStatus, {
    String? rejectionReason,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'booking_status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'rejected' && rejectionReason != null) {
        updateData['cancellation_reason'] = rejectionReason;
      }

      if (newStatus == 'completed') {
        updateData['completion_date'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_bookingsCollection).doc(bookingId).update(updateData);
      
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  // Cancel booking (by customer)
  Future<bool> cancelBooking(String bookingId, String cancellationReason) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'booking_status': 'cancelled',
        'cancellation_reason': cancellationReason,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  // Check vehicle availability for dates
  Future<bool> checkAvailability({
    required String vehicleId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Query for overlapping bookings that are not cancelled or rejected
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('vehicle_id', isEqualTo: vehicleId)
          .where('booking_status', whereIn: ['pending', 'confirmed'])
          .get();

      // Check for date overlaps
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final bookingStart = (data['start_date'] as Timestamp).toDate();
        final bookingEnd = (data['end_date'] as Timestamp).toDate();

        // Check if dates overlap
        if (startDate.isBefore(bookingEnd) && endDate.isAfter(bookingStart)) {
          return false; // Dates overlap, not available
        }
      }

      return true; // No overlaps, available
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  // Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['booking_id'] = doc.id;
      
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
      }
      if (data['start_date'] is Timestamp) {
        data['start_date'] = (data['start_date'] as Timestamp).toDate().toIso8601String();
      }
      if (data['end_date'] is Timestamp) {
        data['end_date'] = (data['end_date'] as Timestamp).toDate().toIso8601String();
      }
      
      return Booking.fromJson(data);
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  // Stream owner's bookings for real-time updates
  Stream<List<Booking>> streamOwnerBookings(String ownerId) {
    return _firestore
        .collection(_bookingsCollection)
        .where('owner_id', isEqualTo: ownerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['booking_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        if (data['start_date'] is Timestamp) {
          data['start_date'] = (data['start_date'] as Timestamp).toDate().toIso8601String();
        }
        if (data['end_date'] is Timestamp) {
          data['end_date'] = (data['end_date'] as Timestamp).toDate().toIso8601String();
        }
        
        return Booking.fromJson(data);
      }).toList();
    });
  }

  // Get booking statistics for owner
  Future<Map<String, dynamic>> getOwnerBookingStats(String ownerId) async {
    try {
      final allBookings = await fetchOwnerBookings(ownerId);
      
      int pending = 0;
      int confirmed = 0;
      int completed = 0;
      int cancelled = 0;
      double totalRevenue = 0;

      for (var booking in allBookings) {
        switch (booking.bookingStatus.toLowerCase()) {
          case 'pending':
            pending++;
            break;
          case 'confirmed':
            confirmed++;
            break;
          case 'completed':
            completed++;
            totalRevenue += booking.totalPrice;
            break;
          case 'cancelled':
          case 'rejected':
            cancelled++;
            break;
        }
      }

      return {
        'total_bookings': allBookings.length,
        'pending': pending,
        'confirmed': confirmed,
        'completed': completed,
        'cancelled': cancelled,
        'total_revenue': totalRevenue,
        'active_bookings': confirmed,
      };
    } catch (e) {
      print('Error getting booking stats: $e');
      return {
        'total_bookings': 0,
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
        'total_revenue': 0.0,
        'active_bookings': 0,
      };
    }
  }

  // Get recent bookings for owner
  Future<List<Booking>> getRecentOwnerBookings(String ownerId, {int limit = 5}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('owner_id', isEqualTo: ownerId)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['booking_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp).toDate().toIso8601String();
        }
        if (data['start_date'] is Timestamp) {
          data['start_date'] = (data['start_date'] as Timestamp).toDate().toIso8601String();
        }
        if (data['end_date'] is Timestamp) {
          data['end_date'] = (data['end_date'] as Timestamp).toDate().toIso8601String();
        }
        
        return Booking.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting recent bookings: $e');
      return [];
    }
  }
}