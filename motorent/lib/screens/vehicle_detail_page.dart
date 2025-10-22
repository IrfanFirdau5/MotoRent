import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import 'booking_page.dart';

class VehicleDetailPage extends StatefulWidget {
  final Vehicle vehicle;
  final int? userId;

  const VehicleDetailPage({
    Key? key,
    required this.vehicle,
    this.userId,
  }) : super(key: key);

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _reviewService.mockFetchVehicleReviews(widget.vehicle.vehicleId);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  void _navigateToBooking(BuildContext context) {
    if (widget.userId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('Please login to book this vehicle.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(
          vehicle: widget.vehicle,
          userId: widget.userId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1E88E5),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.vehicle.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.directions_car,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.vehicle.fullName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.vehicle.isAvailable
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.vehicle.isAvailable ? 'Available' : 'Unavailable',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (widget.vehicle.rating != null)
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          if (index < widget.vehicle.rating!.floor()) {
                            return const Icon(Icons.star, size: 20, color: Colors.amber);
                          } else if (index == widget.vehicle.rating!.floor() &&
                              widget.vehicle.rating! % 1 >= 0.5) {
                            return const Icon(Icons.star_half, size: 20, color: Colors.amber);
                          } else {
                            return Icon(Icons.star_border, size: 20, color: Colors.grey[400]);
                          }
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.vehicle.rating!.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' (${widget.vehicle.reviewCount ?? 0} reviews)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF1E88E5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Rental Price',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'RM ${widget.vehicle.pricePerDay.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        const Text(
                          'per day',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Vehicle Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow(Icons.directions_car, 'Brand', widget.vehicle.brand),
                  _buildInfoRow(Icons.car_rental, 'Model', widget.vehicle.model),
                  _buildInfoRow(Icons.confirmation_number, 'License Plate',
                      widget.vehicle.licensePlate),
                  _buildInfoRow(Icons.store, 'Owner', widget.vehicle.ownerName ?? 'Unknown'),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Listed Since',
                    DateFormat('dd MMM yyyy').format(widget.vehicle.createdAt),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.vehicle.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Customer Reviews',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_reviews.isNotEmpty)
                        Text(
                          '${_reviews.length} review${_reviews.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  if (_isLoadingReviews)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No reviews yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to review this vehicle',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._reviews.take(3).map((review) => _buildReviewCard(review)).toList(),
                  
                  if (_reviews.length > 3) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          _showAllReviews();
                        },
                        child: Text(
                          'See all ${_reviews.length} reviews',
                          style: const TextStyle(
                            color: Color(0xFF1E88E5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: widget.vehicle.isAvailable
                          ? () => _navigateToBooking(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        widget.vehicle.isAvailable ? 'Book Now' : 'Currently Unavailable',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: const Color(0xFF1E88E5),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
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
                  backgroundColor: const Color(0xFF1E88E5),
                  child: Text(
                    review.userName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
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
                        review.userName ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            if (index < review.rating.floor()) {
                              return const Icon(Icons.star, size: 16, color: Colors.amber);
                            } else if (index == review.rating.floor() &&
                                review.rating % 1 >= 0.5) {
                              return const Icon(Icons.star_half, size: 16, color: Colors.amber);
                            } else {
                              return Icon(Icons.star_border, size: 16, color: Colors.grey[400]);
                            }
                          }),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy').format(review.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Reviews',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      return _buildReviewCard(_reviews[index]);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}