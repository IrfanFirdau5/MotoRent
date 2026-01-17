// FILE: motorent/lib/screens/customer/third_party_log_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ThirdPartyLogPage extends StatefulWidget {
  final String userId;
  
  const ThirdPartyLogPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ThirdPartyLogPage> createState() => _ThirdPartyLogPageState();
}

class _ThirdPartyLogPageState extends State<ThirdPartyLogPage> {
  String _selectedCategory = 'all';
  
  // Mock third-party sharing data
  final List<ThirdPartyShare> _mockShares = [
    ThirdPartyShare(
      partner: 'iPay88',
      category: ThirdPartyCategory.payment,
      dataShared: ['Payment card details (tokenized)', 'Transaction amount', 'Email address'],
      purpose: 'Process rental payments securely',
      frequency: 'Per transaction',
      legalBasis: 'Contract performance - necessary for payment processing',
      privacyPolicy: 'https://www.ipay88.com.my/privacy-policy',
      lastShared: DateTime.now().subtract(const Duration(days: 1)),
      canRevoke: false,
      location: 'Malaysia',
      retentionPeriod: '7 years (legal requirement)',
      icon: Icons.payment,
      color: Colors.green,
    ),
    ThirdPartyShare(
      partner: 'Stripe',
      category: ThirdPartyCategory.payment,
      dataShared: ['Credit card info (tokenized)', 'Billing address', 'Transaction history'],
      purpose: 'Alternative payment processing',
      frequency: 'Per transaction',
      legalBasis: 'Contract performance',
      privacyPolicy: 'https://stripe.com/privacy',
      lastShared: DateTime.now().subtract(const Duration(days: 3)),
      canRevoke: false,
      location: 'Singapore, USA',
      retentionPeriod: '7 years',
      icon: Icons.credit_card,
      color: Colors.blue,
    ),
    ThirdPartyShare(
      partner: 'Google Analytics',
      category: ThirdPartyCategory.analytics,
      dataShared: ['Device type', 'App usage patterns', 'Location data (anonymized)'],
      purpose: 'Improve app performance and user experience',
      frequency: 'Continuous',
      legalBasis: 'Consent',
      privacyPolicy: 'https://policies.google.com/privacy',
      lastShared: DateTime.now().subtract(const Duration(hours: 2)),
      canRevoke: true,
      location: 'USA',
      retentionPeriod: '26 months',
      icon: Icons.analytics,
      color: Colors.orange,
    ),
    ThirdPartyShare(
      partner: 'Firebase (Google)',
      category: ThirdPartyCategory.infrastructure,
      dataShared: ['User ID', 'Crash reports', 'Performance metrics'],
      purpose: 'App hosting and error monitoring',
      frequency: 'Continuous',
      legalBasis: 'Legitimate interest',
      privacyPolicy: 'https://firebase.google.com/support/privacy',
      lastShared: DateTime.now().subtract(const Duration(hours: 1)),
      canRevoke: false,
      location: 'Singapore',
      retentionPeriod: '180 days',
      icon: Icons.cloud,
      color: Colors.amber,
    ),
    ThirdPartyShare(
      partner: 'SendGrid',
      category: ThirdPartyCategory.communication,
      dataShared: ['Email address', 'Name', 'Booking details'],
      purpose: 'Send booking confirmations and notifications',
      frequency: 'Per email',
      legalBasis: 'Contract performance',
      privacyPolicy: 'https://sendgrid.com/policies/privacy',
      lastShared: DateTime.now().subtract(const Duration(days: 2)),
      canRevoke: false,
      location: 'USA',
      retentionPeriod: '90 days',
      icon: Icons.email,
      color: Colors.blue,
    ),
    ThirdPartyShare(
      partner: 'Twilio',
      category: ThirdPartyCategory.communication,
      dataShared: ['Phone number', 'SMS content'],
      purpose: 'Send SMS notifications and alerts',
      frequency: 'Per SMS',
      legalBasis: 'Consent',
      privacyPolicy: 'https://www.twilio.com/legal/privacy',
      lastShared: DateTime.now().subtract(const Duration(days: 1)),
      canRevoke: true,
      location: 'USA',
      retentionPeriod: '30 days',
      icon: Icons.sms,
      color: Colors.red,
    ),
    ThirdPartyShare(
      partner: 'MapBox / Google Maps',
      category: ThirdPartyCategory.maps,
      dataShared: ['GPS location', 'Search queries'],
      purpose: 'Display maps and vehicle locations',
      frequency: 'When using map features',
      legalBasis: 'Legitimate interest',
      privacyPolicy: 'https://www.mapbox.com/legal/privacy',
      lastShared: DateTime.now().subtract(const Duration(hours: 6)),
      canRevoke: false,
      location: 'USA',
      retentionPeriod: '30 days',
      icon: Icons.map,
      color: Colors.green,
    ),
    ThirdPartyShare(
      partner: 'Zurich Takaful Insurance',
      category: ThirdPartyCategory.insurance,
      dataShared: ['Name', 'NRIC', 'License details', 'Vehicle rental info'],
      purpose: 'Provide optional rental insurance',
      frequency: 'When purchasing insurance',
      legalBasis: 'Consent',
      privacyPolicy: 'https://www.zurich.com.my/privacy',
      lastShared: DateTime.now().subtract(const Duration(days: 15)),
      canRevoke: true,
      location: 'Malaysia',
      retentionPeriod: '7 years',
      icon: Icons.shield,
      color: Colors.purple,
    ),
    ThirdPartyShare(
      partner: 'Amazon Web Services (AWS)',
      category: ThirdPartyCategory.infrastructure,
      dataShared: ['All data stored in app', 'User files', 'Database records'],
      purpose: 'Cloud hosting and data storage',
      frequency: 'Continuous',
      legalBasis: 'Legitimate interest',
      privacyPolicy: 'https://aws.amazon.com/privacy',
      lastShared: DateTime.now().subtract(const Duration(minutes: 30)),
      canRevoke: false,
      location: 'Singapore',
      retentionPeriod: 'As per data retention policy',
      icon: Icons.storage,
      color: Colors.orange,
    ),
  ];

  List<ThirdPartyShare> _getFilteredShares() {
    if (_selectedCategory == 'all') {
      return _mockShares;
    }
    return _mockShares.where((share) => 
      share.category.toString().split('.').last == _selectedCategory
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredShares = _getFilteredShares();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Third-Party Sharing',
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
                colors: [Color(0xFFE65100), Color(0xFFFF6F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔗 Data Sharing Partners',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'See which third-party services have access to your data and why. You can manage some of these sharing preferences.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Info Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We only share data with trusted partners and always use encryption.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('all', 'All Partners', Icons.apps),
                _buildCategoryChip('payment', 'Payment', Icons.payment),
                _buildCategoryChip('analytics', 'Analytics', Icons.analytics),
                _buildCategoryChip('communication', 'Communication', Icons.email),
                _buildCategoryChip('infrastructure', 'Infrastructure', Icons.cloud),
                _buildCategoryChip('maps', 'Maps', Icons.map),
                _buildCategoryChip('insurance', 'Insurance', Icons.shield),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Partners Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filteredShares.length} partners',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredShares.where((s) => s.canRevoke).length} revocable',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Partners List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredShares.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildPartnerCard(filteredShares[index]);
              },
            ),
          ),
        ],
      ),
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
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPartnerCard(ThirdPartyShare share) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: share.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(share.icon, color: share.color, size: 24),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  share.partner,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (share.canRevoke)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Revocable',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                share.purpose,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Last shared: ${_formatTimestamp(share.lastShared)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailSection('Data Shared', share.dataShared, Icons.folder_open),
                  const SizedBox(height: 12),
                  _buildInfoRow('Purpose', share.purpose, Icons.info_outline),
                  _buildInfoRow('Frequency', share.frequency, Icons.repeat),
                  _buildInfoRow('Legal Basis', share.legalBasis, Icons.gavel),
                  _buildInfoRow('Location', share.location, Icons.public),
                  _buildInfoRow('Retention', share.retentionPeriod, Icons.schedule),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewPrivacyPolicy(share.privacyPolicy),
                          icon: const Icon(Icons.policy, size: 16),
                          label: const Text('Privacy Policy', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      if (share.canRevoke) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _revokeConsent(share),
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('Revoke Access', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailSection(String title, List<String> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1E88E5)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Text(item, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM yyyy').format(timestamp);
    }
  }

  Future<void> _viewPrivacyPolicy(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open privacy policy')),
      );
    }
  }

  void _revokeConsent(ThirdPartyShare share) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Data Sharing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to revoke data sharing with ${share.partner}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[900], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This may limit some app features or services.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
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
                SnackBar(
                  content: Text('Data sharing with ${share.partner} has been revoked'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}

enum ThirdPartyCategory {
  payment,
  analytics,
  communication,
  infrastructure,
  maps,
  insurance,
}

class ThirdPartyShare {
  final String partner;
  final ThirdPartyCategory category;
  final List<String> dataShared;
  final String purpose;
  final String frequency;
  final String legalBasis;
  final String privacyPolicy;
  final DateTime lastShared;
  final bool canRevoke;
  final String location;
  final String retentionPeriod;
  final IconData icon;
  final Color color;

  ThirdPartyShare({
    required this.partner,
    required this.category,
    required this.dataShared,
    required this.purpose,
    required this.frequency,
    required this.legalBasis,
    required this.privacyPolicy,
    required this.lastShared,
    required this.canRevoke,
    required this.location,
    required this.retentionPeriod,
    required this.icon,
    required this.color,
  });
}