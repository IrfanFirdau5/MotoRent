// FILE: motorent/lib/screens/customer/recent_data_access_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentDataAccessPage extends StatefulWidget {
  final String userId;
  
  const RecentDataAccessPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<RecentDataAccessPage> createState() => _RecentDataAccessPageState();
}

class _RecentDataAccessPageState extends State<RecentDataAccessPage> {
  String _filterPeriod = 'all'; // all, today, week, month
  
  // Mock data access logs
  final List<DataAccessLog> _mockLogs = [
    DataAccessLog(
      accessor: 'You',
      action: 'Viewed profile',
      dataAccessed: 'Personal Information',
      purpose: 'Profile review',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      accessType: AccessType.self,
      ipAddress: '103.106.xxx.xxx',
      device: 'Samsung Galaxy S23',
    ),
    DataAccessLog(
      accessor: 'MotoRent System',
      action: 'Read booking data',
      dataAccessed: 'Rental History, Payment Info',
      purpose: 'Display bookings dashboard',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      accessType: AccessType.system,
      ipAddress: 'Internal',
      device: 'Server',
    ),
    DataAccessLog(
      accessor: 'Ahmad Legacy (Vehicle Owner)',
      action: 'Viewed contact details',
      dataAccessed: 'Name, Phone Number',
      purpose: 'Active rental coordination',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      accessType: AccessType.vehicleOwner,
      ipAddress: '101.50.xxx.xxx',
      device: 'iPhone 14',
    ),
    DataAccessLog(
      accessor: 'Payment Gateway (iPay88)',
      action: 'Processed payment',
      dataAccessed: 'Payment Method, Amount',
      purpose: 'Transaction processing',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      accessType: AccessType.thirdParty,
      ipAddress: '203.124.xxx.xxx',
      device: 'API Server',
    ),
    DataAccessLog(
      accessor: 'You',
      action: 'Updated preferences',
      dataAccessed: 'Notification Settings',
      purpose: 'Settings modification',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      accessType: AccessType.self,
      ipAddress: '103.106.xxx.xxx',
      device: 'Samsung Galaxy S23',
    ),
    DataAccessLog(
      accessor: 'MotoRent Admin',
      action: 'Verified license',
      dataAccessed: 'Driver License Information',
      purpose: 'License verification process',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      accessType: AccessType.admin,
      ipAddress: 'Internal',
      device: 'Admin Dashboard',
    ),
    DataAccessLog(
      accessor: 'Email Service (SendGrid)',
      action: 'Sent email',
      dataAccessed: 'Email Address, Name',
      purpose: 'Booking confirmation email',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      accessType: AccessType.thirdParty,
      ipAddress: '168.245.xxx.xxx',
      device: 'Email Server',
    ),
    DataAccessLog(
      accessor: 'Strana Sdn. Bhd. (Vehicle Owner)',
      action: 'Viewed rental details',
      dataAccessed: 'Name, License Number, Booking Dates',
      purpose: 'Rental approval',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      accessType: AccessType.vehicleOwner,
      ipAddress: '118.200.xxx.xxx',
      device: 'Desktop Browser',
    ),
    DataAccessLog(
      accessor: 'You',
      action: 'Downloaded invoice',
      dataAccessed: 'Transaction Records',
      purpose: 'Invoice download',
      timestamp: DateTime.now().subtract(const Duration(days: 6)),
      accessType: AccessType.self,
      ipAddress: '103.106.xxx.xxx',
      device: 'Samsung Galaxy S23',
    ),
    DataAccessLog(
      accessor: 'MotoRent System',
      action: 'Location tracking',
      dataAccessed: 'GPS Location',
      purpose: 'Active rental tracking',
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      accessType: AccessType.system,
      ipAddress: 'Internal',
      device: 'Mobile App',
    ),
  ];

  List<DataAccessLog> _getFilteredLogs() {
    final now = DateTime.now();
    return _mockLogs.where((log) {
      switch (_filterPeriod) {
        case 'today':
          return log.timestamp.isAfter(now.subtract(const Duration(days: 1)));
        case 'week':
          return log.timestamp.isAfter(now.subtract(const Duration(days: 7)));
        case 'month':
          return log.timestamp.isAfter(now.subtract(const Duration(days: 30)));
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recent Data Access',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👁️ Who Accessed Your Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track who has viewed or used your personal information and for what purpose.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Filter Period
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Show:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Time'),
                        _buildFilterChip('today', 'Today'),
                        _buildFilterChip('week', 'This Week'),
                        _buildFilterChip('month', 'This Month'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Summary Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '${filteredLogs.length}',
                    'Total Access',
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${filteredLogs.where((l) => l.accessType == AccessType.thirdParty).length}',
                    'Third-Party',
                    Icons.share,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${filteredLogs.where((l) => l.accessType == AccessType.vehicleOwner).length}',
                    'Owners',
                    Icons.person,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Access Logs List
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No access logs for this period',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildAccessLogCard(filteredLogs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _filterPeriod = value;
          });
        },
        selectedColor: const Color(0xFF1E88E5),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessLogCard(DataAccessLog log) {
    final accessTypeConfig = _getAccessTypeConfig(log.accessType);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAccessDetails(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accessTypeConfig['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      accessTypeConfig['icon'],
                      color: accessTypeConfig['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.accessor,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.action,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accessTypeConfig['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      accessTypeConfig['label'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accessTypeConfig['color'],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.folder, 'Data:', log.dataAccessed),
              _buildDetailRow(Icons.info_outline, 'Purpose:', log.purpose),
              _buildDetailRow(Icons.access_time, 'When:', _formatTimestamp(log.timestamp)),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.devices, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    log.device,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    log.ipAddress,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getAccessTypeConfig(AccessType type) {
    switch (type) {
      case AccessType.self:
        return {
          'icon': Icons.person,
          'color': Colors.blue,
          'label': 'You',
        };
      case AccessType.system:
        return {
          'icon': Icons.settings,
          'color': Colors.grey,
          'label': 'System',
        };
      case AccessType.admin:
        return {
          'icon': Icons.admin_panel_settings,
          'color': Colors.purple,
          'label': 'Admin',
        };
      case AccessType.vehicleOwner:
        return {
          'icon': Icons.directions_car,
          'color': Colors.green,
          'label': 'Owner',
        };
      case AccessType.thirdParty:
        return {
          'icon': Icons.business,
          'color': Colors.orange,
          'label': 'Third-Party',
        };
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
    }
  }

  void _showAccessDetails(DataAccessLog log) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAccessTypeConfig(log.accessType)['icon'],
                  color: _getAccessTypeConfig(log.accessType)['color'],
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    log.accessor,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailItem('Action', log.action),
            _buildDetailItem('Data Accessed', log.dataAccessed),
            _buildDetailItem('Purpose', log.purpose),
            _buildDetailItem('Timestamp', DateFormat('dd MMM yyyy, HH:mm:ss').format(log.timestamp)),
            _buildDetailItem('Device', log.device),
            _buildDetailItem('IP Address', log.ipAddress),
            const SizedBox(height: 16),
            if (log.accessType == AccessType.thirdParty || log.accessType == AccessType.vehicleOwner) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This access was necessary for providing the service you requested.',
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

enum AccessType {
  self,
  system,
  admin,
  vehicleOwner,
  thirdParty,
}

class DataAccessLog {
  final String accessor;
  final String action;
  final String dataAccessed;
  final String purpose;
  final DateTime timestamp;
  final AccessType accessType;
  final String ipAddress;
  final String device;

  DataAccessLog({
    required this.accessor,
    required this.action,
    required this.dataAccessed,
    required this.purpose,
    required this.timestamp,
    required this.accessType,
    required this.ipAddress,
    required this.device,
  });
}