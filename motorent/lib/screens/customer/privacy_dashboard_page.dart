// FILE: motorent/lib/screens/customer/privacy_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'privacy_policy_page.dart';
import 'your_rights_page.dart';

class PrivacyDashboardPage extends StatefulWidget {
  final String userId;

  const PrivacyDashboardPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<PrivacyDashboardPage> createState() => _PrivacyDashboardPageState();
}

class _PrivacyDashboardPageState extends State<PrivacyDashboardPage> {
  int _privacyScore = 85;
  bool _emailPromotions = true;
  bool _smsNotifications = true;
  bool _pushNotifications = true;
  bool _analyticsPartners = false;
  bool _insurancePartners = false;
  String _locationService = 'rental_only'; // rental_only, always, never
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🔒 My Privacy Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy Score Card
          _buildPrivacyScoreCard(),
          const SizedBox(height: 16),

          // Quick Links Section
          _buildQuickLinksCard(),
          const SizedBox(height: 16),

          // Privacy Settings Section
          _buildPrivacySettingsCard(),
          const SizedBox(height: 16),

          // Privacy Activity Section
          _buildPrivacyActivityCard(),
          const SizedBox(height: 16),

          // Data Management Section
          _buildDataManagementCard(),
          const SizedBox(height: 16),

          // Privacy Support Section
          _buildPrivacySupportCard(),
        ],
      ),
    );
  }

  Widget _buildPrivacyScoreCard() {
    Color scoreColor = _privacyScore >= 80
        ? Colors.green
        : _privacyScore >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Your Privacy at a Glance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Privacy Score:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '$_privacyScore/100',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _privacyScore / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 16),
            Text(
              _privacyScore >= 80 ? 'Strong Privacy ✓' : 'Needs Improvement',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Recommendations:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (!_twoFactorEnabled)
              _buildRecommendation(
                '⚠ Enable Two-Factor Authentication',
                '+10 points',
                () => _showEnableTwoFactorDialog(),
              ),
            if (_analyticsPartners || _insurancePartners)
              _buildRecommendation(
                '⚠ Review third-party sharing settings',
                '+5 points',
                () => _scrollToPrivacySettings(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(String title, String points, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Text(
              points,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.folder_outlined,
            title: '📁 My Data',
            subtitle: 'View all data we have about you',
            onTap: () => _navigateToMyData(),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.download_outlined,
            title: 'Download my data',
            subtitle: 'Get a copy of your information',
            onTap: () => _downloadMyData(),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.edit_outlined,
            title: 'Request corrections',
            subtitle: 'Fix incorrect information',
            onTap: () => _requestCorrections(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Privacy Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Marketing & Communications
            const Text(
              'Marketing & Communications',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            _buildToggleTile(
              'Email Promotions',
              _emailPromotions,
              (value) => setState(() => _emailPromotions = value),
            ),
            _buildToggleTile(
              'SMS Notifications',
              _smsNotifications,
              (value) => setState(() => _smsNotifications = value),
            ),
            _buildToggleTile(
              'Push Notifications',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Data Sharing
            const Text(
              'Data Sharing (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            _buildToggleTileWithInfo(
              'Analytics Partners',
              'Help us improve service',
              _analyticsPartners,
              (value) {
                setState(() => _analyticsPartners = value);
                _updatePrivacyScore();
              },
            ),
            _buildToggleTileWithInfo(
              'Insurance Partners',
              'Get personalized insurance',
              _insurancePartners,
              (value) {
                setState(() => _insurancePartners = value);
                _updatePrivacyScore();
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Location Services
            const Text(
              'Location Services',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            _buildLocationServiceOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1E88E5),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTileWithInfo(
    String title,
    String info,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF1E88E5),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              '? $info',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationServiceOptions() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('During Rental Only', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Recommended',
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
          value: 'rental_only',
          groupValue: _locationService,
          activeColor: const Color(0xFF1E88E5),
          onChanged: (value) => setState(() => _locationService = value!),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('Always', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'Better recommendations',
            style: TextStyle(fontSize: 12),
          ),
          value: 'always',
          groupValue: _locationService,
          activeColor: const Color(0xFF1E88E5),
          onChanged: (value) => setState(() => _locationService = value!),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('Never', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'May limit features',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
          value: 'never',
          groupValue: _locationService,
          activeColor: const Color(0xFF1E88E5),
          onChanged: (value) => setState(() => _locationService = value!),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildPrivacyActivityCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Text(
                  '👁️ Privacy Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.history,
            title: 'Recent data access',
            subtitle: 'Who viewed your information',
            onTap: () => _showRecentDataAccess(),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.share_outlined,
            title: 'Third-party sharing log',
            subtitle: 'External services we shared with',
            onTap: () => _showThirdPartyLog(),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.login_outlined,
            title: 'Login history',
            subtitle: 'Your recent account activity',
            onTap: () => _showLoginHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Text(
                  '🗑️ Manage My Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.delete_outline,
            title: 'Delete specific data',
            subtitle: 'Remove selected information',
            onTap: () => _deleteSpecificData(),
            iconColor: Colors.orange,
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.delete_forever,
            title: 'Delete my account',
            subtitle: 'Permanently remove your account',
            onTap: () => _deleteAccount(),
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySupportCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                Text(
                  '📧 Privacy Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.support_agent,
            title: 'Contact Privacy Team',
            subtitle: 'Get help with privacy concerns',
            onTap: () => _contactPrivacyTeam(),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.policy_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy practices',
            onTap: () => _showPrivacyPolicy(),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.gavel_outlined,
            title: 'Your Rights',
            subtitle: 'Learn about your privacy rights',
            onTap: () => _showYourRights(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF1E88E5)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  // Navigation and Action Methods
  void _navigateToMyData() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyDataPage(userId: widget.userId),
      ),
    );
  }

  void _downloadMyData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download My Data'),
        content: const Text(
          'Your data will be prepared and sent to your email within 24 hours. You will receive all information we have about you in a downloadable format.',
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
                  content: Text('Data download request submitted!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _requestCorrections() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataCorrectionPage(userId: widget.userId),
      ),
    );
  }

  void _showRecentDataAccess() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecentDataAccessPage(userId: widget.userId),
      ),
    );
  }

  void _showThirdPartyLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThirdPartyLogPage(userId: widget.userId),
      ),
    );
  }

  void _showLoginHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginHistoryPage(userId: widget.userId),
      ),
    );
  }

  void _deleteSpecificData() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeleteSpecificDataPage(userId: widget.userId),
      ),
    );
  }

  void _deleteAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeleteAccountPage(userId: widget.userId),
      ),
    );
  }

  void _contactPrivacyTeam() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Privacy Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Get in touch with our privacy team:'),
            const SizedBox(height: 16),
            const Text('📧 Email: privacy@motorent.com'),
            const SizedBox(height: 8),
            const Text('📞 Phone: +60 3-1234 5678'),
            const SizedBox(height: 8),
            const Text('⏰ Hours: Mon-Fri, 9AM-6PM MYT'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyPage(),
      ),
    );
  }

  void _showYourRights() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const YourRightsPage(),
      ),
    );
  }

  void _showEnableTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Two-Factor Authentication'),
        content: const Text(
          'Two-factor authentication adds an extra layer of security to your account. You will need to enter a code from your phone in addition to your password when logging in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _twoFactorEnabled = true);
              _updatePrivacyScore();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication enabled!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enable Now'),
          ),
        ],
      ),
    );
  }

  void _scrollToPrivacySettings() {
    // In a real implementation, you would scroll to the settings section
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review your data sharing settings below'),
      ),
    );
  }

  void _updatePrivacyScore() {
    int score = 70; // Base score
    
    if (_twoFactorEnabled) score += 10;
    if (!_analyticsPartners) score += 5;
    if (!_insurancePartners) score += 5;
    if (_locationService == 'rental_only') score += 5;
    if (_locationService == 'never') score += 10;
    
    setState(() => _privacyScore = score.clamp(0, 100));
  }
}

// Placeholder pages - implement these with actual functionality
class MyDataPage extends StatelessWidget {
  final String userId;
  const MyDataPage({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Data')),
    body: const Center(child: Text('My Data Page - To be implemented')),
  );
}

class DataCorrectionPage extends StatelessWidget {
  final String userId;
  const DataCorrectionPage({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request Corrections')),
    body: const Center(child: Text('Data Correction Page - To be implemented')),
  );
}

class RecentDataAccessPage extends StatelessWidget {
  final String userId;
  const RecentDataAccessPage({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recent Data Access')),
    body: const Center(child: Text('Recent Data Access - To be implemented')),
  );
}

class ThirdPartyLogPage extends StatelessWidget {
  final String userId;
  const ThirdPartyLogPage({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Third-Party Sharing Log')),
    body: const Center(child: Text('Third-Party Log - To be implemented')),
  );
}

class LoginHistoryPage extends StatelessWidget {
  final String userId;
  const LoginHistoryPage({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Login History')),
    body: const Center(child: Text('Login History - To be implemented')),
  );
}

class DeleteSpecificDataPage extends StatelessWidget {
  final String userId;
  const DeleteSpecificDataPage({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Delete Specific Data')),
    body: const Center(child: Text('Delete Specific Data - To be implemented')),
  );
}

class DeleteAccountPage extends StatelessWidget {
  final String userId;
  const DeleteAccountPage({Key? key, required this.userId}) : super(key: key);
  
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Delete Account')),
    body: const Center(child: Text('Delete Account - To be implemented')),
  );
}