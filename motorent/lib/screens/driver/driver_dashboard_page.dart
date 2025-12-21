// FILE: motorent/lib/screens/driver/driver_dashboard_page.dart
// REPLACE THE ENTIRE FILE WITH THIS

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/ride_request.dart';
import '../../services/driver_service.dart';
import '../../services/firebase_driver_service.dart';
import 'driver_availability_page.dart';
import 'driver_upcoming_jobs_page.dart';
import 'driver_earnings_page.dart';
import 'driver_profile_page.dart';
import '../login_page.dart';
import '../../services/auth_service.dart';
import 'driver_report_page.dart';

class DriverDashboardPage extends StatefulWidget {
  final User driver;

  const DriverDashboardPage({
    Key? key,
    required this.driver,
  }) : super(key: key);

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  final DriverService _driverService = DriverService();
  final FirebaseDriverService _firebaseDriverService = FirebaseDriverService();
  final AuthService _authService = AuthService();
  
  bool _isAvailable = false;
  bool _isLoading = true;
  List<RideRequest> _pendingRequests = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final availability = await _driverService.getDriverAvailability(widget.driver.userId);
      final requests = await _driverService.fetchPendingRequests(widget.driver.userId);
      final stats = await _driverService.fetchDriverStats(widget.driver.userId);

      setState(() {
        _isAvailable = availability;
        _pendingRequests = requests;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability() async {
    setState(() {
      _isAvailable = !_isAvailable;
    });

    try {
      await _driverService.updateAvailability(widget.driver.userId, _isAvailable);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAvailable 
                ? 'You are now available for ride requests' 
                : 'You are now unavailable',
          ),
          backgroundColor: _isAvailable ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        _isAvailable = !_isAvailable;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update availability: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _respondToRequest(RideRequest request, bool accept) async {
    try {
      // ✅ FIXED: bookingId is now already a String containing the Firestore doc ID
      print('🟢 Calling respondToRequest with:');
      print('   Booking ID (Firestore Doc ID): ${request.bookingId}');
      print('   Driver ID: ${widget.driver.userIdString}');
      print('   Accept: $accept');
      
      // ✅ VALIDATION: Make sure we have a valid Firestore document ID
      if (request.bookingId.isEmpty || request.bookingId == '0') {
        throw Exception('Invalid booking ID: ${request.bookingId}');
      }
      
      // Use Firebase service directly with proper parameters
      await _firebaseDriverService.respondToRequest(
        request.bookingId, // ✅ PERFECT: This is now the actual Firestore document ID
        widget.driver.userIdString,
        accept,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept 
                ? 'Ride request accepted! Job added to your schedule.' 
                : 'Ride request declined',
          ),
          backgroundColor: accept ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      
      _loadDashboardData();
    } catch (e) {
      print('❌ Error in _respondToRequest: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverProfilePage(driver: widget.driver),
                ),
              ).then((_) => _loadDashboardData());
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SpinKitFadingCircle(
                color: const Color(0xFF1E88E5),
                size: 50.0,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${widget.driver.name}!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Availability Toggle
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_isAvailable ? Colors.green : Colors.grey)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isAvailable ? Icons.check_circle : Icons.cancel,
                                size: 32,
                                color: _isAvailable ? Colors.green : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Availability Status',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isAvailable ? 'Available for rides' : 'Unavailable',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isAvailable,
                              onChanged: (value) => _toggleAvailability(),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Statistics
                    const Text(
                      'Today\'s Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            _stats['completed_today']?.toString() ?? '0',
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Upcoming',
                            _stats['upcoming']?.toString() ?? '0',
                            Icons.schedule,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Jobs',
                            _stats['total_jobs']?.toString() ?? '0',
                            Icons.work_outline,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Earnings',
                            'RM ${(_stats['total_earnings'] ?? 0.0).toStringAsFixed(2)}',
                            Icons.attach_money,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pending Requests
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pending Requests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_pendingRequests.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_pendingRequests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_pendingRequests.isEmpty)
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No pending requests',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...(_pendingRequests.take(3).map((request) => 
                        _buildRequestCard(request)
                      )),

                    const SizedBox(height: 20),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActionCard(
                      'Manage Availability',
                      'Set your schedule and available times',
                      Icons.calendar_today,
                      Colors.blue,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverAvailabilityPage(
                              driver: widget.driver,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActionCard(
                      'View Upcoming Jobs',
                      'Check your scheduled rides',
                      Icons.directions_car,
                      Colors.green,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverUpcomingJobsPage(
                              driver: widget.driver,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActionCard(
                      'View Earnings',
                      'Track your income and payments',
                      Icons.account_balance_wallet,
                      Colors.purple,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverEarningsPage(
                              driver: widget.driver,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    _buildActionCard(
                      'Report Issue',
                      'Report problems or concerns',
                      Icons.report_problem,
                      Colors.red,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DriverReportPage(
                              userId: widget.driver.userIdString,
                              userName: widget.driver.name,
                            ),
                          ),
                        );
                      },
                    ),

                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(RideRequest request) {
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
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
                  child: Text(
                    request.customerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1E88E5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.vehicleName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.pickupLocation,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(request.pickupTime),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToRequest(request, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToRequest(request, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}