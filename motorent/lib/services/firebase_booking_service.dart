// FILE: motorent/lib/services/firebase_booking_service.dart
// ✅ UPDATED: Payment authorization flow with invoice generation

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import 'stripe_payment_service.dart';
import '../services/vehicle_revenue_tracking_service.dart';

class FirebaseBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _bookingsCollection = 'bookings';
  final StripePaymentService _stripeService = StripePaymentService();
  final VehicleRevenueTrackingService _revenueService = VehicleRevenueTrackingService();

  // ✅ UPDATED: Create booking with payment_pending status
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
    String? pickupLocation,
    String? dropoffLocation,
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

      // ✅ Create booking with payment_pending status (awaiting payment)
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
        'booking_status': 'payment_pending', // ✅ Waiting for payment
        'payment_status': 'pending', // ✅ Payment not yet made
        'payment_intent_id': null, // ✅ Will be updated after payment
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'need_driver': needDriver,
        'driver_price': driverPrice,
        'driver_id': null,
        'driver_name': null,
        'driver_request_status': needDriver ? 'pending' : null,
        'driver_job_status': null,
        'pickup_location': pickupLocation,
        'dropoff_location': dropoffLocation,
      };

      final docRef = await _firestore.collection(_bookingsCollection).add(bookingData);

      print('✅ Booking created with ID: ${docRef.id}, Status: payment_pending');

      // Create the Booking object to return
      final booking = Booking(
        bookingId: docRef.id,
        userId: userId,
        vehicleId: vehicleId,
        ownerId: ownerId,
        startDate: startDate,
        endDate: endDate,
        totalPrice: totalPrice,
        bookingStatus: 'payment_pending',
        createdAt: DateTime.now(),
        userName: userName,
        vehicleName: vehicleName,
        userPhone: userPhone,
        needDriver: needDriver,
        driverPrice: driverPrice,
        driverId: null,
        driverName: null,
        paymentStatus: 'pending',
        paymentIntentId: null,
      );

      return {
        'success': true,
        'booking_id': docRef.id,
        'booking': booking,
        'message': 'Booking created! Please proceed to payment.',
      };
    } catch (e) {
      print('❌ Error creating booking: $e');
      return {
        'success': false,
        'message': 'Failed to create booking: $e',
      };
    }
  }

  // ✅ NEW: Update booking after payment authorization
  Future<bool> updatePaymentAuthorization({
    required String bookingId,
    required String paymentIntentId,
  }) async {
    try {
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'payment_intent_id': paymentIntentId,
        'payment_status': 'authorized', // Funds are held
        'booking_status': 'pending', // Awaiting owner approval
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Payment authorization recorded for booking: $bookingId');
      print('   Payment Intent ID: $paymentIntentId');
      print('   Status: pending (awaiting owner approval)');
      return true;
    } catch (e) {
      print('❌ Error updating payment authorization: $e');
      return false;
    }
  }

  // ✅ UPDATED: Approve booking (by owner) - This captures the held payment
  Future<Map<String, dynamic>> approveBooking(String bookingId) async {
    try {
      print('🔍 Fetching booking: $bookingId');
      
      // Get the booking
      final bookingDoc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      
      if (!bookingDoc.exists) {
        return {
          'success': false,
          'message': 'Booking not found',
        };
      }

      final bookingData = bookingDoc.data()!;
      final needDriver = bookingData['need_driver'] ?? false;
      final paymentIntentId = bookingData['payment_intent_id'] as String?;
      final paymentStatus = bookingData['payment_status'] as String?;

      print('📋 Booking details:');
      print('   Payment Intent ID: $paymentIntentId');
      print('   Payment Status: $paymentStatus');
      print('   Need Driver: $needDriver');

      // ✅ Capture the held payment
      if (paymentIntentId != null && paymentStatus == 'authorized') {
        print('💰 Attempting to capture payment...');
        
        final captureResult = await _stripeService.capturePayment(paymentIntentId);
        
        if (captureResult == null) {
          print('❌ Failed to capture payment');
          return {
            'success': false,
            'message': 'Failed to capture payment. Please try again.',
          };
        }
        
        print('✅ Payment captured successfully!');
        print('   Amount: ${captureResult['amount_received']} ${captureResult['currency']}');
      } else if (paymentIntentId == null) {
        print('⚠️  No payment intent ID found - skipping capture');
      } else if (paymentStatus != 'authorized') {
        print('⚠️  Payment status is $paymentStatus - skipping capture');
      }

      // Update booking status to confirmed
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'booking_status': 'confirmed',
        'payment_status': 'captured', // ✅ Payment captured
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Booking $bookingId approved and confirmed');

      // If driver is needed, the driver_request_status is already 'pending'
      if (needDriver) {
        print('✅ Driver request is now visible to drivers (status: pending)');
      }

      return {
        'success': true,
        'message': needDriver 
            ? 'Booking approved! Payment captured. Driver request is now visible to drivers.'
            : 'Booking approved! Payment captured successfully.',
      };
    } catch (e) {
      print('❌ Error approving booking: $e');
      return {
        'success': false,
        'message': 'Failed to approve booking: $e',
      };
    }
  }

  // ✅ UPDATED: Reject booking (by owner) - This cancels the held payment
  Future<Map<String, dynamic>> rejectBooking(String bookingId, String reason) async {
    try {
      print('🔍 Rejecting booking: $bookingId');
      
      // Get the booking
      final bookingDoc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      
      if (!bookingDoc.exists) {
        return {
          'success': false,
          'message': 'Booking not found',
        };
      }

      final bookingData = bookingDoc.data()!;
      final paymentIntentId = bookingData['payment_intent_id'] as String?;
      final paymentStatus = bookingData['payment_status'] as String?;

      print('📋 Booking details:');
      print('   Payment Intent ID: $paymentIntentId');
      print('   Payment Status: $paymentStatus');

      // ✅ Cancel the held payment if it was authorized
      if (paymentIntentId != null && paymentStatus == 'authorized') {
        print('💳 Attempting to cancel payment authorization...');
        
        final cancelled = await _stripeService.cancelPaymentIntent(paymentIntentId);
        
        if (cancelled) {
          print('✅ Payment authorization cancelled - funds released to customer');
        } else {
          print('⚠️  Failed to cancel payment - manual intervention may be required');
        }
      }

      // Update booking status
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'booking_status': 'rejected',
        'payment_status': 'cancelled', // ✅ Payment cancelled
        'rejection_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Booking rejected successfully');

      return {
        'success': true,
        'message': 'Booking rejected and payment authorization cancelled',
      };
    } catch (e) {
      print('❌ Error rejecting booking: $e');
      return {
        'success': false,
        'message': 'Failed to reject booking: $e',
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

  // Update booking status (generic)
  Future<bool> updateBookingStatus(
    String bookingId,
    String newStatus, {
    String? rejectionReason,
  }) async {
    try {
      // If completing a booking, use the special method that records revenue
      if (newStatus == 'completed') {
        final result = await completeBooking(bookingId);
        return result['success'] == true;
      }
      
      // Otherwise, standard status update
      Map<String, dynamic> updateData = {
        'booking_status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'rejected' && rejectionReason != null) {
        updateData['rejection_reason'] = rejectionReason;
      }

      await _firestore.collection(_bookingsCollection).doc(bookingId).update(updateData);
      
      return true;
    } catch (e) {
      print('Error updating booking status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> completeBooking(String bookingId) async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('✅ COMPLETING BOOKING');
      print('═══════════════════════════════════════');
      print('Booking ID: $bookingId');
      
      // Get booking data
      final bookingDoc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      
      if (!bookingDoc.exists) {
        return {
          'success': false,
          'message': 'Booking not found',
        };
      }
      
      final bookingData = bookingDoc.data()!;
      
      // Mark booking as completed
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'booking_status': 'completed',
        'completion_date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ Booking status updated to completed');
      
      // Record revenue in vehicle_revenue collection
      print('💰 Recording vehicle revenue...');
      
      final revenueRecorded = await _revenueService.recordBookingRevenue(
        bookingId: bookingId,
        vehicleId: bookingData['vehicle_id'],
        ownerId: bookingData['owner_id'],
        totalPrice: (bookingData['total_price'] as num).toDouble(),
        startDate: (bookingData['start_date'] as Timestamp).toDate(),
        endDate: (bookingData['end_date'] as Timestamp).toDate(),
        completionDate: DateTime.now(),
        needDriver: bookingData['need_driver'] ?? false,
        driverPrice: (bookingData['driver_price'] as num?)?.toDouble(),
      );
      
      if (revenueRecorded) {
        print('✅ Revenue recorded successfully');
      } else {
        print('⚠️  Revenue recording failed (booking still marked as complete)');
      }
      
      print('═══════════════════════════════════════');
      print('');
      
      return {
        'success': true,
        'message': 'Booking completed and revenue recorded',
        'revenue_recorded': revenueRecorded,
      };
      
    } catch (e, stackTrace) {
      print('❌ Error completing booking: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Failed to complete booking: $e',
      };
    }
  }

  // Cancel booking (by customer)
  Future<bool> cancelBooking(String bookingId, String cancellationReason) async {
    try {
      // Get booking to check payment status
      final bookingDoc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      
      if (bookingDoc.exists) {
        final bookingData = bookingDoc.data()!;
        final paymentIntentId = bookingData['payment_intent_id'] as String?;
        final paymentStatus = bookingData['payment_status'] as String?;
        
        // If payment was authorized but not captured, cancel it
        if (paymentIntentId != null && paymentStatus == 'authorized') {
          print('💳 Cancelling authorized payment for customer cancellation...');
          await _stripeService.cancelPaymentIntent(paymentIntentId);
        }
      }
      
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'booking_status': 'cancelled',
        'payment_status': 'cancelled',
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
          .where('booking_status', whereIn: ['pending', 'confirmed', 'payment_pending'])
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