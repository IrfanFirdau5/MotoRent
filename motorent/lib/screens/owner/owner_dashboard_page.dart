import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_vehicle_page.dart';
import 'my_vehicles_page.dart';
import 'owner_bookings_page.dart';
import 'revenue_overview_page.dart';
import 'manage_company_drivers_page.dart';
import 'owner_report_page.dart';
import '/services/firebase_booking_service.dart';
import '/services/firebase_vehicle_service.dart';
import '/models/vehicle.dart';
import '../debug_everything_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  int _totalVehicles = 0;
  int _activeBookings = 0;
  double _monthlyRevenue = 0;
  int _totalBookings = 0;
  double _averageRating = 0;
  
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
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      print('📊 Loading dashboard data for owner: ${currentUser.uid}');

      // Fetch vehicles
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('owner_id', isEqualTo: currentUser.uid)
          .where('is_deleted', isEqualTo: false)
          .get();

      // Fetch bookings
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('owner_id', isEqualTo: currentUser.uid)
          .get();

      // Calculate statistics
      int totalVehicles = vehiclesSnapshot.docs.length;
      int totalBookings = bookingsSnapshot.docs.length;
      int activeBookings = 0;
      double monthlyRevenue = 0.0;
      double totalRating = 0.0;
      int ratedVehicles = 0;

      // Calculate active bookings and revenue
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final status = data['booking_status'] as String?;
        
        // Count active bookings
        if (status?.toLowerCase() == 'confirmed') {
          final endDate = data['end_date'] is Timestamp 
              ? (data['end_date'] as Timestamp).toDate()
              : DateTime.now();
          
          if (endDate.isAfter(now)) {
            activeBookings++;
          }
        }
        
        // Calculate monthly revenue from completed bookings
        if (status?.toLowerCase() == 'completed') {
          final completedDate = data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.now();
          
          if (completedDate.isAfter(monthStart)) {
            monthlyRevenue += (data['total_price'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      // Calculate average rating
      for (var doc in vehiclesSnapshot.docs) {
        final data = doc.data();
        final rating = data['rating'] as num?;
        if (rating != null) {
          totalRating += rating.toDouble();
          ratedVehicles++;
        }
      }

      double averageRating = ratedVehicles > 0 ? totalRating / ratedVehicles : 0.0;

      print('✅ Dashboard data loaded:');
      print('   Vehicles: $totalVehicles');
      print('   Active Bookings: $activeBookings');
      print('   Total Bookings: $totalBookings');
      print('   Monthly Revenue: RM $monthlyRevenue');
      print('   Average Rating: $averageRating');

      setState(() {
        _totalVehicles = totalVehicles;
        _activeBookings = activeBookings;
        _monthlyRevenue = monthlyRevenue;
        _totalBookings = totalBookings;
        _averageRating = averageRating;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentBookings() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
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
      print('Error loading recent bookings: $e');
      return [];
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
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      widget.ownerName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Vehicles',
                            _totalVehicles.toString(),
                            Icons.directions_car,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Active Bookings',
                            _activeBookings.toString(),
                            Icons.event_available,
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
                            'Monthly Revenue',
                            'RM ${_monthlyRevenue.toStringAsFixed(0)}',
                            Icons.attach_money,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Avg Rating',
                            _averageRating.toStringAsFixed(1),
                            Icons.star,
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Add Vehicle',
                            Icons.add_circle,
                            Colors.blue,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddVehiclePage(
                                    ownerId: widget.ownerId,
                                  ),
                                ),
                              ).then((value) {
                                if (value == true) {
                                  _loadDashboardData();
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'My Vehicles',
                            Icons.garage,
                            Colors.green,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyVehiclesPage(
                                    ownerId: widget.ownerId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'View Bookings',
                            Icons.calendar_month,
                            Colors.orange,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OwnerBookingsPage(
                                    ownerId: widget.ownerId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            'My Drivers',
                            Icons.people,
                            Colors.purple,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManageCompanyDriversPage(
                                    ownerId: widget.ownerId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Report Issue Button
                    _buildActionButton(
                      'Report Issue',
                      Icons.report_problem,
                      Colors.red,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OwnerReportPage(
                              userId: widget.ownerId.toString(),
                              userName: widget.ownerName,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Revenue Chart
                    const Text(
                      'Revenue Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RevenueOverviewPage(
                              ownerId: widget.ownerId,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                                          return Text(
                                            months[value.toInt()],
                                            style: const TextStyle(fontSize: 12),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: [
                                      const FlSpot(0, 3000),
                                      const FlSpot(1, 3500),
                                      const FlSpot(2, 4200),
                                      const FlSpot(3, 3800),
                                      const FlSpot(4, 4500),
                                      const FlSpot(5, 4567.50),
                                    ],
                                    isCurved: true,
                                    color: const Color(0xFF1E88E5),
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.touch_app,
                                      size: 14,
                                      color: Color(0xFF1E88E5),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tap for details',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DebugEverythingPage(),
                          ),
                        );
                      },
                      child: const Text('Debug Everything'),
                    ),
                    
                    // Recent Bookings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Bookings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OwnerBookingsPage(
                                  ownerId: widget.ownerId,
                                ),
                              ),
                            );
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
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'No recent bookings',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: snapshot.data!.map((booking) {
                            return _buildRecentBookingCard(
                              booking['vehicleName'],
                              booking['customerName'],
                              booking['dates'],
                              booking['amount'],
                              booking['status'],
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecentBookingCard(
    String vehicleName,
    String customerName,
    String dates,
    String amount,
    String status,
  ) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customerName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dates,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}