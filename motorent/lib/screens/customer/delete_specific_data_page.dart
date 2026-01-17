// FILE: motorent/lib/screens/customer/delete_specific_data_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeleteSpecificDataPage extends StatefulWidget {
  final String userId;

  const DeleteSpecificDataPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<DeleteSpecificDataPage> createState() => _DeleteSpecificDataPageState();
}

class _DeleteSpecificDataPageState extends State<DeleteSpecificDataPage> {
  final Map<String, bool> _selectedCategories = {};
  bool _isDeleting = false;

  // Mock data categories with details
  final List<Map<String, dynamic>> _dataCategories = [
    {
      'id': 'profile_photos',
      'title': 'Profile Photos',
      'description': 'Delete your uploaded profile pictures',
      'icon': Icons.photo_camera,
      'color': Colors.blue,
      'itemCount': 3,
      'size': '2.4 MB',
      'canDelete': true,
      'items': [
        'Profile_Photo_2024.jpg (1.2 MB)',
        'Profile_Photo_2023.jpg (800 KB)',
        'Avatar_Image.png (400 KB)',
      ],
    },
    {
      'id': 'search_history',
      'title': 'Search History',
      'description': 'Clear your vehicle search history',
      'icon': Icons.history,
      'color': Colors.orange,
      'itemCount': 47,
      'size': '124 KB',
      'canDelete': true,
      'items': [
        'Toyota Vios rental in Kuching',
        'Honda Civic near me',
        'SUV rental Sarawak',
        '...and 44 more searches',
      ],
    },
    {
      'id': 'location_history',
      'title': 'Location History',
      'description': 'Remove saved locations and search areas',
      'icon': Icons.location_on,
      'color': Colors.red,
      'itemCount': 12,
      'size': '56 KB',
      'canDelete': true,
      'items': [
        'Kuching City Center',
        'Kuching International Airport',
        'Vivacity Megamall',
        '...and 9 more locations',
      ],
    },
    {
      'id': 'saved_preferences',
      'title': 'Saved Preferences',
      'description': 'Reset your app preferences and settings',
      'icon': Icons.settings,
      'color': Colors.purple,
      'itemCount': 8,
      'size': '12 KB',
      'canDelete': true,
      'items': [
        'Preferred vehicle types',
        'Price range filters',
        'Notification settings',
        'Display preferences',
        'Language settings',
      ],
    },
    {
      'id': 'messages',
      'title': 'Messages & Chats',
      'description': 'Delete conversations with vehicle owners',
      'icon': Icons.chat,
      'color': Colors.green,
      'itemCount': 15,
      'size': '340 KB',
      'canDelete': true,
      'items': [
        'Chat with Ahmad Legacy (5 messages)',
        'Chat with Strana Sdn. Bhd. (8 messages)',
        'Chat with Fareast Trip (2 messages)',
      ],
    },
    {
      'id': 'reviews',
      'title': 'My Reviews',
      'description': 'Remove reviews you\'ve written',
      'icon': Icons.rate_review,
      'color': Colors.amber,
      'itemCount': 6,
      'size': '84 KB',
      'canDelete': true,
      'items': [
        'Review: Toyota Vios - 5 stars',
        'Review: Honda Civic - 4 stars',
        'Review: Perodua Axia - 5 stars',
        '...and 3 more reviews',
      ],
    },
    {
      'id': 'device_info',
      'title': 'Device Information',
      'description': 'Remove logged device details',
      'icon': Icons.devices,
      'color': Colors.indigo,
      'itemCount': 2,
      'size': '8 KB',
      'canDelete': true,
      'items': [
        'Samsung Galaxy S21 (Android 13)',
        'Xiaomi Redmi Note 10 (Android 12)',
      ],
    },
    {
      'id': 'payment_methods',
      'title': 'Saved Payment Methods',
      'description': 'Delete saved credit/debit cards',
      'icon': Icons.credit_card,
      'color': Colors.teal,
      'itemCount': 2,
      'size': '4 KB',
      'canDelete': true,
      'items': [
        'Visa •••• 4532',
        'Mastercard •••• 8901',
      ],
    },
    {
      'id': 'completed_rentals',
      'title': 'Completed Rental History',
      'description': 'Old rental records (30+ days)',
      'icon': Icons.calendar_month,
      'color': Colors.brown,
      'itemCount': 8,
      'size': '156 KB',
      'canDelete': true,
      'items': [
        'Rental: Toyota Vios (Jan 2025)',
        'Rental: Honda Civic (Dec 2024)',
        'Rental: Perodua Axia (Nov 2024)',
        '...and 5 more rentals',
      ],
    },
    {
      'id': 'transaction_records',
      'title': 'Transaction Records',
      'description': 'Payment receipts and invoices',
      'icon': Icons.receipt_long,
      'color': Colors.red,
      'itemCount': 12,
      'size': '892 KB',
      'canDelete': false,
      'retention': '7 years',
      'reason': 'Required by tax law (LHDN)',
      'items': [
        'Invoice #INV-2025-001 (RM 450.00)',
        'Invoice #INV-2024-089 (RM 320.00)',
        'Receipt #RCP-2024-156 (RM 180.00)',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize all to unchecked
    for (var category in _dataCategories) {
      _selectedCategories[category['id']] = false;
    }
  }

  int get _selectedCount {
    return _selectedCategories.values.where((selected) => selected).length;
  }

  String get _totalSize {
    double totalBytes = 0;
    _dataCategories.forEach((category) {
      if (_selectedCategories[category['id']] == true &&
          category['canDelete']) {
        final sizeStr = category['size'] as String;
        if (sizeStr.contains('MB')) {
          totalBytes += double.parse(sizeStr.replaceAll(' MB', '')) * 1024;
        } else if (sizeStr.contains('KB')) {
          totalBytes += double.parse(sizeStr.replaceAll(' KB', ''));
        }
      }
    });

    if (totalBytes >= 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} MB';
    } else {
      return '${totalBytes.toStringAsFixed(0)} KB';
    }
  }

  Future<void> _deleteSelectedData() async {
    final selectedItems = _dataCategories
        .where(
            (cat) => _selectedCategories[cat['id']] == true && cat['canDelete'])
        .toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category to delete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to permanently delete:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedCount categories',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total size: $_totalSize',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. Are you sure?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
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
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    // Simulate deletion
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
      // Reset selections
      _selectedCategories.updateAll((key, value) => false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Selected data deleted successfully'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delete Specific Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[900]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selective Data Deletion',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose specific categories of data to delete. Some data cannot be deleted due to legal requirements.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selection summary
          if (_selectedCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_box, color: Colors.orange[900]),
                      const SizedBox(width: 12),
                      Text(
                        '$_selectedCount selected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Total: $_totalSize',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                ],
              ),
            ),

          // Data categories list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _dataCategories.length,
              itemBuilder: (context, index) {
                final category = _dataCategories[index];
                return _buildCategoryCard(category);
              },
            ),
          ),

          // Delete button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _selectedCount > 0 && !_isDeleting
                    ? _deleteSelectedData
                    : null,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.delete_forever),
                label: Text(
                  _isDeleting
                      ? 'Deleting...'
                      : 'Delete Selected ($_selectedCount)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final isSelected = _selectedCategories[category['id']] ?? false;
    final canDelete = category['canDelete'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? (category['color'] as Color) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: canDelete
              ? Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategories[category['id']] = value ?? false;
                    });
                  },
                  activeColor: category['color'] as Color,
                )
              : Icon(
                  Icons.lock,
                  color: Colors.grey[400],
                ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: category['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['title'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!canDelete)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Cannot Delete',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 52, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.folder,
                      '${category['itemCount']} items',
                      Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.storage,
                      category['size'],
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            if (!canDelete)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel, size: 16, color: Colors.orange[900]),
                        const SizedBox(width: 8),
                        Text(
                          'Legal Retention Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Retention Period: ${category['retention']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${category['reason']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 16,
                          color: category['color'] as Color,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Items to be deleted:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(category['items'] as List<String>).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fiber_manual_record,
                              size: 8,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
