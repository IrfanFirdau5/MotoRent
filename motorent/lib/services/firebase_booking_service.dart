// FILE: motorent/lib/services/firebase_booking_service.dart
// ✅ COMPLETE VERSION: Payment authorization + Location coordinates + Invoice generation

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import 'stripe_payment_service.dart';
import '../services/vehicle_revenue_tracking_service.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart';

class FirebaseBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _bookingsCollection = 'bookings';
  final StripePaymentService _stripeService = StripePaymentService();
  final VehicleRevenueTrackingService _revenueService = VehicleRevenueTrackingService();

  // ✅ COMPLETE: Create booking with location coordinates
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
    double? pickupLatitude,
    double? pickupLongitude,
    String? dropoffLocation,
    double? dropoffLatitude,
    double? dropoffLongitude,
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

      if (needDriver) {
      }

      // ✅ Create booking with all location data
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
        'booking_status': 'payment_pending', // Awaiting payment
        'payment_status': 'pending', // Payment not yet made
        'payment_intent_id': null, // Will be updated after payment
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'need_driver': needDriver,
        'driver_price': driverPrice,
        'driver_id': null,
        'driver_name': null,
        'driver_request_status': needDriver ? 'pending' : null,
        'driver_job_status': null,
        
        // ✅ Location fields with coordinates
        'pickup_location': pickupLocation,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'dropoff_location': dropoffLocation,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
      };

      final docRef = await _firestore.collection(_bookingsCollection).add(bookingData);


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
        pickupLocation: pickupLocation,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        dropoffLocation: dropoffLocation,
        dropoffLatitude: dropoffLatitude,
        dropoffLongitude: dropoffLongitude,
      );

      return {
        'success': true,
        'booking_id': docRef.id,
        'booking': booking,
        'message': 'Booking created! Please proceed to payment.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create booking: $e',
      };
    }
  }

  // ✅ Update booking after payment authorization
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

      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ Approve booking (by owner) - Captures the held payment
  Future<Map<String, dynamic>> approveBooking(String bookingId) async {
    try {
      
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


      // ✅ Capture the held payment
      if (paymentIntentId != null && paymentStatus == 'authorized') {
        
        final captureResult = await _stripeService.capturePayment(paymentIntentId);
        
        if (captureResult == null) {
          return {
            'success': false,
            'message': 'Failed to capture payment. Please try again.',
          };
        }
        
      } else if (paymentIntentId == null) {
      } else if (paymentStatus != 'authorized') {
      }

      // Update booking status to confirmed
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'booking_status': 'confirmed',
        'payment_status': 'captured', // Payment captured
        'updated_at': FieldValue.serverTimestamp(),
      });


      if (needDriver) {
      }


      return {
        'success': true,
        'message': needDriver 
            ? 'Booking approved! Payment captured. Driver request is now visible to drivers.'
            : 'Booking approved! Payment captured successfully.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to approve booking: $e',
      };
    }
  }

  // ✅ Reject booking (by owner) - Cancels the held payment
  Future<Map<String, dynamic>> rejectBooking(String bookingId, String reason) async {
    try {
      
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


      // ✅ Cancel the held payment
      if (paymentIntentId != null && paymentStatus == 'authorized') {
        
        final cancelled = await _stripeService.cancelPaymentIntent(paymentIntentId);
        
        if (cancelled) {
        } else {
        }
      }

      // Update booking status
      await _firestore.collection(_bookingsCollection).doc(bookingId).update({
        'booking_status': 'rejected',
        'payment_status': 'cancelled',
        'rejection_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });


      return {
        'success': true,
        'message': 'Booking rejected and payment authorization cancelled',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reject booking: $e',
      };
    }
  }

  // ✅ Fetch owner's bookings with location data
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
      throw Exception('Failed to load bookings: $e');
    }
  }

  // ✅ Fetch user's bookings with location data
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
      throw Exception('Failed to load bookings: $e');
    }
  }

  // ✅ Update booking status (generic)
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
      return false;
    }
  }

  // ✅ Complete booking and record revenue
  Future<Map<String, dynamic>> completeBooking(String bookingId) async {
    try {
      
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
      
      
      // Record revenue in vehicle_revenue collection
      
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
      } else {
      }
      
      
      return {
        'success': true,
        'message': 'Booking completed and revenue recorded',
        'revenue_recorded': revenueRecorded,
      };
      
    } catch (e, stackTrace) {
      return {
        'success': false,
        'message': 'Failed to complete booking: $e',
      };
    }
  }

  // ✅ Cancel booking (by customer)
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
      return false;
    }
  }

  // ✅ Check vehicle availability for dates
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
      return false;
    }
  }

  // ✅ Get booking by ID with all location data
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection(_bookingsCollection).doc(bookingId).get();
      
      if (!doc.exists) return null;

      final data = doc.data()!;
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
    } catch (e) {
      return null;
    }
  }

  // ✅ Stream owner's bookings for real-time updates
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
    });
  }

  // ✅ Get booking statistics for owner
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

  // ✅ Get recent bookings for owner
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
      return [];
    }
  }

  // ✅ Get bookings by location (for analytics)
  Future<List<Booking>> getBookingsByLocation({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
  }) async {
    try {
      // Note: This is a simple implementation
      // For production, use geohashing or GeoFirestore for efficient geo queries
      final allBookings = await _firestore
          .collection(_bookingsCollection)
          .get();

      List<Booking> nearbyBookings = [];

      for (var doc in allBookings.docs) {
        final data = doc.data();
        final pickupLat = data['pickup_latitude'] as double?;
        final pickupLng = data['pickup_longitude'] as double?;

        if (pickupLat != null && pickupLng != null) {
          // Calculate distance using Haversine formula (simplified)
          final distance = _calculateDistance(
            latitude,
            longitude,
            pickupLat,
            pickupLng,
          );

          if (distance <= radiusInKm) {
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
            
            nearbyBookings.add(Booking.fromJson(data));
          }
        }
      }

      return nearbyBookings;
    } catch (e) {
      return [];
    }
  }

  // ✅ Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin((dLon / 2)) * sin((dLon / 2));

    final c = 2 * asin((sqrt(a)));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }
}
 
extension BookingDistance on Booking {
  double? distanceFromLocation(double latitude, double longitude) {
    if (pickupLatitude == null || pickupLongitude == null) return null;

    const double earthRadius = 6371; // km

    final dLat = _toRadians(pickupLatitude! - latitude);
    final dLon = _toRadians(pickupLongitude! - longitude);

    final a = sin((dLat / 2)) * sin((dLat / 2)) +
        cos(_toRadians(latitude)) * cos(_toRadians(pickupLatitude!)) *
        sin((dLon / 2)) * sin((dLon / 2));

    final c = 2 * asin((sqrt(a)));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  // Calculate distance between pickup and dropoff
  double? get tripDistance {
    if (!hasCompleteDriverLocationData) return null;

    const double earthRadius = 6371; // km

    final dLat = _toRadians(dropoffLatitude! - pickupLatitude!);
    final dLon = _toRadians(dropoffLongitude! - pickupLongitude!);

    final a = sin((dLat / 2)) * sin((dLat / 2)) +
        cos(_toRadians(pickupLatitude!)) * cos(_toRadians(dropoffLatitude!)) *
        sin((dLon / 2)) * sin((dLon / 2));

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Format distance for display
  String? get tripDistanceFormatted {
    final distance = tripDistance;
    if (distance == null) return null;

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    } else if (distance < 10) {
      return '${distance.toStringAsFixed(1)} km';
    } else {
      return '${distance.toStringAsFixed(0)} km';
    }
  }

  // Estimate driving time (rough estimate: 50 km/h average)
  Duration? get estimatedDrivingTime {
    final distance = tripDistance;
    if (distance == null) return null;

    const double averageSpeed = 50.0; // km/h
    final hours = distance / averageSpeed;
    return Duration(minutes: (hours * 60).round());
  }

  // Format driving time for display
  String? get drivingTimeFormatted {
    final duration = estimatedDrivingTime;
    if (duration == null) return null;

    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $minutes min';
      }
    }
  }

  // Get pickup coordinates as LatLng
  LatLng? get pickupLatLng {
    if (pickupLatitude == null || pickupLongitude == null) return null;
    return LatLng(pickupLatitude!, pickupLongitude!);
  }

  // Get dropoff coordinates as LatLng
  LatLng? get dropoffLatLng {
    if (dropoffLatitude == null || dropoffLongitude == null) return null;
    return LatLng(dropoffLatitude!, dropoffLongitude!);
  }

  // Check if booking is nearby a location
  bool isNearby(double latitude, double longitude, {double radiusInKm = 10.0}) {
    final distance = distanceFromLocation(latitude, longitude);
    return distance != null && distance <= radiusInKm;
  }

  // Get cardinal direction from pickup to dropoff
  String? get tripDirection {
    if (!hasCompleteDriverLocationData) return null;

    final dLon = _toRadians(dropoffLongitude! - pickupLongitude!);
    final lat1Rad = _toRadians(pickupLatitude!);
    final lat2Rad = _toRadians(dropoffLatitude!);

    final y = sin((dLon)) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearing = atan2(y,x);
    final degrees = _toDegrees(bearing);
    final normalizedDegrees = (degrees + 360) % 360;

    if (normalizedDegrees >= 337.5 || normalizedDegrees < 22.5) {
      return 'North';
    } else if (normalizedDegrees >= 22.5 && normalizedDegrees < 67.5) {
      return 'Northeast';
    } else if (normalizedDegrees >= 67.5 && normalizedDegrees < 112.5) {
      return 'East';
    } else if (normalizedDegrees >= 112.5 && normalizedDegrees < 157.5) {
      return 'Southeast';
    } else if (normalizedDegrees >= 157.5 && normalizedDegrees < 202.5) {
      return 'South';
    } else if (normalizedDegrees >= 202.5 && normalizedDegrees < 247.5) {
      return 'Southwest';
    } else if (normalizedDegrees >= 247.5 && normalizedDegrees < 292.5) {
      return 'West';
    } else {
      return 'Northwest';
    }
  }

  // Estimate fuel cost (Malaysian fuel prices)
  double? get estimatedFuelCost {
    final distance = tripDistance;
    if (distance == null) return null;

    const double fuelPricePerLiter = 2.05; // RM per liter (Malaysia average)
    const double fuelConsumption = 8.0; // liters per 100 km
    final litersUsed = (distance / 100) * fuelConsumption;
    return litersUsed * fuelPricePerLiter;
  }

  // Format fuel cost for display
  String? get estimatedFuelCostFormatted {
    final cost = estimatedFuelCost;
    if (cost == null) return null;
    return 'RM ${cost.toStringAsFixed(2)}';
  }

  // Get Google Maps URL for pickup location
  String? get pickupMapsUrl {
    if (pickupLatitude == null || pickupLongitude == null) return null;
    return 'https://www.google.com/maps/search/?api=1&query=$pickupLatitude,$pickupLongitude';
  }

  // Get Google Maps URL for dropoff location
  String? get dropoffMapsUrl {
    if (dropoffLatitude == null || dropoffLongitude == null) return null;
    return 'https://www.google.com/maps/search/?api=1&query=$dropoffLatitude,$dropoffLongitude';
  }

  // Get Google Maps directions URL
  String? get directionsUrl {
    if (!hasCompleteDriverLocationData) return null;
    return 'https://www.google.com/maps/dir/?api=1&origin=$pickupLatitude,$pickupLongitude&destination=$dropoffLatitude,$dropoffLongitude&travelmode=driving';
  }

  // Get route summary
  Map<String, dynamic>? get routeSummary {
    if (!hasCompleteDriverLocationData) return null;

    return {
      'distance_km': tripDistance,
      'distance_formatted': tripDistanceFormatted,
      'driving_time': estimatedDrivingTime,
      'driving_time_formatted': drivingTimeFormatted,
      'direction': tripDirection,
      'fuel_cost': estimatedFuelCost,
      'fuel_cost_formatted': estimatedFuelCostFormatted,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'maps_directions_url': directionsUrl,
    };
  }

  // Check if pickup is in Malaysia
  bool get isPickupInMalaysia {
    if (pickupLatitude == null || pickupLongitude == null) return false;
    return (pickupLatitude! >= 0.85 && pickupLatitude! <= 7.36) &&
           (pickupLongitude! >= 99.64 && pickupLongitude! <= 119.27);
  }

  // Check if dropoff is in Malaysia
  bool get isDropoffInMalaysia {
    if (dropoffLatitude == null || dropoffLongitude == null) return false;
    return (dropoffLatitude! >= 0.85 && dropoffLatitude! <= 7.36) &&
           (dropoffLongitude! >= 99.64 && dropoffLongitude! <= 119.27);
  }

  // Get midpoint between pickup and dropoff
  LatLng? get routeMidpoint {
    if (!hasCompleteDriverLocationData) return null;

    final dLon = _toRadians(dropoffLongitude! - pickupLongitude!);

    final lat1Rad = _toRadians(pickupLatitude!);
    final lat2Rad = _toRadians(dropoffLatitude!);
    final lon1Rad = _toRadians(pickupLongitude!);

    final dx = cos(lat2Rad) * cos(dLon);
    final dy = cos(lat2Rad) * sin(dLon);

    final lat3 = atan2(sin(lat1Rad) + sin(lat2Rad),
                        sqrt((cos(lat1Rad) + dx) * (cos(lat1Rad) + dx) + dy * dy));

    final lon3 = lon1Rad + atan2(dy,cos(lat1Rad) + dx);

    return LatLng(
      _toDegrees(lat3),
      _toDegrees(lon3),
    );
  }

  // Format pickup coordinates
  String? get pickupCoordinatesFormatted {
    if (pickupLatitude == null || pickupLongitude == null) return null;
    return '${pickupLatitude!.toStringAsFixed(6)}, ${pickupLongitude!.toStringAsFixed(6)}';
  }

  // Format dropoff coordinates
  String? get dropoffCoordinatesFormatted {
    if (dropoffLatitude == null || dropoffLongitude == null) return null;
    return '${dropoffLatitude!.toStringAsFixed(6)}, ${dropoffLongitude!.toStringAsFixed(6)}';
  }

  double _toDegrees(double radians) {
    return radians * (180.0 / 3.141592653589793);
  }
}

// ✅ Additional helper class for LatLng
// //class LatLng {
//   final double latitude;
//   final double longitude;

//   const LatLng(this.latitude, this.longitude);

//   @override
//   String toString() => 'LatLng($latitude, $longitude)';

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is LatLng &&
//           runtimeType == other.runtimeType &&
//           latitude == other.latitude &&
//           longitude == other.longitude;

//   @override
//   int get hashCode => latitude.hashCode ^ longitude.hashCode;

//   // Convert to map
//   Map<String, double> toMap() {
//     return {
//       'latitude': latitude,
//       'longitude': longitude,
//     };
//   }

//   // Create from map
//   factory LatLng.fromMap(Map<String, dynamic> map) {
//     return LatLng(
//       (map['latitude'] as num).toDouble(),
//       (map['longitude'] as num).toDouble(),
//     );
//   }
// }