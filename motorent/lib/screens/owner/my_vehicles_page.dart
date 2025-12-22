// FILE: motorent/lib/screens/owner/my_vehicles_page.dart
// UPDATED VERSION - Replace your current file

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/vehicle.dart';
import '/services/firebase_vehicle_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/review_service.dart'; 
import 'package:motorent/services/vehicle_service.dart';

class MyVehiclesPage extends StatefulWidget {
  final dynamic ownerId; // Can accept int or String

  const MyVehiclesPage({
    Key? key,
    required this.ownerId,
  }) : super(key: key);

  @override
  State<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends State<MyVehiclesPage> {
  final FirebaseVehicleService _vehicleService = FirebaseVehicleService();
  final ReviewService _reviewService = ReviewService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  String _errorMessage = '';

  Map<String, Map<String, dynamic>> _vehicleReviewData = {};
  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      print('🔍 Loading vehicles for owner: ${currentUser.uid}');

      // SIMPLIFIED QUERY - No complex filters
      final querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('owner_id', isEqualTo: currentUser.uid)
          .get();

      print('📦 Raw query returned: ${querySnapshot.docs.length} documents');

      // Filter out deleted vehicles in code instead of query
      final vehicles = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            final isDeleted = data['is_deleted'] ?? false;
            return !isDeleted;
          })
          .map((doc) {
            final data = doc.data();
            data['vehicle_id'] = doc.id;
            
            // Handle Timestamp conversion
            if (data['created_at'] is Timestamp) {
              data['created_at'] = (data['created_at'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            }
            
            return Vehicle.fromJson(data);
          })
          .toList();

      print('✅ Filtered to ${vehicles.length} non-deleted vehicles');
      
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading vehicles: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        _errorMessage = 'Failed to load vehicles: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability(Vehicle vehicle) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final newStatus = vehicle.isAvailable ? 'unavailable' : 'available';
    
    print('🔄 Toggling availability to: $newStatus');

    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicle.vehicleId.toString())
        .update({
      'availability_status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
    });

    print('✅ Status updated successfully');

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vehicle.isAvailable
              ? 'Vehicle marked as unavailable'
              : 'Vehicle marked as available',
        ),
        backgroundColor: Colors.green,
      ),
    );

    _loadVehicles(); // Reload the list

  } catch (e) {
    print('❌ Error updating status: $e');

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to update status: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _showDeleteDialog(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Vehicle'),
          content: Text(
            'Are you sure you want to delete ${vehicle.fullName}?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteVehicle(vehicle);
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    print('🗑️ Deleting vehicle: ${vehicle.vehicleId}');

    // Soft delete - just mark as deleted
    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicle.vehicleId.toString())
        .update({
      'is_deleted': true,
      'availability_status': 'unavailable',
      'updated_at': FieldValue.serverTimestamp(),
    });

    print('✅ Vehicle deleted successfully');

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehicle deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );

    _loadVehicles(); // Reload the list

  } catch (e) {
    print('❌ Error deleting vehicle: $e');

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to delete vehicle: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showVehicleOptions(Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicle.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
                  title: const Text('Edit Details'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit feature coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    vehicle.isAvailable ? Icons.visibility_off : Icons.visibility,
                    color: Colors.orange,
                  ),
                  title: Text(
                    vehicle.isAvailable ? 'Mark as Unavailable' : 'Mark as Available',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleAvailability(vehicle);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.green),
                  title: const Text('View Statistics'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Statistics feature coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Vehicle'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteDialog(vehicle);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
              : _vehicles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.garage,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No vehicles listed yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first vehicle to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVehicles,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _vehicles[index];
                          return _buildVehicleCard(vehicle);
                        },
                      ),
                    ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: CachedNetworkImage(
                  imageUrl: vehicle.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.directions_car,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
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
            ],
          ),

          // Vehicle Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        vehicle.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showVehicleOptions(vehicle),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      vehicle.licensePlate,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Rating
                if (vehicle.rating != null && vehicle.rating! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          vehicle.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${vehicle.reviewCount ?? 0} reviews)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
                    ElevatedButton.icon(
                      onPressed: () => _showVehicleOptions(vehicle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.settings, color: Colors.white, size: 18),
                      label: const Text(
                        'Manage',
                        style: TextStyle(color: Colors.white),
                      ),
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
}