// FILE: motorent/lib/screens/owner/owner_dashboard_page.dart
// ✅ COMPLETE VERSION WITH SUBSCRIPTION SYSTEM - FULL FILE

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_vehicle_page.dart';
import 'my_vehicles_page.dart';
import 'owner_bookings_page.dart';
import 'revenue_overview_page.dart';
import 'manage_company_drivers_page.dart';
import 'owner_report_page.dart';
import 'owner_profile_page.dart';
import '/services/firebase_booking_service.dart';
import '/services/firebase_vehicle_service.dart';
import '../../services/vehicle_revenue_tracking_service.dart';
import '/models/vehicle.dart';
import '/models/user.dart';
import '../debug_everything_page.dart';
import '../login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:intl/intl.dart';
import 'manual_revenue_backfill_page.dart';
// ✅ NEW IMPORTS FOR SUBSCRIPTION
import '../../services/subscription_service.dart';
import '../../models/subscription.dart';
import 'subscription_payment_page.dart';
import '../../widgets/subscription_banner.dart';

class OwnerDashboardPage extends StatefulWidget {
  final int ownerId;
  final String ownerName;

  const OwnerDashboardPage({
    Key? key,
    required this.ownerId,
    required this.ownerName,
  }) : super(key: key);

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  bool _isLoading = true;
  final _bookingService = FirebaseBookingService();
  final _vehicleService = FirebaseVehicleService();

  final VehicleRevenueTrackingService _revenueService = VehicleRevenueTrackingService();
  List<double> _last6MonthsRevenue = [0, 0, 0, 0, 0, 0];
  List<String> _last6MonthsLabels = [];
  bool _chartLoading = true;

  int _totalVehicles = 0;
  int _activeBookings = 0;
  double _monthlyRevenue = 0;
  int _totalBookings = 0;
  double _averageRating = 0;
  
  // ✅ NEW: Subscription fields
  final SubscriptionService _subscriptionService = SubscriptionService();
  Subscription? _subscription;
  bool _isLoadingSubscription = true;
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadRevenueChartData();
    _loadAverageRating();
    _loadSubscription(); // ✅ NEW
  }

  // ✅ NEW: Load subscription
  Future<void> _loadSubscription() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final subscription = await _subscriptionService.getUserSubscription(currentUser.uid);
      
      setState(() {
        _subscription = subscription;
        _isLoadingSubscription = false;
      });
      
      
    } catch (e) {
      setState(() {
        _isLoadingSubscription = false;
      });
    }
  }

  // ✅ NEW: Show subscription required dialog
  Future<void> _showSubscriptionRequired() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Upgrade to Pro',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlock Revenue Overview with MotoRent Pro!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildProFeature(Icons.analytics, 'Detailed Revenue Analytics'),
            const SizedBox(height: 8),
            _buildProFeature(Icons.assessment, 'AI-Powered Insights'),
            const SizedBox(height: 8),
            _buildProFeature(Icons.picture_as_pdf, 'Professional Reports'),
            const SizedBox(height: 8),
            _buildProFeature(Icons.trending_up, 'Profit/Loss Analysis'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Only RM 50.00',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '/month',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 20),
                SizedBox(width: 8),
                Text(
                  'Subscribe Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
    if (result == true && mounted) {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Navigate to subscription payment page
      final subscribed = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionPaymentPage(
            userId: currentUser.uid,
            userEmail: currentUser.email ?? '',
            userName: widget.ownerName,
          ),
        ),
      );
      
      // Reload subscription if payment was successful
      if (subscribed == true) {
        _loadSubscription();
      }
    }
  }

  // ✅ NEW: Build Pro feature item
  Widget _buildProFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const Icon(
          Icons.check_circle,
          size: 18,
          color: Colors.green,
        ),
      ],
    );
  }

  // ✅ NEW: Handle revenue overview tap
  void _handleRevenueOverviewTap() {
    // Check if user has Pro access
    if (_subscription?.hasProAccess ?? false) {
      // User has Pro - navigate to revenue overview
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RevenueOverviewPage(ownerId: widget.ownerId),
        ),
      );
    } else {
      // User doesn't have Pro - show subscription dialog
      _showSubscriptionRequired();
    }
  }

  // ✅ NEW: Show subscription details
  void _showSubscriptionDetails() {
    if (_subscription == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 28),
            SizedBox(width: 12),
            Text('MotoRent Pro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', _subscription!.statusDisplay),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Valid Until',
              DateFormat('dd MMMM yyyy').format(_subscription!.endDate!),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Days Remaining',
              '${_subscription!.daysRemaining} days',
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Price', 'RM 50.00/month'),
            if (_subscription!.isExpiringSoon) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your subscription expires soon!',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('owner_id', isEqualTo: currentUser.uid)
          .where('is_deleted', isEqualTo: false)
          .get();

      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('owner_id', isEqualTo: currentUser.uid)
          .get();

      int totalVehicles = vehiclesSnapshot.docs.length;
      int totalBookings = bookingsSnapshot.docs.length;
      int activeBookings = 0;
      double monthlyRevenue = 0.0;
      double totalRating = 0.0;
      int ratedVehicles = 0;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final status = data['booking_status'] as String?;
        
        if (status?.toLowerCase() == 'confirmed') {
          final endDate = data['end_date'] is Timestamp 
              ? (data['end_date'] as Timestamp).toDate()
              : DateTime.now();
          
          if (endDate.isAfter(now)) {
            activeBookings++;
          }
        }
        
        if (status?.toLowerCase() == 'completed') {
          final completedDate = data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.now();
          
          if (completedDate.isAfter(monthStart)) {
            monthlyRevenue += (data['total_price'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      for (var doc in vehiclesSnapshot.docs) {
        final data = doc.data();
        final rating = data['rating'] as num?;
        if (rating != null) {
          totalRating += rating.toDouble();
          ratedVehicles++;
        }
      }

      double averageRating = ratedVehicles > 0 ? totalRating / ratedVehicles : 0.0;

      setState(() {
        _totalVehicles = totalVehicles;
        _activeBookings = activeBookings;
        _monthlyRevenue = monthlyRevenue;
        _totalBookings = totalBookings;
        _averageRating = averageRating;
        _isLoading = false;
      });

      _loadRevenueChartData();

    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRevenueChartData() async {
    setState(() {
      _chartLoading = true;
    });

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }


      final now = DateTime.now();
      List<double> revenueData = [];
      List<String> monthLabels = [];

      for (int i = 5; i >= 0; i--) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final month = targetDate.month;
        final year = targetDate.year;

        final monthRevenue = await _revenueService.getOwnerRevenueForMonth(
          ownerId: currentUser.uid,
          month: month,
          year: year,
        );

        double totalRevenue = 0;
        for (var vehicleRevenue in monthRevenue) {
          totalRevenue += (vehicleRevenue['total_revenue'] as num?)?.toDouble() ?? 0.0;
        }

        revenueData.add(totalRevenue);
        monthLabels.add(DateFormat('MMM').format(targetDate));

      }

      setState(() {
        _last6MonthsRevenue = revenueData;
        _last6MonthsLabels = monthLabels;
        _chartLoading = false;
      });


    } catch (e, stackTrace) {
      
      setState(() {
        _chartLoading = false;
      });
    }
  }

  Future<void> _loadAverageRating() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;


      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('owner_id', isEqualTo: currentUser.uid)
          .where('is_deleted', isEqualTo: false)
          .get();

      if (vehiclesSnapshot.docs.isEmpty) {
        setState(() {
          _averageRating = 0.0;
        });
        return;
      }

      double totalRatingSum = 0;
      int totalReviewCount = 0;

      for (var vehicleDoc in vehiclesSnapshot.docs) {
        final vehicleData = vehicleDoc.data();
        final rating = (vehicleData['rating'] as num?)?.toDouble();
        final reviewCount = (vehicleData['review_count'] as int?) ?? 0;

        if (rating != null && reviewCount > 0) {
          totalRatingSum += (rating * reviewCount);
          totalReviewCount += reviewCount;
        }
      }

      final averageRating = totalReviewCount > 0 
          ? totalRatingSum / totalReviewCount 
          : 0.0;

      setState(() {
        _averageRating = averageRating;
      });


    } catch (e) {
      setState(() {
        _averageRating = 0.0;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentBookings() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('owner_id', isEqualTo: currentUser.uid)
          .orderBy('created_at', descending: true)
          .limit(3)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'vehicleName': data['vehicle_name'] ?? 'Unknown Vehicle',
          'customerName': data['user_name'] ?? 'Unknown Customer',
          'dates': '${DateFormat('MMM dd').format((data['start_date'] as Timestamp).toDate())} - ${DateFormat('MMM dd').format((data['end_date'] as Timestamp).toDate())}',
          'amount': 'RM ${(data['total_price'] as num).toStringAsFixed(2)}',
          'status': data['booking_status'] ?? 'pending',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await auth.FirebaseAuth.instance.signOut();
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      drawer: _buildSidebar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadDashboardData();
                await _loadSubscription();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    Text(widget.ownerName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),

                    // ✅ NEW: Subscription Banner
                    if (_subscription != null && !_isLoadingSubscription)
                      SubscriptionBanner(
                        subscription: _subscription!,
                        onUpgradeTap: _showSubscriptionRequired,
                        onManageTap: _subscription!.hasProAccess ? _showSubscriptionDetails : null,
                      ),

                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Total Vehicles', _totalVehicles.toString(), Icons.directions_car, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Active Bookings', _activeBookings.toString(), Icons.event_available, Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Monthly Revenue', 'RM ${_monthlyRevenue.toStringAsFixed(0)}', Icons.attach_money, Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Avg Rating', _averageRating.toStringAsFixed(1), Icons.star, Colors.amber)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ✅ UPDATED: Revenue Overview with subscription check
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Revenue Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            if (_subscription?.hasProAccess ?? false)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'PRO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _handleRevenueOverviewTap,
                          icon: Icon(
                            _subscription?.hasProAccess ?? false
                                ? Icons.arrow_forward
                                : Icons.lock,
                            size: 16,
                          ),
                          label: Text(
                            _subscription?.hasProAccess ?? false
                                ? 'View Details'
                                : 'Unlock',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _handleRevenueOverviewTap,
                      child: _buildRevenueChart(),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Bookings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerBookingsPage(ownerId: widget.ownerId)));
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadRecentBookings(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No recent bookings', style: TextStyle(color: Colors.grey[600]))));
                        }
                        return Column(children: snapshot.data!.map((b) => _buildRecentBookingCard(b['vehicleName'], b['customerName'], b['dates'], b['amount'], b['status'])).toList());
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSidebar() {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(widget.ownerName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                ),
                const SizedBox(height: 12),
                Text(widget.ownerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(currentUser?.email ?? '', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Vehicle Owner', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                
                // ✅ NEW: Subscription item in drawer
                if (!_isLoadingSubscription && _subscription != null)
                  ListTile(
                    leading: Icon(
                      _subscription!.hasProAccess ? Icons.star : Icons.star_outline,
                      color: _subscription!.hasProAccess ? Colors.amber : Colors.grey,
                    ),
                    title: Text(
                      _subscription!.hasProAccess ? 'MotoRent Pro' : 'Upgrade to Pro',
                      style: TextStyle(
                        fontWeight: _subscription!.hasProAccess ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      _subscription!.hasProAccess
                          ? 'Active until ${DateFormat('dd MMM yyyy').format(_subscription!.endDate!)}'
                          : 'Unlock premium features',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: _subscription!.hasProAccess
                        ? null
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'RM 50',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    onTap: () {
                      Navigator.pop(context);
                      if (_subscription!.hasProAccess) {
                        _showSubscriptionDetails();
                      } else {
                        _showSubscriptionRequired();
                      }
                    },
                  ),
                
                _buildDrawerItem(icon: Icons.person, title: 'Edit Profile', onTap: () async {
                  Navigator.pop(context);
                  try {
                    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get();
                    if (userDoc.exists && mounted) {
                      final userData = userDoc.data()!;
                      userData['user_id'] = userDoc.id;
                      if (userData['created_at'] is Timestamp) {
                        userData['created_at'] = (userData['created_at'] as Timestamp).toDate().toIso8601String();
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerProfilePage(user: User.fromJson(userData))));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                }),
                const Divider(height: 1),
                
                Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('VEHICLES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
                _buildDrawerItem(icon: Icons.add_circle, title: 'Add Vehicle', color: Colors.blue, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AddVehiclePage(ownerId: widget.ownerId))).then((v) { if (v == true) _loadDashboardData(); });
                }),
                _buildDrawerItem(icon: Icons.garage, title: 'My Vehicles', color: Colors.green, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyVehiclesPage(ownerId: widget.ownerId)));
                }),
                const Divider(height: 1),
                
                Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('MANAGEMENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
                _buildDrawerItem(icon: Icons.calendar_month, title: 'View Bookings', color: Colors.orange, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerBookingsPage(ownerId: widget.ownerId)));
                }),
                _buildDrawerItem(icon: Icons.people, title: 'My Drivers', color: Colors.purple, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ManageCompanyDriversPage(ownerId: widget.ownerId)));
                }),
                _buildDrawerItem(icon: Icons.sync, title: 'Revenue Backfill', color: Colors.green, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ManualRevenueBackfillPage(ownerId: widget.ownerId)));
                }),
                const Divider(height: 1),
                
                Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('SUPPORT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]))),
                _buildDrawerItem(icon: Icons.report_problem, title: 'Report Issue', color: Colors.red, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerReportPage(userId: widget.ownerId.toString(), userName: widget.ownerName)));
                }),
                _buildDrawerItem(icon: Icons.bug_report, title: 'Debug Tools', color: Colors.grey, onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DebugEverythingPage()));
                }),
              ],
            ),
          ),
          
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[300]!))),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); _handleLogout(); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_chartLoading) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hasData = _last6MonthsRevenue.any((revenue) => revenue > 0);
    
    if (!hasData) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No revenue data yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete bookings to see trends',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxRevenue = _last6MonthsRevenue.reduce((a, b) => a > b ? a : b);
    final double chartMaxY = maxRevenue > 0 ? (maxRevenue * 1.2) : 1000;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: chartMaxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('0');
                  if (value >= 1000) {
                    return Text(
                      '${(value / 1000).toStringAsFixed(1)}k',
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _last6MonthsLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _last6MonthsLabels[index],
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                _last6MonthsRevenue.length,
                (index) => FlSpot(index.toDouble(), _last6MonthsRevenue[index]),
              ),
              isCurved: true,
              color: const Color(0xFF1E88E5),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF1E88E5),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF1E88E5).withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final monthLabel = _last6MonthsLabels[spot.x.toInt()];
                  final revenue = spot.y;
                  return LineTooltipItem(
                    '$monthLabel\nRM ${revenue.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBookingCard(String vehicleName, String customerName, String dates, String amount, String status) {
    Color statusColor = status.toLowerCase() == 'confirmed' ? Colors.green : status.toLowerCase() == 'pending' ? Colors.orange : status.toLowerCase() == 'completed' ? Colors.blue : Colors.grey;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.directions_car, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(customerName, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(dates, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5), fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}