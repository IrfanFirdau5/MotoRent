// FILE: motorent/lib/screens/customer/login_history_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoginHistoryPage extends StatefulWidget {
  final String userId;
  
  const LoginHistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<LoginHistoryPage> createState() => _LoginHistoryPageState();
}

class _LoginHistoryPageState extends State<LoginHistoryPage> {
  String _filterPeriod = 'all'; // all, week, month
  
  // Mock login history data
  final List<LoginRecord> _mockLogins = [
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      device: 'Samsung Galaxy S23',
      location: 'Kuching, Sarawak',
      ipAddress: '103.106.xxx.xxx',
      browser: 'Chrome Mobile 120',
      os: 'Android 14',
      status: LoginStatus.success,
      isCurrent: true,
    ),
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      device: 'Samsung Galaxy S23',
      location: 'Kuching, Sarawak',
      ipAddress: '103.106.xxx.xxx',
      browser: 'Chrome Mobile 120',
      os: 'Android 14',
      status: LoginStatus.success,
      isCurrent: false,
    ),
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      device: 'Desktop Browser',
      location: 'Kuala Lumpur',
      ipAddress: '101.50.xxx.xxx',
      browser: 'Chrome 120',
      os: 'Windows 11',
      status: LoginStatus.success,
      isCurrent: false,
    ),
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      device: 'Unknown Device',
      location: 'Jakarta, Indonesia',
      ipAddress: '182.253.xxx.xxx',
      browser: 'Unknown',
      os: 'Unknown',
      status: LoginStatus.failed,
      isCurrent: false,
      failureReason: 'Invalid password',
    ),
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      device: 'iPhone 14',
      location: 'Kuching, Sarawak',
      ipAddress: '103.106.xxx.xxx',
      browser: 'Safari Mobile',
      os: 'iOS 17',
      status: LoginStatus.success,
      isCurrent: false,
    ),
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      device: 'Samsung Galaxy S23',
      location: 'Sibu, Sarawak',
      ipAddress: '118.200.xxx.xxx',
      browser: 'Chrome Mobile 120',
      os: 'Android 14',
      status: LoginStatus.success,
      isCurrent: false,
    ),
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 10)),
      device: 'Xiaomi Redmi Note 10',
      location: 'Miri, Sarawak',
      ipAddress: '101.78.xxx.xxx',
      browser: 'Chrome Mobile 119',
      os: 'Android 13',
      status: LoginStatus.success,
      isCurrent: false,
    ),
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 15)),
      device: 'Unknown Device',
      location: 'Singapore',
      ipAddress: '203.124.xxx.xxx',
      browser: 'Unknown',
      os: 'Unknown',
      status: LoginStatus.failed,
      isCurrent: false,
      failureReason: 'Too many attempts',
    ),
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 20)),
      device: 'Desktop Browser',
      location: 'Kuching, Sarawak',
      ipAddress: '103.106.xxx.xxx',
      browser: 'Firefox 119',
      os: 'macOS 14',
      status: LoginStatus.success,
      isCurrent: false,
    ),
    LoginRecord(
      timestamp: DateTime.now().subtract(const Duration(days: 25)),
      device: 'Samsung Galaxy S23',
      location: 'Kuching, Sarawak',
      ipAddress: '103.106.xxx.xxx',
      browser: 'Chrome Mobile 118',
      os: 'Android 14',
      status: LoginStatus.success,
      isCurrent: false,
    ),
  ];

  List<LoginRecord> _getFilteredLogins() {
    final now = DateTime.now();
    return _mockLogins.where((login) {
      switch (_filterPeriod) {
        case 'week':
          return login.timestamp.isAfter(now.subtract(const Duration(days: 7)));
        case 'month':
          return login.timestamp.isAfter(now.subtract(const Duration(days: 30)));
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogins = _getFilteredLogins();
    final successCount = filteredLogins.where((l) => l.status == LoginStatus.success).length;
    final failedCount = filteredLogins.where((l) => l.status == LoginStatus.failed).length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login History',
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
                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔐 Account Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track all login attempts to your account. Report suspicious activity immediately.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Security Alert (if failed logins exist)
          if (failedCount > 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security Alert',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$failedCount failed login attempts detected. Review below.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Filter Period
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        _buildFilterChip('week', 'Last 7 Days'),
                        _buildFilterChip('month', 'Last 30 Days'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '$successCount',
                    'Successful',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '$failedCount',
                    'Failed',
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${filteredLogins.length}',
                    'Total',
                    Icons.history,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Login Records List
          Expanded(
            child: filteredLogins.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No login activity for this period',
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
                    itemCount: filteredLogins.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildLoginCard(filteredLogins[index]);
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

  Widget _buildLoginCard(LoginRecord login) {
    final statusConfig = _getStatusConfig(login.status);
    
    return Card(
      elevation: login.isCurrent ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: login.isCurrent 
            ? const BorderSide(color: Color(0xFF1E88E5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showLoginDetails(login),
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
                      color: statusConfig['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusConfig['icon'],
                      color: statusConfig['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                login.device,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (login.isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Current',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(login.timestamp),
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
                      color: statusConfig['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusConfig['label'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusConfig['color'],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on, 'Location:', login.location),
              _buildDetailRow(Icons.router, 'IP:', login.ipAddress),
              _buildDetailRow(Icons.language, 'Browser:', login.browser),
              if (login.status == LoginStatus.failed && login.failureReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reason: ${login.failureReason}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Map<String, dynamic> _getStatusConfig(LoginStatus status) {
    switch (status) {
      case LoginStatus.success:
        return {
          'icon': Icons.check_circle,
          'color': Colors.green,
          'label': 'Success',
        };
      case LoginStatus.failed:
        return {
          'icon': Icons.cancel,
          'color': Colors.red,
          'label': 'Failed',
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

  void _showLoginDetails(LoginRecord login) {
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
                  _getStatusConfig(login.status)['icon'],
                  color: _getStatusConfig(login.status)['color'],
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Login Details',
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
            _buildDetailItem('Status', _getStatusConfig(login.status)['label']),
            _buildDetailItem('Timestamp', DateFormat('dd MMM yyyy, HH:mm:ss').format(login.timestamp)),
            _buildDetailItem('Device', login.device),
            _buildDetailItem('Operating System', login.os),
            _buildDetailItem('Browser', login.browser),
            _buildDetailItem('Location', login.location),
            _buildDetailItem('IP Address', login.ipAddress),
            if (login.failureReason != null)
              _buildDetailItem('Failure Reason', login.failureReason!),
            const SizedBox(height: 16),
            if (login.status == LoginStatus.failed) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.red[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'If this wasn\'t you, change your password immediately and enable two-factor authentication.',
                        style: TextStyle(fontSize: 12, color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _reportSuspiciousActivity(login);
                  },
                  icon: const Icon(Icons.report),
                  label: const Text('Report Suspicious Activity'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else
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

  void _reportSuspiciousActivity(LoginRecord login) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Suspicious Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to report this login attempt as suspicious:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Device: ${login.device}', style: const TextStyle(fontSize: 12)),
                  Text('Location: ${login.location}', style: const TextStyle(fontSize: 12)),
                  Text('Time: ${DateFormat('dd MMM yyyy, HH:mm').format(login.timestamp)}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Our security team will investigate this activity and may contact you for additional verification.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suspicious activity reported. Our security team will investigate.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}

enum LoginStatus {
  success,
  failed,
}

class LoginRecord {
  final DateTime timestamp;
  final String device;
  final String location;
  final String ipAddress;
  final String browser;
  final String os;
  final LoginStatus status;
  final bool isCurrent;
  final String? failureReason;

  LoginRecord({
    required this.timestamp,
    required this.device,
    required this.location,
    required this.ipAddress,
    required this.browser,
    required this.os,
    required this.status,
    required this.isCurrent,
    this.failureReason,
  });
}