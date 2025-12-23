// FILE: motorent/lib/screens/owner/owner_vehicle_overview_page.dart
// COMPLETE REPLACEMENT - Vehicle statistics and reviews overview

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/review.dart';
import '../../models/vehicle.dart';
import '../../services/review_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerVehicleOverviewPage extends StatefulWidget {
  final Vehicle vehicle;
  final String ownerId;

  const OwnerVehicleOverviewPage({
    Key? key,
    required this.vehicle,
    required this.ownerId,
  }) : super(key: key);

  @override
  State<OwnerVehicleOverviewPage> createState() => _OwnerVehicleOverviewPageState();
}

class _OwnerVehicleOverviewPageState extends State<OwnerVehicleOverviewPage>
    with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  late TabController _tabController;
  
  List<Review> _reviews = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Statistics data
  int _totalBookings = 0;
  int _completedBookings = 0;
  double _totalRevenue = 0.0;
  double _averageBookingValue = 0.0;
  double _utilizationRate = 0.0;
  Map<String, int> _monthlyBookings = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 Loading data for vehicle: ${widget.vehicle.vehicleId}');
      
      // Load reviews
      final reviews = await _reviewService.fetchVehicleReviews(
        widget.vehicle.vehicleId.toString()
      );
      
      // Load statistics
      await _loadStatistics();
      
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
      
      print('✅ Loaded ${reviews.length} reviews');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final vehicleId = widget.vehicle.vehicleId.toString();
      
      // Fetch all bookings for this vehicle
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('vehicle_id', isEqualTo: vehicleId)
          .get();

      int total = bookingsSnapshot.docs.length;
      int completed = 0;
      double revenue = 0.0;
      Map<String, int> monthlyBookings = {};
      
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final status = data['booking_status'] as String?;
        
        if (status?.toLowerCase() == 'completed') {
          completed++;
          revenue += (data['total_price'] as num?)?.toDouble() ?? 0.0;
          
          // Count monthly bookings for chart
          final createdAt = (data['created_at'] as Timestamp?)?.toDate();
          if (createdAt != null && createdAt.isAfter(sixMonthsAgo)) {
            final monthKey = DateFormat('MMM').format(createdAt);
            monthlyBookings[monthKey] = (monthlyBookings[monthKey] ?? 0) + 1;
          }
        }
      }

      // Calculate utilization rate (simplified: days booked / days in last 30 days)
      int daysBooked = 0;
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data();
        final status = data['booking_status'] as String?;
        
        if (status == 'confirmed' || status == 'completed') {
          final startDate = (data['start_date'] as Timestamp?)?.toDate();
          final endDate = (data['end_date'] as Timestamp?)?.toDate();
          
          if (startDate != null && endDate != null) {
            // Check if booking overlaps with last 30 days
            if (endDate.isAfter(thirtyDaysAgo) && startDate.isBefore(now)) {
              final overlapStart = startDate.isAfter(thirtyDaysAgo) ? startDate : thirtyDaysAgo;
              final overlapEnd = endDate.isBefore(now) ? endDate : now;
              daysBooked += overlapEnd.difference(overlapStart).inDays + 1;
            }
          }
        }
      }

      double utilizationRate = (daysBooked / 30).clamp(0.0, 1.0);
      double avgBookingValue = completed > 0 ? revenue / completed : 0.0;

      setState(() {
        _totalBookings = total;
        _completedBookings = completed;
        _totalRevenue = revenue;
        _averageBookingValue = avgBookingValue;
        _utilizationRate = utilizationRate;
        _monthlyBookings = monthlyBookings;
      });

      print('📊 Statistics loaded:');
      print('   Total Bookings: $total');
      print('   Completed: $completed');
      print('   Revenue: RM $revenue');
      print('   Utilization: ${(utilizationRate * 100).toStringAsFixed(1)}%');
    } catch (e) {
      print('❌ Error loading statistics: $e');
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return total / _reviews.length;
  }

  Map<int, int> get _ratingDistribution {
    Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in _reviews) {
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.vehicle.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 18),
                  SizedBox(width: 8),
                  Text('Statistics'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review, size: 18),
                  SizedBox(width: 8),
                  Text('Reviews'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: SpinKitFadingCircle(
                color: const Color(0xFF1E88E5),
                size: 50.0,
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatisticsTab(),
                    _buildReviewsTab(),
                  ],
                ),
    );
  }

  Widget _buildStatisticsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Card
            _buildVehicleCard(),
            const SizedBox(height: 20),

            // Key Metrics
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Bookings',
                    _totalBookings.toString(),
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Completed',
                    _completedBookings.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Revenue',
                    'RM ${_totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Avg. Value',
                    'RM ${_averageBookingValue.toStringAsFixed(0)}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Utilization Rate
            Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Utilization Rate (30 days)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(_utilizationRate * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _utilizationRate >= 0.7
                              ? Colors.green
                              : _utilizationRate >= 0.4
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _utilizationRate,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _utilizationRate >= 0.7
                            ? Colors.green
                            : _utilizationRate >= 0.4
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _utilizationRate >= 0.7
                        ? 'Excellent utilization! Your vehicle is in high demand.'
                        : _utilizationRate >= 0.4
                            ? 'Good performance. Consider promotions to increase bookings.'
                            : 'Low utilization. Review pricing or increase marketing efforts.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Booking Trend Chart
            if (_monthlyBookings.isNotEmpty) ...[
              const Text(
                'Booking Trend (Last 6 Months)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
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
                child: _buildBookingChart(),
              ),
              const SizedBox(height: 20),
            ],

            // Rating Summary
            if (_reviews.isNotEmpty) ...[
              const Text(
                'Rating Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E88E5),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return Icon(
                                index < _averageRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 24,
                                color: Colors.amber,
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_reviews.length} ${_reviews.length == 1 ? 'review' : 'reviews'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: _ratingDistribution.entries
                            .toList()
                            .reversed
                            .map((entry) => _buildRatingBar(
                                  entry.key,
                                  entry.value,
                                  _reviews.length,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Reviews Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This vehicle hasn\'t received any reviews from customers yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          return _buildReviewCard(_reviews[index]);
        },
      ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vehicle.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.vehicle.licensePlate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.vehicle.isAvailable
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.vehicle.isAvailable
                            ? 'Available'
                            : 'Unavailable',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Daily Rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${widget.vehicle.pricePerDay.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Column(
                  children: [
                    const Text(
                      'Rating',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _reviews.isNotEmpty
                              ? _averageRating.toStringAsFixed(1)
                              : 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingChart() {
    final now = DateTime.now();
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month - (5 - i), 1);
      final monthKey = DateFormat('MMM').format(monthDate);
      final count = _monthlyBookings[monthKey] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: const Color(0xFF1E88E5),
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (_monthlyBookings.values.isEmpty
                ? 5
                : _monthlyBookings.values.reduce((a, b) => a > b ? a : b) + 2)
            .toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final monthDate =
                    DateTime(now.year, now.month - (5 - value.toInt()), 1);
                return Text(
                  DateFormat('MMM').format(monthDate),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    double percentage = total > 0 ? count / total : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1E88E5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  radius: 24,
                  backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(review.createdAt),
                        style: TextStyle(
                          fontSize: 12,
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
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 22,
                  color: index < review.rating ? Colors.amber : Colors.grey,
                );
              }),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                review.comment,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}