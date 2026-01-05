// FILE: motorent/lib/screens/customer/my_bookings_page.dart
// ✅ COMPLETE VERSION with Invoice Access for Customer

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../../models/user.dart';
import '../../services/firebase_booking_service.dart';
import '../../services/firebase_vehicle_service.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/customer_drawer.dart';
import '../../widgets/invoice_access_widget.dart';
import 'vehicle_listing_page.dart';
import 'submit_review_page.dart';

class MyBookingsPage extends StatefulWidget {
  final String userId;
  
  const MyBookingsPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseBookingService _bookingService = FirebaseBookingService();
  final FirebaseVehicleService _vehicleService = FirebaseVehicleService();
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  User? _currentUser;
  List<Booking> _allBookings = [];
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];
  List<Booking> _cancelledBookings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  Map<String, bool> _reviewStatus = {};
  Map<String, Vehicle?> _vehicleCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
    _loadBookings();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      
      final bookings = await _bookingService.fetchUserBookings(widget.userId);
      
      
      for (var booking in bookings) {
        if (booking.bookingStatus.toLowerCase() == 'completed') {
          try {
            final hasReview = await _reviewService.hasReviewedBooking(
              widget.userId,
              booking.bookingId,
            );
            _reviewStatus[booking.bookingId.toString()] = hasReview;
          } catch (e) {
            _reviewStatus[booking.bookingId.toString()] = false;
          }
        }
      }

      setState(() {
        _allBookings = bookings;
        _categorizeBookings();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load bookings: $e';
        _isLoading = false;
      });
    }
  }

  void _categorizeBookings() {
    final now = DateTime.now();
    
    _upcomingBookings = _allBookings.where((booking) {
      return (booking.bookingStatus.toLowerCase() == 'confirmed' ||
              booking.bookingStatus.toLowerCase() == 'pending') &&
          booking.startDate.isAfter(now);
    }).toList();

    _pastBookings = _allBookings.where((booking) {
      return booking.bookingStatus.toLowerCase() == 'completed' ||
          (booking.endDate.isBefore(now) &&
              booking.bookingStatus.toLowerCase() != 'cancelled' &&
              booking.bookingStatus.toLowerCase() != 'rejected');
    }).toList();

    _cancelledBookings = _allBookings.where((booking) {
      return booking.bookingStatus.toLowerCase() == 'cancelled' ||
             booking.bookingStatus.toLowerCase() == 'rejected';
    }).toList();

    _upcomingBookings.sort((a, b) => a.startDate.compareTo(b.startDate));
    _pastBookings.sort((a, b) => b.endDate.compareTo(a.endDate));
    _cancelledBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _showCancelDialog(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: Text(
            'Are you sure you want to cancel this booking for ${booking.vehicleName}?\n\n'
            'Start Date: ${DateFormat('dd MMM yyyy').format(booking.startDate)}\n'
            'End Date: ${DateFormat('dd MMM yyyy').format(booking.endDate)}\n\n'
            'Note: Cancellation policies may apply.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _cancelBooking(booking.bookingId.toString());
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await _bookingService.cancelBooking(
        bookingId,
        'Cancelled by customer',
      );
      
      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel booking'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Vehicle?> _getVehicleForReview(String vehicleId) async {
    if (_vehicleCache.containsKey(vehicleId)) {
      return _vehicleCache[vehicleId];
    }

    try {
      final vehicle = await _vehicleService.fetchVehicleById(vehicleId);
      
      _vehicleCache[vehicleId] = vehicle;
      
      return vehicle;
    } catch (e) {
      return null;
    }
  }

  Future<void> _writeReview(Booking booking) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      
      final vehicle = await _getVehicleForReview(booking.vehicleId);
      
      if (!mounted) return;
      Navigator.pop(context);

      if (vehicle == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load vehicle details. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubmitReviewPage(
            vehicle: vehicle,
            bookingId: booking.bookingId.toString(),
            userId: widget.userId,
          ),
        ),
      );

      if (result == true) {
        _loadBookings();
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Thank you for your review!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      
      if (!mounted) return;
      Navigator.pop(context);
      
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
      drawer: _currentUser != null ? CustomerDrawer(user: _currentUser!) : null,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => VehicleListingPage(user: _currentUser),
                ),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: 'Upcoming',
              icon: Badge(
                label: Text('${_upcomingBookings.length}'),
                isLabelVisible: _upcomingBookings.isNotEmpty,
                child: const Icon(Icons.upcoming),
              ),
            ),
            Tab(
              text: 'Past',
              icon: Badge(
                label: Text('${_pastBookings.length}'),
                isLabelVisible: _pastBookings.isNotEmpty,
                child: const Icon(Icons.history),
              ),
            ),
            Tab(
              text: 'Cancelled',
              icon: Badge(
                label: Text('${_cancelledBookings.length}'),
                isLabelVisible: _cancelledBookings.isNotEmpty,
                child: const Icon(Icons.cancel),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitFadingCircle(
                color: Color(0xFF1E88E5),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList(_upcomingBookings, 'upcoming'),
                    _buildBookingList(_pastBookings, 'past'),
                    _buildBookingList(_cancelledBookings, 'cancelled'),
                  ],
                ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'upcoming'
                  ? Icons.event_available
                  : type == 'past'
                      ? Icons.history
                      : Icons.cancel_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming'
                  ? 'No upcoming bookings'
                  : type == 'past'
                      ? 'No past bookings'
                      : 'No cancelled bookings',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (type == 'past')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Your completed bookings will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, type);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, String type) {
    final canCancel = type == 'upcoming' &&
        booking.bookingStatus.toLowerCase() != 'cancelled' &&
        booking.startDate.isAfter(DateTime.now().add(const Duration(days: 1)));
    
    final canReview = type == 'past' && 
        booking.bookingStatus.toLowerCase() == 'completed' &&
        !(_reviewStatus[booking.bookingId.toString()] ?? false);
    
    final hasReviewed = type == 'past' && 
        (_reviewStatus[booking.bookingId.toString()] ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
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
                  child: Text(
                    'Booking #${booking.bookingId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.bookingStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.statusDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.vehicleName ?? 'Unknown Vehicle',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.duration} day${booking.duration > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (booking.needDriver) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.drive_eta,
                                size: 14,
                                color: Colors.blue[900],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'With Driver',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(booking.startDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF1E88E5),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Return',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(booking.endDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${booking.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
                if (canCancel)
                  OutlinedButton(
                    onPressed: () => _showCancelDialog(booking),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // ✅ Invoice Section
            if (booking.paymentStatus == 'authorized' || 
                booking.paymentStatus == 'captured') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              InvoiceAccessWidget(
                bookingId: booking.bookingId.toString(),
                isOwner: false, // Customer
              ),
              
              const SizedBox(height: 12),
            ],

            // Review button
            if (canReview) ...[
              const Divider(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _writeReview(booking),
                  icon: const Icon(Icons.rate_review, size: 20),
                  label: const Text(
                    'Write a Review',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],

            if (hasReviewed) ...[
              const Divider(),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Review Submitted',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}