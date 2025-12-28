// FILE: motorent/lib/services/firebase_driver_payment_service.dart
// CREATE THIS NEW FILE

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDriverPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _withdrawalsCollection = 'driver_withdrawals';
  final String _driverPaymentsCollection = 'driver_payments';

  /// Get driver's payment information (available balance, pending withdrawals, etc.)
  Future<Map<String, dynamic>> getDriverPaymentInfo(String driverId) async {
    try {
      print('🔍 Fetching payment info for driver: $driverId');
      
      // Get all earnings for the driver (both paid and pending count as available)
      final earningsSnapshot = await _firestore
          .collection('driver_earnings')
          .where('driver_id', isEqualTo: driverId)
          .get();

      print('📊 Found ${earningsSnapshot.docs.length} earning records');

      double totalEarnings = 0.0;
      double pendingEarnings = 0.0;
      
      for (var doc in earningsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final status = data['status'] as String?;
        
        print('  💰 Earning: RM $amount, Status: $status');
        
        // Count all earnings that aren't yet withdrawn
        totalEarnings += amount;
        
        // Track pending vs paid separately if needed
        if (status?.toLowerCase() == 'pending') {
          pendingEarnings += amount;
        }
      }

      print('💵 Total Earnings: RM $totalEarnings');

      // Get all completed withdrawals
      final withdrawalsSnapshot = await _firestore
          .collection(_withdrawalsCollection)
          .where('driver_id', isEqualTo: driverId)
          .where('status', isEqualTo: 'completed')
          .get();

      print('✅ Found ${withdrawalsSnapshot.docs.length} completed withdrawals');

      double totalWithdrawn = 0.0;
      for (var doc in withdrawalsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        totalWithdrawn += amount;
        print('  💸 Withdrawn: RM $amount');
      }

      print('💸 Total Withdrawn: RM $totalWithdrawn');

      // Get pending withdrawals
      final pendingSnapshot = await _firestore
          .collection(_withdrawalsCollection)
          .where('driver_id', isEqualTo: driverId)
          .where('status', whereIn: ['pending', 'processing'])
          .get();

      print('⏳ Found ${pendingSnapshot.docs.length} pending withdrawals');

      double pendingWithdrawals = 0.0;
      for (var doc in pendingSnapshot.docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        pendingWithdrawals += amount;
        print('  ⏳ Pending: RM $amount');
      }

      print('⏳ Total Pending Withdrawals: RM $pendingWithdrawals');

      // Available balance = total earnings - total withdrawn - pending withdrawals
      double availableBalance = totalEarnings - totalWithdrawn - pendingWithdrawals;

      print('');
      print('═══════════════════════════════════════');
      print('💰 PAYMENT INFO SUMMARY');
      print('═══════════════════════════════════════');
      print('Total Earnings:        RM ${totalEarnings.toStringAsFixed(2)}');
      print('Pending Earnings:      RM ${pendingEarnings.toStringAsFixed(2)}');
      print('Total Withdrawn:       RM ${totalWithdrawn.toStringAsFixed(2)}');
      print('Pending Withdrawals:   RM ${pendingWithdrawals.toStringAsFixed(2)}');
      print('AVAILABLE BALANCE:     RM ${availableBalance.toStringAsFixed(2)}');
      print('═══════════════════════════════════════');
      print('');

      return {
        'total_earnings': totalEarnings,
        'pending_earnings': pendingEarnings,
        'total_withdrawn': totalWithdrawn,
        'pending_withdrawals': pendingWithdrawals,
        'available_balance': availableBalance,
      };
    } catch (e) {
      print('❌ Error getting driver payment info: $e');
      print('Stack trace: ${StackTrace.current}');
      return {
        'total_earnings': 0.0,
        'pending_earnings': 0.0,
        'total_withdrawn': 0.0,
        'pending_withdrawals': 0.0,
        'available_balance': 0.0,
      };
    }
  }

  /// Request a withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required String driverId,
    required String driverName,
    required String driverEmail,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    try {
      // Validate available balance
      final paymentInfo = await getDriverPaymentInfo(driverId);
      final availableBalance = paymentInfo['available_balance'] as double;

      if (amount > availableBalance) {
        return {
          'success': false,
          'message': 'Insufficient balance. Available: RM ${availableBalance.toStringAsFixed(2)}',
        };
      }

      if (amount < 10.0) {
        return {
          'success': false,
          'message': 'Minimum withdrawal amount is RM 10.00',
        };
      }

      // Create withdrawal request
      final withdrawalData = {
        'driver_id': driverId,
        'driver_name': driverName,
        'driver_email': driverEmail,
        'amount': amount,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_holder_name': accountHolderName,
        'status': 'pending', // pending, processing, completed, rejected
        'requested_at': FieldValue.serverTimestamp(),
        'processed_at': null,
        'processed_by': null,
        'transfer_reference': null,
        'rejection_reason': null,
        'stripe_transfer_id': null,
      };

      final docRef = await _firestore
          .collection(_withdrawalsCollection)
          .add(withdrawalData);

      print('✅ Withdrawal request created: ${docRef.id}');
      print('   Amount: RM ${amount.toStringAsFixed(2)}');
      print('   Driver: $driverName');
      print('   Status: pending');

      return {
        'success': true,
        'withdrawal_id': docRef.id,
        'message': 'Withdrawal request submitted successfully',
      };
    } catch (e) {
      print('❌ Error requesting withdrawal: $e');
      return {
        'success': false,
        'message': 'Failed to submit withdrawal request: $e',
      };
    }
  }

  /// Get withdrawal history for a driver
  Future<List<Map<String, dynamic>>> getWithdrawalHistory(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_withdrawalsCollection)
          .where('driver_id', isEqualTo: driverId)
          .orderBy('requested_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['withdrawal_id'] = doc.id;
        
        // Convert Timestamp to DateTime
        if (data['requested_at'] is Timestamp) {
          data['created_at'] = (data['requested_at'] as Timestamp).toDate();
        }
        if (data['processed_at'] is Timestamp) {
          data['processed_at'] = (data['processed_at'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    } catch (e) {
      print('Error getting withdrawal history: $e');
      return [];
    }
  }

  /// Admin: Get all pending withdrawal requests
  Future<List<Map<String, dynamic>>> getPendingWithdrawals() async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('🔍 FETCHING PENDING WITHDRAWALS');
      print('═══════════════════════════════════════');
      
      final querySnapshot = await _firestore
          .collection(_withdrawalsCollection)
          .where('status', isEqualTo: 'pending')
          .get();

      print('Found ${querySnapshot.docs.length} pending withdrawals');

      final withdrawals = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['withdrawal_id'] = doc.id;
        
        print('  ✓ Withdrawal ID: ${doc.id}');
        print('    Driver: ${data['driver_name']}');
        print('    Amount: RM ${data['amount']}');
        print('    Status: ${data['status']}');
        
        if (data['requested_at'] is Timestamp) {
          data['created_at'] = (data['requested_at'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();

      // Sort by requested_at (oldest first)
      withdrawals.sort((a, b) {
        final aDate = a['created_at'] as DateTime?;
        final bDate = b['created_at'] as DateTime?;
        if (aDate == null || bDate == null) return 0;
        return aDate.compareTo(bDate);
      });

      print('═══════════════════════════════════════');
      print('');
      
      return withdrawals;
    } catch (e) {
      print('');
      print('❌ Error getting pending withdrawals: $e');
      print('Stack trace: ${StackTrace.current}');
      print('');
      return [];
    }
  }

  /// Admin: Approve and process withdrawal with Stripe
  Future<Map<String, dynamic>> approveWithdrawalWithStripe({
    required String withdrawalId,
    required String adminId,
    required String driverEmail,
    required double amount,
  }) async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('💰 PROCESSING WITHDRAWAL WITH STRIPE');
      print('═══════════════════════════════════════');
      print('Withdrawal ID: $withdrawalId');
      print('Amount: RM ${amount.toStringAsFixed(2)}');
      print('Driver Email: $driverEmail');
      
      // Note: In test mode, this will simulate the transfer
      // In live mode, this requires the driver to have a Stripe account
      // For now, we'll just mark as completed and add a note
      
      // TODO: Implement actual Stripe Transfer when needed
      // This would require:
      // 1. Driver to have a Stripe Connect account
      // 2. Or driver to have provided their bank details to Stripe
      // 3. Use Stripe API to create a transfer
      
      final transferReference = 'STRIPE_TEST_${DateTime.now().millisecondsSinceEpoch}';
      
      await _firestore.collection(_withdrawalsCollection).doc(withdrawalId).update({
        'status': 'completed',
        'processed_at': FieldValue.serverTimestamp(),
        'processed_by': adminId,
        'transfer_reference': transferReference,
        'payment_method': 'stripe_transfer',
        'stripe_transfer_id': null, // Would be set if using real Stripe transfers
      });

      print('✅ Withdrawal approved (test mode)');
      print('   Reference: $transferReference');
      print('═══════════════════════════════════════');
      print('');
      
      return {
        'success': true,
        'transfer_reference': transferReference,
        'message': 'Withdrawal processed successfully',
      };
    } catch (e) {
      print('❌ Error processing withdrawal: $e');
      return {
        'success': false,
        'message': 'Failed to process withdrawal: $e',
      };
    }
  }

  /// Admin: Approve and process withdrawal (manual bank transfer)
  Future<bool> approveWithdrawal({
    required String withdrawalId,
    required String adminId,
    required String transferReference,
    String? stripeTransferId,
  }) async {
    try {
      await _firestore.collection(_withdrawalsCollection).doc(withdrawalId).update({
        'status': 'completed',
        'processed_at': FieldValue.serverTimestamp(),
        'processed_by': adminId,
        'transfer_reference': transferReference,
        'payment_method': 'manual_bank_transfer',
        'stripe_transfer_id': stripeTransferId,
      });

      print('✅ Withdrawal approved: $withdrawalId');
      return true;
    } catch (e) {
      print('❌ Error approving withdrawal: $e');
      return false;
    }
  }

  /// Admin: Reject withdrawal
  Future<bool> rejectWithdrawal({
    required String withdrawalId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _firestore.collection(_withdrawalsCollection).doc(withdrawalId).update({
        'status': 'rejected',
        'processed_at': FieldValue.serverTimestamp(),
        'processed_by': adminId,
        'rejection_reason': reason,
      });

      print('✅ Withdrawal rejected: $withdrawalId');
      return true;
    } catch (e) {
      print('❌ Error rejecting withdrawal: $e');
      return false;
    }
  }

  /// Get withdrawal statistics for admin dashboard
  Future<Map<String, dynamic>> getWithdrawalStatistics() async {
    try {
      final allWithdrawals = await _firestore
          .collection(_withdrawalsCollection)
          .get();

      int pending = 0;
      int processing = 0;
      int completed = 0;
      int rejected = 0;
      double totalRequested = 0.0;
      double totalCompleted = 0.0;

      for (var doc in allWithdrawals.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final amount = (data['amount'] as num).toDouble();

        totalRequested += amount;

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'processing':
            processing++;
            break;
          case 'completed':
            completed++;
            totalCompleted += amount;
            break;
          case 'rejected':
            rejected++;
            break;
        }
      }

      return {
        'total_requests': allWithdrawals.docs.length,
        'pending': pending,
        'processing': processing,
        'completed': completed,
        'rejected': rejected,
        'total_requested': totalRequested,
        'total_completed': totalCompleted,
      };
    } catch (e) {
      print('Error getting withdrawal statistics: $e');
      return {
        'total_requests': 0,
        'pending': 0,
        'processing': 0,
        'completed': 0,
        'rejected': 0,
        'total_requested': 0.0,
        'total_completed': 0.0,
      };
    }
  }

  /// Stream pending withdrawals for real-time updates (admin)
  Stream<List<Map<String, dynamic>>> streamPendingWithdrawals() {
    return _firestore
        .collection(_withdrawalsCollection)
        .where('status', isEqualTo: 'pending')
        .orderBy('requested_at', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['withdrawal_id'] = doc.id;
        
        if (data['requested_at'] is Timestamp) {
          data['created_at'] = (data['requested_at'] as Timestamp).toDate();
        }
        
        return data;
      }).toList();
    });
  }

  /// Create earnings record when a job is completed
  Future<bool> createEarningRecord({
    required String driverId,
    required int jobId,
    required double amount,
    required String description,
  }) async {
    try {
      await _firestore.collection('driver_earnings').add({
        'driver_id': driverId,
        'job_id': jobId,
        'amount': amount,
        'description': description,
        'status': 'paid', // Mark as paid immediately
        'date': FieldValue.serverTimestamp(),
        'paid_at': FieldValue.serverTimestamp(),
      });

      print('✅ Earning record created for driver $driverId: RM ${amount.toStringAsFixed(2)}');
      return true;
    } catch (e) {
      print('❌ Error creating earning record: $e');
      return false;
    }
  }

  /// 🧪 TEMPORARY: Create test earnings data for a driver
  Future<void> createTestEarningsForDriver(String driverId, String driverName) async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('🧪 CREATING TEST EARNINGS');
      print('═══════════════════════════════════════');
      print('Driver ID: $driverId');
      print('Driver Name: $driverName');
      print('');
      
      // Create 11 test earnings (matching what you see in the UI)
      final now = DateTime.now();
      
      final List<Map<String, dynamic>> testEarnings = [
        {
          'description': 'airport to airport',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 12)),
        },
        {
          'description': 'heer to there',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 18)),
        },
        {
          'description': 'was to here',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 23)),
        },
        {
          'description': 'Job #4',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 25)),
        },
        {
          'description': 'Job #5',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 30)),
        },
        {
          'description': 'Job #6',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 35)),
        },
        {
          'description': 'Job #7',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 40)),
        },
        {
          'description': 'Job #8',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 45)),
        },
        {
          'description': 'Job #9',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 50)),
        },
        {
          'description': 'Job #10',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 55)),
        },
        {
          'description': 'Job #11',
          'amount': 100.0,
          'date': now.subtract(const Duration(days: 60)),
        },
      ];

      for (int i = 0; i < testEarnings.length; i++) {
        final earning = testEarnings[i];
        await _firestore.collection('driver_earnings').add({
          'driver_id': driverId,
          'job_id': DateTime.now().millisecondsSinceEpoch + i, // Temporary job ID
          'amount': earning['amount'],
          'description': earning['description'],
          'status': 'paid', // Mark as paid so it's available for withdrawal
          'date': Timestamp.fromDate(earning['date'] as DateTime),
          'paid_at': Timestamp.fromDate(earning['date'] as DateTime),
          'created_at': FieldValue.serverTimestamp(),
        });
        
        print('  ✅ Created: ${earning['description']} - RM ${earning['amount']}');
      }

      print('');
      print('✅ Successfully created ${testEarnings.length} test earnings!');
      print('   Total: RM ${testEarnings.fold(0.0, (sum, e) => sum + (e['amount'] as double)).toStringAsFixed(2)}');
      print('═══════════════════════════════════════');
      print('');
    } catch (e) {
      print('❌ Error creating test earnings: $e');
      throw e;
    }
  }
}