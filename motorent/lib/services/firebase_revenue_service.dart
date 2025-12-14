// FILE: motorent/lib/services/firebase_revenue_service.dart
// CREATE THIS NEW FILE

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseRevenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _revenueCollection = 'vehicle_revenue';
  final String _bookingsCollection = 'bookings';

  // Calculate and store monthly revenue for a vehicle
  Future<Map<String, dynamic>> calculateMonthlyRevenue({
    required String vehicleId,
    required String ownerId,
    required int month,
    required int year,
    required double monthlyPayment, // Vehicle installment/lease payment
  }) async {
    try {
      // Fetch all completed bookings for this vehicle in the specified month
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final bookingsSnapshot = await _firestore
          .collection(_bookingsCollection)
          .where('vehicle_id', isEqualTo: vehicleId)
          .where('booking_status', isEqualTo: 'completed')
          .where('completion_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('completion_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Calculate revenue metrics
      double totalRevenue = 0;
      int bookingsCount = 0;
      int daysBooked = 0;

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['total_price'] as num).toDouble();
        bookingsCount++;
        
        // Calculate days between start and end date
        final start = (data['start_date'] as Timestamp).toDate();
        final end = (data['end_date'] as Timestamp).toDate();
        daysBooked += end.difference(start).inDays + 1;
      }

      // Calculate metrics
      final averageBookingValue = bookingsCount > 0 ? totalRevenue / bookingsCount : 0.0;
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final utilizationRate = daysBooked / daysInMonth;

      // Create or update revenue record
      final revenueData = {
        'vehicle_id': vehicleId,
        'owner_id': ownerId,
        'month': month,
        'year': year,
        'monthly_revenue': totalRevenue,
        'monthly_payment': monthlyPayment,
        'bookings_count': bookingsCount,
        'average_booking_value': averageBookingValue,
        'utilization_rate': utilizationRate,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Check if record exists
      final existingQuery = await _firestore
          .collection(_revenueCollection)
          .where('vehicle_id', isEqualTo: vehicleId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Update existing record
        await _firestore
            .collection(_revenueCollection)
            .doc(existingQuery.docs.first.id)
            .update(revenueData);
      } else {
        // Create new record
        revenueData['created_at'] = FieldValue.serverTimestamp();
        await _firestore.collection(_revenueCollection).add(revenueData);
      }

      return {
        'success': true,
        'revenue': totalRevenue,
        'bookings': bookingsCount,
        'utilization': utilizationRate,
      };
    } catch (e) {
      print('Error calculating monthly revenue: $e');
      return {
        'success': false,
        'message': 'Failed to calculate revenue: $e',
      };
    }
  }

  // Fetch revenue data for owner's vehicles
  Future<List<VehicleRevenueData>> fetchOwnerRevenue({
    required String ownerId,
    int? month,
    int? year,
  }) async {
    try {
      // Use current month/year if not specified
      final now = DateTime.now();
      final targetMonth = month ?? now.month;
      final targetYear = year ?? now.year;

      final querySnapshot = await _firestore
          .collection(_revenueCollection)
          .where('owner_id', isEqualTo: ownerId)
          .where('month', isEqualTo: targetMonth)
          .where('year', isEqualTo: targetYear)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['revenue_id'] = doc.id;
        return VehicleRevenueData.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching owner revenue: $e');
      throw Exception('Failed to load revenue data: $e');
    }
  }

  // Fetch revenue history for a specific vehicle
  Future<List<VehicleRevenueData>> fetchVehicleRevenueHistory({
    required String vehicleId,
    int months = 6,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - months, 1);

      final querySnapshot = await _firestore
          .collection(_revenueCollection)
          .where('vehicle_id', isEqualTo: vehicleId)
          .where('year', isGreaterThanOrEqualTo: startDate.year)
          .orderBy('year', descending: true)
          .orderBy('month', descending: true)
          .limit(months)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['revenue_id'] = doc.id;
        return VehicleRevenueData.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching vehicle revenue history: $e');
      throw Exception('Failed to load revenue history: $e');
    }
  }

  // Get aggregate revenue statistics for owner
  Future<Map<String, dynamic>> getOwnerRevenueStats({
    required String ownerId,
    int? month,
    int? year,
  }) async {
    try {
      final revenueData = await fetchOwnerRevenue(
        ownerId: ownerId,
        month: month,
        year: year,
      );

      double totalRevenue = 0;
      double totalPayment = 0;
      int totalBookings = 0;
      int profitableVehicles = 0;
      int losingVehicles = 0;

      for (var revenue in revenueData) {
        totalRevenue += revenue.monthlyRevenue;
        totalPayment += revenue.monthlyPayment;
        totalBookings += revenue.bookingsCount;

        if (revenue.monthlyRevenue > revenue.monthlyPayment) {
          profitableVehicles++;
        } else {
          losingVehicles++;
        }
      }

      final netProfit = totalRevenue - totalPayment;
      final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0.0;

      return {
        'total_revenue': totalRevenue,
        'total_payment': totalPayment,
        'net_profit': netProfit,
        'profit_margin': profitMargin,
        'total_bookings': totalBookings,
        'profitable_vehicles': profitableVehicles,
        'losing_vehicles': losingVehicles,
        'total_vehicles': revenueData.length,
      };
    } catch (e) {
      print('Error getting owner revenue stats: $e');
      return {
        'total_revenue': 0.0,
        'total_payment': 0.0,
        'net_profit': 0.0,
        'profit_margin': 0.0,
        'total_bookings': 0,
        'profitable_vehicles': 0,
        'losing_vehicles': 0,
        'total_vehicles': 0,
      };
    }
  }

  // Update monthly payment for a vehicle
  Future<bool> updateMonthlyPayment({
    required String vehicleId,
    required int month,
    required int year,
    required double newPayment,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_revenueCollection)
          .where('vehicle_id', isEqualTo: vehicleId)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      await _firestore
          .collection(_revenueCollection)
          .doc(querySnapshot.docs.first.id)
          .update({
        'monthly_payment': newPayment,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating monthly payment: $e');
      return false;
    }
  }

  // Generate revenue trend data (for charts)
  Future<List<Map<String, dynamic>>> getRevenueTrend({
    required String ownerId,
    int months = 6,
  }) async {
    try {
      final now = DateTime.now();
      List<Map<String, dynamic>> trend = [];

      for (int i = months - 1; i >= 0; i--) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final month = targetDate.month;
        final year = targetDate.year;

        final stats = await getOwnerRevenueStats(
          ownerId: ownerId,
          month: month,
          year: year,
        );

        trend.add({
          'month': month,
          'year': year,
          'month_name': _getMonthName(month),
          'revenue': stats['total_revenue'],
          'profit': stats['net_profit'],
        });
      }

      return trend;
    } catch (e) {
      print('Error generating revenue trend: $e');
      return [];
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

// Vehicle Revenue Data Model
class VehicleRevenueData {
  final String revenueId;
  final String vehicleId;
  final String ownerId;
  final int month;
  final int year;
  final double monthlyRevenue;
  final double monthlyPayment;
  final int bookingsCount;
  final double averageBookingValue;
  final double utilizationRate;

  VehicleRevenueData({
    required this.revenueId,
    required this.vehicleId,
    required this.ownerId,
    required this.month,
    required this.year,
    required this.monthlyRevenue,
    required this.monthlyPayment,
    required this.bookingsCount,
    required this.averageBookingValue,
    required this.utilizationRate,
  });

  factory VehicleRevenueData.fromJson(Map<String, dynamic> json) {
    return VehicleRevenueData(
      revenueId: json['revenue_id'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
      monthlyPayment: (json['monthly_payment'] ?? 0).toDouble(),
      bookingsCount: json['bookings_count'] ?? 0,
      averageBookingValue: (json['average_booking_value'] ?? 0).toDouble(),
      utilizationRate: (json['utilization_rate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revenue_id': revenueId,
      'vehicle_id': vehicleId,
      'owner_id': ownerId,
      'month': month,
      'year': year,
      'monthly_revenue': monthlyRevenue,
      'monthly_payment': monthlyPayment,
      'bookings_count': bookingsCount,
      'average_booking_value': averageBookingValue,
      'utilization_rate': utilizationRate,
    };
  }

  double get profitLoss => monthlyRevenue - monthlyPayment;
  bool get isProfit => profitLoss > 0;
}