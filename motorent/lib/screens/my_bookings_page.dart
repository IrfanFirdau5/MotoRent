import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/review_service.dart';
import 'add_review_page.dart';

class MyBookingsPage extends StatefulWidget {
  final int userId;

  const MyBookingsPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final ReviewService _reviewService = ReviewService();
  late TabController _tabController;

  List<Booking> _allBookings = [];
  List<Booking> _upcomingBookings = [];
  List<Booking> _pastBookings = [];
  List<Booking> _cancelledBookings = [];
  Map<int, bool> _reviewedBookings = {}; // Track which bookings have reviews

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
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
      final bookings = await _bookingService.mockFetchUserBookings(widget.userId);

      // Check which bookings have been reviewed
      for (var booking in bookings) {
        final hasReviewed = await _reviewService.mockHasUserReviewed(booking.bookingId);
        _reviewedBookings[booking.bookingId] = hasReviewed;
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
              booking.bookingStatus.toLowerCase() != 'cancelled');
    }).toList();

    _cancelledBookings = _allBookings.where((booking) {
      return booking.bookingStatus.toLowerCase() == 'cancelled';
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
            'End Date: ${DateFormat('dd MMM yyyy').format(booking.endDate)}',
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
      _cancelBooking(booking.bookingId);
    }
  }

  Future<void> _cancelBooking(int bookingId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await _bookingService.mockCancelBooking(bookingId);

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
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

  Future<void> _navigateToAddReview(Booking booking) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewPage(
          booking: booking,
          userId: widget.userId,
        ),
      ),
    );

    if (result == true) {
      // Review was submitted, refresh the list
      _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
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
        booking.startDate.isAfter(DateTime.now().add(const Duration(days: 1)));
    
    final canReview = type == 'past' && 
        (_reviewedBookings[booking.bookingId] == false);

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
                Text(
                  'Booking #${booking.bookingId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                      'Cancel Booking',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            // Add Review Button for completed bookings
            if (canReview) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAddReview(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: const Text(
                    'Write a Review',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            // Show "Reviewed" badge if already reviewed
            if (type == 'past' && _reviewedBookings[booking.bookingId] == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}