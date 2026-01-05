// FILE: motorent/lib/services/vehicle_revenue_tracking_service.dart
// ✅ NEW SERVICE - Automatically tracks vehicle revenue when bookings are completed

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VehicleRevenueTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Record revenue when a booking is completed
  /// Call this method when owner marks booking as complete
  Future<bool> recordBookingRevenue({
    required String bookingId,
    required String vehicleId,
    required String ownerId,
    required double totalPrice,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime completionDate,
    bool needDriver = false,
    double? driverPrice,
  }) async {
    try {
      
      // Calculate vehicle revenue (exclude driver fee)
      double vehicleRevenue = totalPrice;
      if (needDriver && driverPrice != null) {
        vehicleRevenue = totalPrice - driverPrice;
      }
      
      
      // Calculate rental duration
      int rentalDays = endDate.difference(startDate).inDays + 1;
      
      // Get the month and year of completion
      final month = completionDate.month;
      final year = completionDate.year;
      final monthKey = '${year}_${month.toString().padLeft(2, '0')}'; // e.g., "2024_12"
      
      
      // Get or fetch vehicle data
      final vehicleDoc = await _firestore.collection('vehicles').doc(vehicleId).get();
      
      if (!vehicleDoc.exists) {
        return false;
      }
      
      final vehicleData = vehicleDoc.data()!;
      final vehicleName = '${vehicleData['brand']} ${vehicleData['model']}';
      final licensePlate = vehicleData['license_plate'] ?? '';
      final monthlyMaintenance = (vehicleData['monthly_maintenance'] as num?)?.toDouble() ?? 0.0;
      final monthlyPayment = (vehicleData['monthly_payment'] as num?)?.toDouble() ?? 0.0;
      final totalMonthlyPayment = monthlyMaintenance + monthlyPayment;
      
      
      // Check if revenue record exists for this vehicle and month
      final revenueDocId = '${vehicleId}_$monthKey';
      final revenueDocRef = _firestore.collection('vehicle_revenue').doc(revenueDocId);
      final revenueDoc = await revenueDocRef.get();
      
      if (revenueDoc.exists) {
        // Update existing record
        
        final existingData = revenueDoc.data()!;
        final currentRevenue = (existingData['total_revenue'] as num?)?.toDouble() ?? 0.0;
        final currentBookings = (existingData['total_bookings'] as int?) ?? 0;
        final currentDaysBooked = (existingData['total_days_booked'] as int?) ?? 0;
        
        final newRevenue = currentRevenue + vehicleRevenue;
        final newBookings = currentBookings + 1;
        final newDaysBooked = currentDaysBooked + rentalDays;
        
        // Calculate utilization rate
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final utilizationRate = newDaysBooked / daysInMonth;
        
        // Calculate average booking value
        final averageBookingValue = newRevenue / newBookings;
        
        await revenueDocRef.update({
          'total_revenue': newRevenue,
          'total_bookings': newBookings,
          'total_days_booked': newDaysBooked,
          'average_booking_value': averageBookingValue,
          'utilization_rate': utilizationRate,
          'updated_at': FieldValue.serverTimestamp(),
        });
        
        
      } else {
        // Create new record
        
        // Calculate metrics
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final utilizationRate = rentalDays / daysInMonth;
        
        final revenueData = {
          'vehicle_id': vehicleId,
          'owner_id': ownerId,
          'vehicle_name': vehicleName,
          'license_plate': licensePlate,
          'month': month,
          'year': year,
          'month_key': monthKey,
          'month_name': DateFormat('MMMM yyyy').format(completionDate),
          
          // Revenue data
          'total_revenue': vehicleRevenue,
          'monthly_maintenance': monthlyMaintenance,
          'monthly_payment': monthlyPayment,
          'total_monthly_payment': totalMonthlyPayment,
          
          // Booking data
          'total_bookings': 1,
          'total_days_booked': rentalDays,
          'average_booking_value': vehicleRevenue,
          'utilization_rate': utilizationRate,
          
          // Calculated fields
          'profit_loss': vehicleRevenue - totalMonthlyPayment,
          'is_profitable': vehicleRevenue > totalMonthlyPayment,
          
          // Timestamps
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };
        
        await revenueDocRef.set(revenueData);
        
      }
      
      // Also update the booking document with revenue tracking flag
      await _firestore.collection('bookings').doc(bookingId).update({
        'revenue_recorded': true,
        'revenue_recorded_at': FieldValue.serverTimestamp(),
      });
      
      
      return true;
      
    } catch (e, stackTrace) {
      return false;
    }
  }
  
  /// Get revenue data for a specific vehicle and month
  Future<Map<String, dynamic>?> getVehicleRevenueForMonth({
    required String vehicleId,
    required int month,
    required int year,
  }) async {
    try {
      final monthKey = '${year}_${month.toString().padLeft(2, '0')}';
      final revenueDocId = '${vehicleId}_$monthKey';
      
      final doc = await _firestore.collection('vehicle_revenue').doc(revenueDocId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['revenue_id'] = doc.id;
        return data;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Get all revenue records for an owner (for current month)
  Future<List<Map<String, dynamic>>> getOwnerRevenueForMonth({
    required String ownerId,
    int? month,
    int? year,
  }) async {
    try {
      final now = DateTime.now();
      final targetMonth = month ?? now.month;
      final targetYear = year ?? now.year;
      
      final querySnapshot = await _firestore
          .collection('vehicle_revenue')
          .where('owner_id', isEqualTo: ownerId)
          .where('month', isEqualTo: targetMonth)
          .where('year', isEqualTo: targetYear)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['revenue_id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      return [];
    }
  }
  
  /// Recalculate revenue for a specific vehicle and month
  /// Useful for correcting data or backfilling
  Future<bool> recalculateVehicleRevenue({
    required String vehicleId,
    required String ownerId,
    required int month,
    required int year,
  }) async {
    try {
      
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      
      // Get all completed bookings for this vehicle in this month
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('vehicle_id', isEqualTo: vehicleId)
          .where('booking_status', isEqualTo: 'completed')
          .where('completion_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('completion_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      if (bookingsSnapshot.docs.isEmpty) {
        return false;
      }
      
      // Get vehicle data
      final vehicleDoc = await _firestore.collection('vehicles').doc(vehicleId).get();
      if (!vehicleDoc.exists) {
        return false;
      }
      
      final vehicleData = vehicleDoc.data()!;
      final vehicleName = '${vehicleData['brand']} ${vehicleData['model']}';
      final licensePlate = vehicleData['license_plate'] ?? '';
      final monthlyMaintenance = (vehicleData['monthly_maintenance'] as num?)?.toDouble() ?? 0.0;
      final monthlyPayment = (vehicleData['monthly_payment'] as num?)?.toDouble() ?? 0.0;
      final totalMonthlyPayment = monthlyMaintenance + monthlyPayment;
      
      // Calculate totals
      double totalRevenue = 0;
      int totalBookings = 0;
      int totalDaysBooked = 0;
      
      for (var doc in bookingsSnapshot.docs) {
        final bookingData = doc.data();
        
        // Calculate vehicle revenue (exclude driver fee)
        double bookingRevenue = (bookingData['total_price'] as num).toDouble();
        if (bookingData['need_driver'] == true && bookingData['driver_price'] != null) {
          bookingRevenue -= (bookingData['driver_price'] as num).toDouble();
        }
        
        totalRevenue += bookingRevenue;
        totalBookings++;
        
        // Calculate rental days
        final startDate = (bookingData['start_date'] as Timestamp).toDate();
        final endDate = (bookingData['end_date'] as Timestamp).toDate();
        totalDaysBooked += endDate.difference(startDate).inDays + 1;
      }
      
      // Calculate metrics
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final utilizationRate = totalDaysBooked / daysInMonth;
      final averageBookingValue = totalRevenue / totalBookings;
      
      // Update or create revenue record
      final monthKey = '${year}_${month.toString().padLeft(2, '0')}';
      final revenueDocId = '${vehicleId}_$monthKey';
      
      final revenueData = {
        'vehicle_id': vehicleId,
        'owner_id': ownerId,
        'vehicle_name': vehicleName,
        'license_plate': licensePlate,
        'month': month,
        'year': year,
        'month_key': monthKey,
        'month_name': DateFormat('MMMM yyyy').format(DateTime(year, month)),
        'total_revenue': totalRevenue,
        'monthly_maintenance': monthlyMaintenance,
        'monthly_payment': monthlyPayment,
        'total_monthly_payment': totalMonthlyPayment,
        'total_bookings': totalBookings,
        'total_days_booked': totalDaysBooked,
        'average_booking_value': averageBookingValue,
        'utilization_rate': utilizationRate,
        'profit_loss': totalRevenue - totalMonthlyPayment,
        'is_profitable': totalRevenue > totalMonthlyPayment,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('vehicle_revenue').doc(revenueDocId).set(
        revenueData,
        SetOptions(merge: true),
      );
      
      
      return true;
      
    } catch (e) {
      return false;
    }
  }
  
  /// Backfill revenue data for all completed bookings
  /// Use this to populate the vehicle_revenue collection from existing bookings
  Future<Map<String, dynamic>> backfillAllRevenue(String ownerId) async {
    try {
      
      // Get all completed bookings for this owner
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('owner_id', isEqualTo: ownerId)
          .where('booking_status', isEqualTo: 'completed')
          .get();
      
      
      int successCount = 0;
      int errorCount = 0;
      
      for (var doc in bookingsSnapshot.docs) {
        final bookingData = doc.data();
        
        // Skip if already recorded
        if (bookingData['revenue_recorded'] == true) {
          continue;
        }
        
        try {
          final completionDate = bookingData['completion_date'] != null
              ? (bookingData['completion_date'] as Timestamp).toDate()
              : (bookingData['updated_at'] as Timestamp).toDate();
          
          final success = await recordBookingRevenue(
            bookingId: doc.id,
            vehicleId: bookingData['vehicle_id'],
            ownerId: bookingData['owner_id'],
            totalPrice: (bookingData['total_price'] as num).toDouble(),
            startDate: (bookingData['start_date'] as Timestamp).toDate(),
            endDate: (bookingData['end_date'] as Timestamp).toDate(),
            completionDate: completionDate,
            needDriver: bookingData['need_driver'] ?? false,
            driverPrice: (bookingData['driver_price'] as num?)?.toDouble(),
          );
          
          if (success) {
            successCount++;
          } else {
            errorCount++;
          }
          
        } catch (e) {
          errorCount++;
        }
      }
      
      
      return {
        'success': true,
        'processed': successCount + errorCount,
        'successful': successCount,
        'errors': errorCount,
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}