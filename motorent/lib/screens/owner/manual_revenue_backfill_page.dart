// FILE: motorent/lib/screens/owner/manual_revenue_backfill_page.dart
// ✅ COMPLETE MANUAL BACKFILL INTERFACE

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/vehicle_revenue_tracking_service.dart';

class ManualRevenueBackfillPage extends StatefulWidget {
  final int ownerId;

  const ManualRevenueBackfillPage({
    Key? key,
    required this.ownerId,
  }) : super(key: key);

  @override
  State<ManualRevenueBackfillPage> createState() => _ManualRevenueBackfillPageState();
}

class _ManualRevenueBackfillPageState extends State<ManualRevenueBackfillPage> {
  final VehicleRevenueTrackingService _revenueService = VehicleRevenueTrackingService();
  
  bool _isLoading = true;
  bool _isBackfilling = false;
  int _totalCompletedBookings = 0;
  int _recordedBookings = 0;
  int _unrecordedBookings = 0;
  List<Map<String, dynamic>> _unrecordedBookingsList = [];
  
  // Backfill results
  int _processedCount = 0;
  int _successCount = 0;
  int _errorCount = 0;
  List<String> _errorMessages = [];
  bool _backfillComplete = false;

  @override
  void initState() {
    super.initState();
    _loadBookingStats();
  }

  Future<void> _loadBookingStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');


      // Get all completed bookings
      final completedSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('owner_id', isEqualTo: currentUser.uid)
          .where('booking_status', isEqualTo: 'completed')
          .get();


      // Count recorded vs unrecorded
      int recorded = 0;
      int unrecorded = 0;
      List<Map<String, dynamic>> unrecordedList = [];

      for (var doc in completedSnapshot.docs) {
        final data = doc.data();
        final isRecorded = data['revenue_recorded'] == true;

        if (isRecorded) {
          recorded++;
        } else {
          unrecorded++;
          
          // Add to unrecorded list with details
          unrecordedList.add({
            'booking_id': doc.id,
            'vehicle_name': data['vehicle_name'] ?? 'Unknown',
            'customer_name': data['user_name'] ?? 'Unknown',
            'total_price': (data['total_price'] as num?)?.toDouble() ?? 0.0,
            'start_date': data['start_date'] is Timestamp 
                ? (data['start_date'] as Timestamp).toDate()
                : DateTime.now(),
            'completion_date': data['completion_date'] is Timestamp
                ? (data['completion_date'] as Timestamp).toDate()
                : (data['updated_at'] is Timestamp
                    ? (data['updated_at'] as Timestamp).toDate()
                    : DateTime.now()),
            'need_driver': data['need_driver'] ?? false,
            'driver_price': (data['driver_price'] as num?)?.toDouble(),
          });
        }
      }


      setState(() {
        _totalCompletedBookings = completedSnapshot.docs.length;
        _recordedBookings = recorded;
        _unrecordedBookings = unrecorded;
        _unrecordedBookingsList = unrecordedList;
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading stats: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _runFullBackfill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Full Backfill'),
        content: Text(
          'This will process $_unrecordedBookings unrecorded bookings and populate the vehicle_revenue collection.\n\nThis may take a few moments. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Run Backfill', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isBackfilling = true;
      _processedCount = 0;
      _successCount = 0;
      _errorCount = 0;
      _errorMessages = [];
      _backfillComplete = false;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');


      final result = await _revenueService.backfillAllRevenue(currentUser.uid);


      setState(() {
        _processedCount = result['processed'] ?? 0;
        _successCount = result['successful'] ?? 0;
        _errorCount = result['errors'] ?? 0;
        _backfillComplete = true;
        _isBackfilling = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Backfill complete! Processed ${result['successful']} bookings.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Reload stats
        await _loadBookingStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Backfill failed: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e, stackTrace) {
      
      setState(() {
        _isBackfilling = false;
        _errorMessages.add(e.toString());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _backfillSingleBooking(String bookingId) async {
    setState(() {
      _isBackfilling = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');


      // Get booking data
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data()!;

      final completionDate = bookingData['completion_date'] is Timestamp
          ? (bookingData['completion_date'] as Timestamp).toDate()
          : (bookingData['updated_at'] is Timestamp
              ? (bookingData['updated_at'] as Timestamp).toDate()
              : DateTime.now());

      final success = await _revenueService.recordBookingRevenue(
        bookingId: bookingId,
        vehicleId: bookingData['vehicle_id'],
        ownerId: bookingData['owner_id'],
        totalPrice: (bookingData['total_price'] as num).toDouble(),
        startDate: (bookingData['start_date'] as Timestamp).toDate(),
        endDate: (bookingData['end_date'] as Timestamp).toDate(),
        completionDate: completionDate,
        needDriver: bookingData['need_driver'] ?? false,
        driverPrice: (bookingData['driver_price'] as num?)?.toDouble(),
      );

      setState(() {
        _isBackfilling = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Booking revenue recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload stats
        await _loadBookingStats();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to record revenue'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      
      setState(() {
        _isBackfilling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Backfill'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isBackfilling ? null : _loadBookingStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Completed',
                          _totalCompletedBookings.toString(),
                          Icons.check_circle,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Recorded',
                          _recordedBookings.toString(),
                          Icons.check,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Unrecorded',
                          _unrecordedBookings.toString(),
                          Icons.warning,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Ready to Process',
                          _unrecordedBookings.toString(),
                          Icons.upload,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Backfill Results (if completed)
                  if (_backfillComplete) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                              const SizedBox(width: 12),
                              const Text(
                                'Backfill Complete!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildResultRow('Processed', _processedCount.toString(), Colors.blue),
                          const SizedBox(height: 8),
                          _buildResultRow('Successful', _successCount.toString(), Colors.green),
                          const SizedBox(height: 8),
                          _buildResultRow('Errors', _errorCount.toString(), Colors.red),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Button
                  if (_unrecordedBookings > 0 && !_backfillComplete) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isBackfilling ? null : _runFullBackfill,
                        icon: _isBackfilling
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.sync, color: Colors.white),
                        label: Text(
                          _isBackfilling
                              ? 'Processing...'
                              : 'Run Full Backfill ($_unrecordedBookings bookings)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // No unrecorded bookings message
                  if (_unrecordedBookings == 0) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 40),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All Set!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'All completed bookings have been recorded in the revenue system.',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Unrecorded Bookings List
                  if (_unrecordedBookingsList.isNotEmpty) ...[
                    const Text(
                      'Unrecorded Bookings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._unrecordedBookingsList.map((booking) {
                      return _buildBookingCard(booking);
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final vehicleRevenue = booking['total_price'] as double;
    final driverPrice = booking['driver_price'] as double?;
    final actualRevenue = driverPrice != null ? vehicleRevenue - driverPrice : vehicleRevenue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['vehicle_name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['customer_name'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM ${actualRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    if (driverPrice != null)
                      Text(
                        '+ RM ${driverPrice.toStringAsFixed(2)} driver',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(booking['start_date']),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.check_circle, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(booking['completion_date']),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isBackfilling
                    ? null
                    : () => _backfillSingleBooking(booking['booking_id']),
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Process This Booking'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}