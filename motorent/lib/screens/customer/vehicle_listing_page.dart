// FILE: motorent/lib/screens/customer/vehicle_listing_page.dart
// ✅ ENHANCED: Now properly shows ratings and review counts for each vehicle

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../models/vehicle.dart';
import '../../models/user.dart';
import '../../services/vehicle_service.dart';
import '../../services/auth_service.dart';
import '../../services/review_service.dart'; // ✅ NEW: Import ReviewService
import 'vehicle_detail_page.dart';
import '../../widgets/customer_drawer.dart';

class VehicleListingPage extends StatefulWidget {
  final User? user;

  const VehicleListingPage({Key? key, this.user}) : super(key: key);

  @override
  State<VehicleListingPage> createState() => _VehicleListingPageState();
}

class _VehicleListingPageState extends State<VehicleListingPage> {
  final VehicleService _vehicleService = VehicleService();
  final AuthService _authService = AuthService();
  
  // ✅ NEW: Import ReviewService
  final ReviewService _reviewService = ReviewService();
  
  User? _currentUser;
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  // ✅ NEW: Store actual review data
  Map<String, Map<String, dynamic>> _vehicleReviewData = {};
  
  // Filter variables
  String _selectedBrand = 'All';
  double _minPrice = 0;
  double _maxPrice = 10000;
  String _availabilityFilter = 'available';
  
  // ✅ NEW: Sort option
  String _sortBy = 'rating'; // rating, price_low, price_high, newest
  
  final List<String> _brands = ['All'];
  
  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadVehicles();
  }

  Future<void> _initializeUser() async {
    if (widget.user != null) {
      setState(() {
        _currentUser = widget.user;
      });
    } else {
      try {
        final user = await _authService.getCurrentUser();
        setState(() {
          _currentUser = user;
        });
      } catch (e) {
        print('Error loading user: $e');
      }
    }
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 Loading vehicles from Firebase...');
      
      final vehicles = await _vehicleService.fetchAvailableVehicles();
      
      print('✅ Loaded ${vehicles.length} vehicles');
      
      // ✅ NEW: Load actual review counts for each vehicle
      await _loadReviewCounts(vehicles);
      
      // Extract unique brands
      final brandSet = <String>{'All'};
      for (var vehicle in vehicles) {
        if (vehicle.brand.isNotEmpty) {
          brandSet.add(vehicle.brand);
        }
      }
      
      setState(() {
        _vehicles = vehicles;
        _filteredVehicles = vehicles;
        _brands.clear();
        _brands.addAll(brandSet.toList()..sort());
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      print('❌ Error loading vehicles: $e');
      setState(() {
        _errorMessage = 'Failed to load vehicles: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ NEW: Load actual review counts from Firestore
  Future<void> _loadReviewCounts(List<Vehicle> vehicles) async {
    try {
      final reviewService = ReviewService();
      
      for (var vehicle in vehicles) {
        try {
          // Fetch reviews for this vehicle
          final reviews = await reviewService.fetchVehicleReviews(
            vehicle.vehicleId.toString()
          );
          
          if (reviews.isNotEmpty) {
            // Calculate actual rating
            final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
            final avgRating = totalRating / reviews.length;
            
            // ✅ Update vehicle object with actual data
            // Since Vehicle is immutable, we'll store this in a map
            _vehicleReviewData[vehicle.vehicleId.toString()] = {
              'rating': avgRating,
              'count': reviews.length,
            };
            
            print('   Vehicle ${vehicle.vehicleId}: ${reviews.length} reviews, avg: ${avgRating.toStringAsFixed(1)}');
          }
        } catch (e) {
          print('   ⚠️  Error loading reviews for vehicle ${vehicle.vehicleId}: $e');
        }
      }
      
      print('✅ Loaded review counts for ${_vehicleReviewData.length} vehicles');
    } catch (e) {
      print('❌ Error loading review counts: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredVehicles = _vehicles.where((vehicle) {
        bool brandMatch = _selectedBrand == 'All' || vehicle.brand == _selectedBrand;
        bool priceMatch = vehicle.pricePerDay >= _minPrice && vehicle.pricePerDay <= _maxPrice;
        bool availabilityMatch = _availabilityFilter == 'All' || 
            vehicle.availabilityStatus.toLowerCase() == _availabilityFilter.toLowerCase();
        
        return brandMatch && priceMatch && availabilityMatch;
      }).toList();
      
      // ✅ Apply sorting
      _sortVehicles();
    });
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // ✅ NEW: Sort vehicles using actual review data
  void _sortVehicles() {
    switch (_sortBy) {
      case 'rating':
        _filteredVehicles.sort((a, b) {
          // Get actual ratings from loaded data
          final aData = _vehicleReviewData[a.vehicleId.toString()];
          final bData = _vehicleReviewData[b.vehicleId.toString()];
          
          final aRating = aData?['rating'] as double?;
          final bRating = bData?['rating'] as double?;
          
          // Vehicles with ratings first, then by rating descending
          if (aRating == null && bRating == null) return 0;
          if (aRating == null) return 1;
          if (bRating == null) return -1;
          return bRating.compareTo(aRating);
        });
        break;
      case 'price_low':
        _filteredVehicles.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
        break;
      case 'price_high':
        _filteredVehicles.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
        break;
      case 'newest':
        _filteredVehicles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'popular':
        _filteredVehicles.sort((a, b) {
          // Sort by actual review count
          final aData = _vehicleReviewData[a.vehicleId.toString()];
          final bData = _vehicleReviewData[b.vehicleId.toString()];
          
          final aCount = aData?['count'] as int? ?? 0;
          final bCount = bData?['count'] as int? ?? 0;
          return bCount.compareTo(aCount);
        });
        break;
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedBrand = 'All';
      _minPrice = 0;
      _maxPrice = 10000;
      _availabilityFilter = 'available';
      _sortBy = 'rating';
      _filteredVehicles = _vehicles.where((v) => v.isAvailable).toList();
      _sortVehicles();
    });
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter & Sort',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // ✅ NEW: Sort By Section
                    const Text(
                      'Sort By',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSortChip('Highest Rated', 'rating', setModalState),
                        _buildSortChip('Lowest Price', 'price_low', setModalState),
                        _buildSortChip('Highest Price', 'price_high', setModalState),
                        _buildSortChip('Most Popular', 'popular', setModalState),
                        _buildSortChip('Newest', 'newest', setModalState),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Brand',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedBrand,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                      ),
                      items: _brands.map((String brand) {
                        return DropdownMenuItem<String>(
                          value: brand,
                          child: Text(brand),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          _selectedBrand = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Price Range (per day)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    RangeSlider(
                      values: RangeValues(_minPrice, _maxPrice),
                      min: 0,
                      max: 10000,
                      divisions: 100,
                      labels: RangeLabels(
                        'RM ${_minPrice.round()}',
                        'RM ${_maxPrice.round()}',
                      ),
                      onChanged: (RangeValues values) {
                        setModalState(() {
                          _minPrice = values.start;
                          _maxPrice = values.end;
                        });
                      },
                    ),
                    Text(
                      'RM ${_minPrice.round()} - RM ${_maxPrice.round()}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Availability',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'All', label: Text('All')),
                        ButtonSegment(value: 'available', label: Text('Available')),
                        ButtonSegment(value: 'unavailable', label: Text('Unavailable')),
                      ],
                      selected: {_availabilityFilter},
                      onSelectionChanged: (Set<String> newSelection) {
                        setModalState(() {
                          _availabilityFilter = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetFilters,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ✅ NEW: Build sort chip
  Widget _buildSortChip(String label, String value, StateSetter setModalState) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setModalState(() {
          _sortBy = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF1E88E5).withOpacity(0.2),
      checkmarkColor: const Color(0xFF1E88E5),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1E88E5) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _currentUser != null ? CustomerDrawer(user: _currentUser!) : null,
      appBar: AppBar(
        title: const Text(
          'Browse Vehicles',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: _currentUser != null,
        actions: [
          // ✅ Show current sort
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _getSortLabel(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter & Sort',
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
                        onPressed: _loadVehicles,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _filteredVehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No vehicles found',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _resetFilters,
                            child: const Text('Clear Filters'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // ✅ Results summary
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: Colors.grey[100],
                          child: Text(
                            '${_filteredVehicles.length} vehicle${_filteredVehicles.length != 1 ? 's' : ''} found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadVehicles,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredVehicles.length,
                              itemBuilder: (context, index) {
                                final vehicle = _filteredVehicles[index];
                                return _buildVehicleCard(vehicle);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'rating':
        return 'Top Rated';
      case 'price_low':
        return 'Price: Low';
      case 'price_high':
        return 'Price: High';
      case 'newest':
        return 'Newest';
      case 'popular':
        return 'Popular';
      default:
        return '';
    }
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    // ✅ ENHANCED: Get actual review data
    final reviewData = _vehicleReviewData[vehicle.vehicleId.toString()];
    final actualRating = reviewData?['rating'] as double?;
    final actualCount = reviewData?['count'] as int? ?? 0;
    
    final hasRating = actualRating != null && actualRating > 0;
    final reviewCount = actualCount;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailPage(
                vehicle: vehicle,
                userId: _currentUser?.userIdString ?? '1',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: vehicle.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.directions_car,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  
                  // Availability badge (top right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: vehicle.isAvailable ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        vehicle.isAvailable ? 'Available' : 'Unavailable',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // ✅ NEW: Rating badge (top left)
                  if (hasRating)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              actualRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle name
                  Text(
                    vehicle.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Owner
                  Row(
                    children: [
                      const Icon(
                        Icons.store,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        vehicle.ownerName ?? 'Unknown Owner',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // ✅ ENHANCED: Rating display with review count
                  if (hasRating)
                    Container(
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
                          ...List.generate(5, (index) {
                            if (index < actualRating!.floor()) {
                              return const Icon(
                                Icons.star,
                                size: 18,
                                color: Colors.amber,
                              );
                            } else if (index == actualRating.floor() &&
                                actualRating % 1 >= 0.5) {
                              return const Icon(
                                Icons.star_half,
                                size: 18,
                                color: Colors.amber,
                              );
                            } else {
                              return Icon(
                                Icons.star_border,
                                size: 18,
                                color: Colors.grey[400],
                              );
                            }
                          }),
                          const SizedBox(width: 8),
                          Text(
                            actualRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // No reviews yet
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
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RM ${vehicle.pricePerDay.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
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
                      
                      // ✅ View Details button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VehicleDetailPage(
                                vehicle: vehicle,
                                userId: _currentUser?.userIdString ?? '1',
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E88E5),
                          side: const BorderSide(color: Color(0xFF1E88E5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}