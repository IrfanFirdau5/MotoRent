// FILE: motorent/lib/screens/customer/vehicle_detail_page.dart
// ✅ FIXED: Reviews now show correctly even if vehicle.rating is null

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:motorent/models/vehicle.dart';
import 'view_reviews_page.dart';
import 'booking_page.dart';
import 'license_verification_page.dart';
import '../../models/user.dart';
import '../../models/review.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart';

class VehicleDetailPage extends StatefulWidget {
  final Vehicle vehicle;
  final String userId;

  const VehicleDetailPage({
    Key? key,
    required this.vehicle,
    required this.userId,
  }) : super(key: key);

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final ReviewService _reviewService = ReviewService();
  List<Review> _recentReviews = [];
  bool _loadingReviews = true; // ✅ Changed to true initially
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  double? _actualAverageRating; // ✅ Track actual rating from reviews
  int _totalReviewCount = 0; // ✅ Track actual count

  @override
  void initState() {
    super.initState();
    _loadRecentReviews();
  }

  Future<void> _loadRecentReviews() async {
    setState(() {
      _loadingReviews = true;
    });

    try {
      print('🔍 Loading reviews for vehicle: ${widget.vehicle.vehicleId}');
      
      // Fetch all reviews
      final allReviews = await _reviewService.fetchVehicleReviews(
        widget.vehicle.vehicleId.toString()
      );
      
      print('✅ Found ${allReviews.length} reviews');
      
      // Calculate rating distribution
      Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      double totalRating = 0;
      
      for (var review in allReviews) {
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
        totalRating += review.rating;
      }
      
      // Calculate average
      double? avgRating;
      if (allReviews.isNotEmpty) {
        avgRating = totalRating / allReviews.length;
      }
      
      setState(() {
        _recentReviews = allReviews.take(3).toList(); // Show only 3 recent
        _ratingDistribution = distribution;
        _actualAverageRating = avgRating;
        _totalReviewCount = allReviews.length;
        _loadingReviews = false;
      });
      
      print('✅ Loaded ${allReviews.length} reviews (showing ${_recentReviews.length})');
      print('   Average rating: ${avgRating?.toStringAsFixed(1) ?? "N/A"}');
    } catch (e) {
      print('❌ Error loading reviews: $e');
      setState(() {
        _loadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Use actual loaded data instead of vehicle data
    final hasReviews = _totalReviewCount > 0;
    final displayRating = _actualAverageRating ?? widget.vehicle.rating ?? 0.0;
    final reviewCount = _totalReviewCount;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
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

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Availability Badge
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
                          color: widget.vehicle.isAvailable ? Colors.green : Colors.red,
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

                  // ✅ ENHANCED: Rating with "View All" link
                  if (_loadingReviews)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loading reviews...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (hasReviews)
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewReviewsPage(
                              vehicle: widget.vehicle,
                              currentUserId: widget.userId,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 20,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              displayRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'No reviews yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Price Card
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

                  // ✅ FIXED: Reviews Section - Show if we actually have reviews
                  if (hasReviews && !_loadingReviews) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reviews & Ratings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewReviewsPage(
                                  vehicle: widget.vehicle,
                                  currentUserId: widget.userId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('View All'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rating Summary Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewReviewsPage(
                                vehicle: widget.vehicle,
                                currentUserId: widget.userId,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Average Rating
                              Column(
                                children: [
                                  Text(
                                    displayRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E88E5),
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < displayRating.round()
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 20,
                                        color: Colors.amber,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              
                              // Rating Distribution
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildMiniRatingBar(5, _ratingDistribution[5] ?? 0, reviewCount),
                                    _buildMiniRatingBar(4, _ratingDistribution[4] ?? 0, reviewCount),
                                    _buildMiniRatingBar(3, _ratingDistribution[3] ?? 0, reviewCount),
                                    _buildMiniRatingBar(2, _ratingDistribution[2] ?? 0, reviewCount),
                                    _buildMiniRatingBar(1, _ratingDistribution[1] ?? 0, reviewCount),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recent Reviews Preview
                    if (_recentReviews.isNotEmpty) ...[
                      const Text(
                        'Recent Reviews',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._recentReviews.map((review) => _buildReviewPreview(review)),
                      
                      // View All Button
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewReviewsPage(
                                  vehicle: widget.vehicle,
                                  currentUserId: widget.userId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review),
                          label: Text('View All $reviewCount Reviews'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E88E5),
                            side: const BorderSide(color: Color(0xFF1E88E5)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 25),
                  ],

                  // Vehicle Information Section
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
                  _buildInfoRow(Icons.confirmation_number, 'License Plate', widget.vehicle.licensePlate),
                  _buildInfoRow(Icons.store, 'Owner', widget.vehicle.ownerName ?? 'Unknown'),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Listed Since',
                    DateFormat('dd MMM yyyy').format(widget.vehicle.createdAt),
                  ),

                  const SizedBox(height: 25),

                  // Description Section
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

                  // Book Now Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: widget.vehicle.isAvailable
                          ? () async {
                              final currentUser = await AuthService().getCurrentUser();
                              
                              if (currentUser == null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please login to book a vehicle'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              if (!currentUser.isLicenseVerified) {
                                if (!context.mounted) return;
                                
                                final shouldVerify = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Row(
                                      children: [
                                        Icon(Icons.verified_user, color: Color(0xFF1E88E5), size: 28),
                                        SizedBox(width: 12),
                                        Text('License Verification Required'),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'To book vehicles on MotoRent, you need to verify your driving license first.',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.info_outline, color: Colors.blue[900], size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'This is a one-time verification process that takes 24-48 hours.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue[900],
                                                  ),
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
                                        child: const Text('Later'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E88E5),
                                        ),
                                        child: const Text(
                                          'Verify Now',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldVerify == true) {
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LicenseVerificationPage(
                                        user: currentUser,
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(
                                    vehicle: widget.vehicle,
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            }
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

  // ✅ Mini rating bar for summary
  Widget _buildMiniRatingBar(int stars, int count, int total) {
    double percentage = total > 0 ? count / total : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star, size: 10, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 4,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1E88E5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Review preview card
  Widget _buildReviewPreview(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              size: 14,
                              color: index < review.rating ? Colors.amber : Colors.grey,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(review.createdAt),
                            style: TextStyle(
                              fontSize: 11,
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
            const SizedBox(height: 10),
            Text(
              review.comment,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ],
        ),
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
}