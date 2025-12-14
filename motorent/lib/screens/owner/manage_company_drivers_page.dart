import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'add_company_driver_page.dart';
import '/services/firebase_company_driver_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCompanyDriversPage extends StatefulWidget {
  final int ownerId;
  
  ManageCompanyDriversPage({
    Key? key,
    required this.ownerId,
  }) : super(key: key);

  @override
  State<ManageCompanyDriversPage> createState() => _ManageCompanyDriversPageState();
}

class _ManageCompanyDriversPageState extends State<ManageCompanyDriversPage> {
  final _driverService = FirebaseCompanyDriverService();
  bool _isLoading = true;
  List<CompanyDriver> _drivers = [];
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      print('🔍 Loading company drivers for owner: ${currentUser.uid}');

      // SIMPLIFIED QUERY - Just owner_id, no ordering
      final querySnapshot = await FirebaseFirestore.instance
          .collection('company_drivers')
          .where('owner_id', isEqualTo: currentUser.uid)
          .get();

      print('📦 Query returned: ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isEmpty) {
        print('ℹ️  No company drivers found');
        setState(() {
          _drivers = [];
          _isLoading = false;
        });
        return;
      }

      // Convert to driver objects
      final drivers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return CompanyDriver(
          driverId: doc.id,
          ownerId: data['owner_id'] ?? '',
          userId: data['user_id'],
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          licenseNumber: data['license_number'] ?? '',
          address: data['address'] ?? '',
          status: data['status'] ?? 'available',
          isActive: data['is_active'] ?? true,
          totalJobs: data['total_jobs'] ?? 0,
          rating: data['rating']?.toDouble(),
          createdAt: data['created_at'] is Timestamp
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.now(),
          updatedAt: data['updated_at'] is Timestamp
              ? (data['updated_at'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();

      // Sort in code instead of query
      drivers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Loaded ${drivers.length} company drivers');
      
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading company drivers: $e');
      print('Stack trace: $stackTrace');
      
      setState(() {
        _errorMessage = 'Failed to load drivers: $e';
        _isLoading = false;
        _drivers = []; // Show empty instead of error
      });
    }
  }

 Future<void> _toggleDriverStatus(CompanyDriver driver) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final newStatus = !driver.isActive;
    
    print('🔄 Toggling driver active status to: $newStatus');

    await FirebaseFirestore.instance
        .collection('company_drivers')
        .doc(driver.driverId)
        .update({
      'is_active': newStatus,
      'status': newStatus ? 'available' : 'offline',
      'updated_at': FieldValue.serverTimestamp(),
    });

    print('✅ Driver status updated successfully');

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          driver.isActive ? 'Driver deactivated' : 'Driver activated',
        ),
        backgroundColor: Colors.green,
      ),
    );

    _loadDrivers(); // Reload the list

  } catch (e) {
    print('❌ Error updating driver status: $e');

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to update driver status: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _showDeleteDialog(CompanyDriver driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Driver'),
        content: Text(
          'Are you sure you want to remove ${driver.name} from your company drivers?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteDriver(driver);
    }
  }

  Future<void> _deleteDriver(CompanyDriver driver) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    print('🗑️ Deleting driver: ${driver.driverId}');

    // Hard delete for drivers
    await FirebaseFirestore.instance
        .collection('company_drivers')
        .doc(driver.driverId)
        .delete();

    print('✅ Driver deleted successfully');

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Driver deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );

    _loadDrivers(); // Reload the list

  } catch (e) {
    print('❌ Error deleting driver: $e');

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to delete driver: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showDriverOptions(CompanyDriver driver) {
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
                  driver.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(
                    driver.isActive ? Icons.pause_circle : Icons.play_circle,
                    color: driver.isActive ? Colors.orange : Colors.green,
                  ),
                  title: Text(
                    driver.isActive ? 'Deactivate Driver' : 'Activate Driver',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleDriverStatus(driver);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.blue),
                  title: const Text('View Performance'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Performance details coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Driver'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteDialog(driver);
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
        title: const Text('My Drivers'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrivers,
            tooltip: 'Refresh',
          ),
        ],
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
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDrivers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _drivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No company drivers yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first driver to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddCompanyDriverPage(
                                    ownerId: widget.ownerId,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadDrivers();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Driver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDrivers,
                      child: Column(
                        children: [
                          // Summary Card
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  'Total Drivers',
                                  _drivers.length.toString(),
                                  Icons.people,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                _buildSummaryItem(
                                  'Available',
                                  _drivers.where((d) => d.status == 'available').length.toString(),
                                  Icons.check_circle,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                _buildSummaryItem(
                                  'On Job',
                                  _drivers.where((d) => d.status == 'on_job').length.toString(),
                                  Icons.drive_eta,
                                ),
                              ],
                            ),
                          ),
                          // Drivers List
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _drivers.length,
                              itemBuilder: (context, index) {
                                final driver = _drivers[index];
                                return _buildDriverCard(driver);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: _drivers.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCompanyDriverPage(
                      ownerId: widget.ownerId,
                    ),
                  ),
                );
                if (result == true) {
                  _loadDrivers();
                }
              },
              backgroundColor: const Color(0xFF1E88E5),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Driver',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(CompanyDriver driver) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _showDriverOptions(driver),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
                    child: Text(
                      driver.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          driver.licenseNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(driver.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(driver.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!driver.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'INACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          driver.phone,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            driver.email,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    'Total Jobs',
                    driver.totalJobs.toString(),
                    Icons.work_outline,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  _buildMetric(
                    'Rating',
                    (driver.rating ?? 0.0).toStringAsFixed(1),
                    Icons.star,
                    valueColor: Colors.amber,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: valueColor ?? const Color(0xFF1E88E5)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'on_job':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'AVAILABLE';
      case 'on_job':
        return 'ON JOB';
      case 'offline':
        return 'OFFLINE';
      default:
        return status.toUpperCase();
    }
  }
}
