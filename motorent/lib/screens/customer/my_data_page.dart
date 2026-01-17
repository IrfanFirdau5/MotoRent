// FILE: motorent/lib/screens/customer/my_data_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyDataPage extends StatefulWidget {
  final String userId;
  
  const MyDataPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<MyDataPage> {
  String _selectedCategory = 'all';
  
  // Mock data categories
  final Map<String, List<DataItem>> _mockData = {
    'personal': [
      DataItem('Full Name', 'Ahmad Zahari bin Abdullah', Icons.person, 'Collected during registration'),
      DataItem('NRIC Number', '901234-56-7890', Icons.badge, 'Required for identity verification'),
      DataItem('Date of Birth', '12/34/1990', Icons.cake, 'Collected during registration'),
      DataItem('Email', 'ahmad.zahari@email.com', Icons.email, 'Used for account communication'),
      DataItem('Phone Number', '+60 12-345 6789', Icons.phone, 'Used for booking notifications'),
      DataItem('Address', 'No. 123, Jalan Tun Razak, 50400 Kuala Lumpur', Icons.location_on, 'Billing and delivery address'),
    ],
    'driver': [
      DataItem('License Number', 'D1234567', Icons.credit_card, 'Required for vehicle rental'),
      DataItem('License Class', 'D (Motor Car)', Icons.directions_car, 'Determines eligible vehicles'),
      DataItem('License Expiry', '15/08/2028', Icons.event, 'Verification purposes'),
      DataItem('Verification Status', 'Verified ✓', Icons.verified, 'License verified on 10/01/2026'),
    ],
    'financial': [
      DataItem('Payment Method', 'Visa **** 4567', Icons.credit_card, 'Default payment method'),
      DataItem('Billing Address', 'Same as residential address', Icons.location_city, 'For invoicing'),
      DataItem('Total Spent', 'RM 2,450.00', Icons.attach_money, 'Lifetime spending on platform'),
      DataItem('Last Transaction', 'RM 350.00 on 15/01/2026', Icons.receipt, 'Most recent payment'),
    ],
    'activity': [
      DataItem('Account Created', '15/06/2025', Icons.calendar_today, 'Registration date'),
      DataItem('Last Login', '17/01/2026 at 09:45 AM', Icons.login, 'Most recent access'),
      DataItem('Total Bookings', '12 completed', Icons.event_available, 'Rental history'),
      DataItem('Reviews Written', '8 reviews', Icons.rate_review, 'Feedback provided'),
      DataItem('Favorite Vehicles', '3 saved', Icons.favorite, 'Bookmarked vehicles'),
    ],
    'technical': [
      DataItem('Device Type', 'Samsung Galaxy S23', Icons.phone_android, 'Primary access device'),
      DataItem('Operating System', 'Android 14', Icons.settings, 'Device OS version'),
      DataItem('App Version', '1.0.0', Icons.app_settings_alt, 'Current app version'),
      DataItem('Last IP Address', '103.106.xxx.xxx', Icons.router, 'Most recent connection'),
      DataItem('Location Permission', 'Allowed during rental', Icons.location_searching, 'GPS access setting'),
    ],
    'preferences': [
      DataItem('Language', 'English', Icons.language, 'App display language'),
      DataItem('Notifications', 'Enabled', Icons.notifications, 'Push notification setting'),
      DataItem('Email Marketing', 'Opted In', Icons.mail, 'Promotional emails'),
      DataItem('SMS Alerts', 'Enabled', Icons.sms, 'Booking reminders'),
      DataItem('Theme', 'System Default', Icons.palette, 'App appearance'),
    ],
  };

  List<DataItem> _getFilteredData() {
    if (_selectedCategory == 'all') {
      return _mockData.values.expand((list) => list).toList();
    }
    return _mockData[_selectedCategory] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download All Data',
            onPressed: _showDownloadDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Personal Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is all the data we have about you. You have the right to access, correct, or delete this information under PDPA 2010.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Last updated: 17/01/2026',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('all', 'All Data', Icons.folder),
                _buildCategoryChip('personal', 'Personal', Icons.person),
                _buildCategoryChip('driver', 'Driver', Icons.directions_car),
                _buildCategoryChip('financial', 'Financial', Icons.account_balance_wallet),
                _buildCategoryChip('activity', 'Activity', Icons.history),
                _buildCategoryChip('technical', 'Technical', Icons.devices),
                _buildCategoryChip('preferences', 'Preferences', Icons.tune),
              ],
            ),
          ),

          // Data Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filteredData.length} data points',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showDataExplanation,
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Why we collect this', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Data List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filteredData[index];
                return _buildDataCard(item);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildCategoryChip(String category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF1E88E5),
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: const Color(0xFF1E88E5),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1E88E5),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDataCard(DataItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item.icon,
            color: const Color(0xFF1E88E5),
            size: 24,
          ),
        ),
        title: Text(
          item.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'Copy',
          onPressed: () => _copyToClipboard(item.value),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.file_download),
                label: const Text('Export Data'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF1E88E5)),
                  foregroundColor: const Color(0xFF1E88E5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _requestDeletion,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Request Deletion'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download All Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your preferred format:'),
            SizedBox(height: 16),
            Text('• JSON - Machine readable format'),
            SizedBox(height: 8),
            Text('• CSV - Spreadsheet format'),
            SizedBox(height: 8),
            Text('• PDF - Human readable document'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadData('JSON');
            },
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadData('CSV');
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadData('PDF');
            },
            child: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  void _downloadData(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preparing $format file... You will receive an email with download link within 24 hours.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _exportData() {
    _showDownloadDialog();
  }

  void _requestDeletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Data Deletion'),
        content: const Text(
          'Are you sure you want to request deletion of specific data? You can choose which data to delete on the next screen.\n\nNote: Some data may be retained for legal compliance (e.g., transaction records for 7 years).',
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
                  content: Text('Please navigate to "Delete Specific Data" page to select data for deletion.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showDataExplanation() {
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
            const Text(
              'Why We Collect This Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildExplanationItem('Personal Information', 'To verify your identity and communicate with you'),
            _buildExplanationItem('Driver Information', 'To ensure you\'re eligible to rent vehicles (legal requirement)'),
            _buildExplanationItem('Financial Data', 'To process payments and prevent fraud'),
            _buildExplanationItem('Activity Data', 'To improve your experience and provide personalized recommendations'),
            _buildExplanationItem('Technical Data', 'To ensure app security and optimize performance'),
            _buildExplanationItem('Preferences', 'To customize your experience and respect your communication choices'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF1E88E5), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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

class DataItem {
  final String label;
  final String value;
  final IconData icon;
  final String description;

  DataItem(this.label, this.value, this.icon, this.description);
}