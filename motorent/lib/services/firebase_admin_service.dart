// FILE: lib/services/firebase_admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirebaseAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER MANAGEMENT ====================
  
  // Fetch all users with optional filtering
  Future<List<User>> fetchUsers({String? userType}) async {
    try {
      Query query = _firestore.collection('users');
      
      if (userType != null && userType != 'all') {
        query = query.where('user_type', isEqualTo: userType);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['user_id'] = doc.id;
        
        // Handle Timestamp conversions
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        
        return User.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['user_id'] = doc.id;
      
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      
      return User.fromJson(data);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Suspend/Unsuspend user
  Future<bool> toggleUserActiveStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error toggling user status: $e');
      return false;
    }
  }

  // Delete user (soft delete by deactivating)
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'is_active': false,
        'is_deleted': true,
        'deleted_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Update user details
  Future<bool> updateUserDetails({
    required String userId,
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;

      await _firestore.collection('users').doc(userId).update(updateData);
      
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Approve/Reject driver or owner application
  Future<bool> updateUserApprovalStatus(
    String userId,
    String approvalStatus, {
    String? rejectionReason,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'approval_status': approvalStatus, // 'approved', 'rejected', 'pending'
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (approvalStatus == 'approved') {
        updateData['is_active'] = true;
        updateData['approved_at'] = FieldValue.serverTimestamp();
      }

      if (approvalStatus == 'rejected' && rejectionReason != null) {
        updateData['rejection_reason'] = rejectionReason;
        updateData['rejected_at'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('users').doc(userId).update(updateData);
      
      return true;
    } catch (e) {
      print('Error updating approval status: $e');
      return false;
    }
  }

  // Get pending approval users (drivers/owners)
  Future<List<User>> getPendingApprovalUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('approval_status', isEqualTo: 'pending')
          .where('user_type', whereIn: ['driver', 'owner'])
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['user_id'] = doc.id;
        
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        
        return User.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching pending users: $e');
      return [];
    }
  }

  // ==================== DASHBOARD STATISTICS ====================
  
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Fetch all collections counts
      final usersSnapshot = await _firestore.collection('users').get();
      final vehiclesSnapshot = await _firestore
          .collection('vehicles')
          .where('is_deleted', isEqualTo: false)
          .get();
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      final reportsSnapshot = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .get();

      // Calculate revenue this month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final monthlyBookings = await _firestore
          .collection('bookings')
          .where('booking_status', isEqualTo: 'completed')
          .where('completion_date', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('completion_date', 
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double monthlyRevenue = 0;
      for (var doc in monthlyBookings.docs) {
        monthlyRevenue += (doc.data()['total_price'] as num).toDouble();
      }

      // Count active bookings
      final activeBookings = await _firestore
          .collection('bookings')
          .where('booking_status', isEqualTo: 'confirmed')
          .get();

      // Count new users this week
      final weekAgo = now.subtract(const Duration(days: 7));
      final newUsers = await _firestore
          .collection('users')
          .where('created_at', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      return {
        'total_users': usersSnapshot.docs.length,
        'total_vehicles': vehiclesSnapshot.docs.length,
        'total_bookings': bookingsSnapshot.docs.length,
        'pending_reports': reportsSnapshot.docs.length,
        'active_bookings': activeBookings.docs.length,
        'revenue_this_month': monthlyRevenue,
        'new_users_this_week': newUsers.docs.length,
        'booking_growth': 12.5, // Calculate from previous month comparison
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'total_users': 0,
        'total_vehicles': 0,
        'total_bookings': 0,
        'pending_reports': 0,
        'active_bookings': 0,
        'revenue_this_month': 0.0,
        'new_users_this_week': 0,
        'booking_growth': 0.0,
      };
    }
  }

  // ==================== MONTHLY REPORT DATA ====================
  
  Future<Map<String, dynamic>> getMonthlyReportData(
    int month,
    int year,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // Revenue data
      final completedBookings = await _firestore
          .collection('bookings')
          .where('booking_status', isEqualTo: 'completed')
          .where('completion_date', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('completion_date', 
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalRevenue = 0;
      double vehicleRevenue = 0;
      double driverRevenue = 0;

      for (var doc in completedBookings.docs) {
        final data = doc.data();
        final total = (data['total_price'] as num).toDouble();
        totalRevenue += total;
        
        if (data['need_driver'] == true && data['driver_price'] != null) {
          driverRevenue += (data['driver_price'] as num).toDouble();
          vehicleRevenue += (total - (data['driver_price'] as num).toDouble());
        } else {
          vehicleRevenue += total;
        }
      }

      // User statistics
      final newUsers = await _firestore
          .collection('users')
          .where('created_at', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', 
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int newCustomers = 0;
      int newOwners = 0;
      int newDrivers = 0;

      for (var doc in newUsers.docs) {
        final userType = doc.data()['user_type'] as String;
        switch (userType.toLowerCase()) {
          case 'customer':
            newCustomers++;
            break;
          case 'owner':
            newOwners++;
            break;
          case 'driver':
            newDrivers++;
            break;
        }
      }

      // Vehicle statistics
      final newVehicles = await _firestore
          .collection('vehicles')
          .where('created_at', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', 
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Booking statistics
      final allMonthBookings = await _firestore
          .collection('bookings')
          .where('created_at', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', 
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int totalBookings = allMonthBookings.docs.length;
      int completed = 0;
      int cancelled = 0;
      int ongoing = 0;

      for (var doc in allMonthBookings.docs) {
        final status = doc.data()['booking_status'] as String;
        switch (status.toLowerCase()) {
          case 'completed':
            completed++;
            break;
          case 'cancelled':
          case 'rejected':
            cancelled++;
            break;
          case 'confirmed':
            ongoing++;
            break;
        }
      }

      // Reports and issues
      final monthReports = await _firestore
          .collection('reports')
          .where('created_at', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', 
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int totalReports = monthReports.docs.length;
      int resolvedReports = 0;
      int pendingReports = 0;

      for (var doc in monthReports.docs) {
        final status = doc.data()['status'] as String;
        if (status == 'resolved') {
          resolvedReports++;
        } else {
          pendingReports++;
        }
      }

      // Reviews and ratings
      final monthReviews = await _firestore
          .collection('reviews')
          .where('created_at', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', 
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double totalRating = 0;
      int reviewCount = monthReviews.docs.length;

      for (var doc in monthReviews.docs) {
        totalRating += (doc.data()['rating'] as num).toDouble();
      }

      double avgRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;

      return {
        'month': month,
        'year': year,
        'revenue': {
          'total': totalRevenue,
          'vehicle_rentals': vehicleRevenue,
          'driver_services': driverRevenue,
          'growth_percentage': 12.5, // Calculate from previous month
          'previous_month': 0.0, // Fetch from previous month
        },
        'expenses': {
          'total': totalRevenue * 0.2, // Estimate 20% expenses
          'maintenance': totalRevenue * 0.07,
          'insurance': totalRevenue * 0.055,
          'platform_fees': totalRevenue * 0.04,
          'marketing': totalRevenue * 0.035,
        },
        'profit': totalRevenue * 0.8,
        'profit_margin': 80.0,
        'users': {
          'new_registrations': newUsers.docs.length,
          'total_users': (await _firestore.collection('users').get()).docs.length,
          'active_users': newUsers.docs.length,
          'by_type': {
            'customers': newCustomers,
            'owners': newOwners,
            'drivers': newDrivers,
          },
        },
        'vehicles': {
          'total_listed': (await _firestore.collection('vehicles')
              .where('is_deleted', isEqualTo: false).get()).docs.length,
          'new_listings': newVehicles.docs.length,
          'active_listings': (await _firestore.collection('vehicles')
              .where('availability_status', isEqualTo: 'available')
              .where('is_deleted', isEqualTo: false).get()).docs.length,
          'pending_approval': (await _firestore.collection('vehicles')
              .where('approval_status', isEqualTo: 'pending').get()).docs.length,
        },
        'bookings': {
          'total': totalBookings,
          'completed': completed,
          'ongoing': ongoing,
          'cancelled': cancelled,
          'cancellation_rate': totalBookings > 0 
              ? (cancelled / totalBookings * 100).toStringAsFixed(1)
              : '0',
        },
        'issues': {
          'total_reports': totalReports,
          'resolved': resolvedReports,
          'pending': pendingReports,
          'resolution_rate': totalReports > 0 
              ? (resolvedReports / totalReports * 100).toStringAsFixed(1)
              : '0',
        },
        'ratings': {
          'average_vehicle_rating': avgRating,
          'average_driver_rating': avgRating, // Calculate separately if needed
          'total_reviews': reviewCount,
        },
      };
    } catch (e) {
      print('Error getting monthly report: $e');
      throw Exception('Failed to generate monthly report: $e');
    }
  }
}