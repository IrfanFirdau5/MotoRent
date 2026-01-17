// FILE: motorent/lib/screens/customer/delete_account_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeleteAccountPage extends StatefulWidget {
  final String userId;

  const DeleteAccountPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  int _currentStep = 0;
  String _deletionOption =
      'profile_only'; // profile_only, everything_except_legal, everything_possible
  bool _downloadDataFirst = false;
  bool _understandImpact = false;
  bool _confirmDeletion = false;
  String _confirmationText = '';
  bool _isDeleting = false;

  // Mock data for active items
  final Map<String, dynamic> _activeItems = {
    'active_rentals': 2,
    'pending_payments': 1,
    'listed_vehicles': 0,
    'pending_reviews': 1,
  };

  final Map<String, dynamic> _dataRetention = {
    'transaction_records': {
      'retention': '7 years',
      'reason': 'Tax and legal compliance (LHDN requirements)',
      'data_kept': 'Payment records, rental receipts, invoices',
    },
    'legal_records': {
      'retention': '7 years',
      'reason': 'Legal claims and dispute resolution',
      'data_kept': 'Contracts, dispute records, complaints',
    },
    'fraud_prevention': {
      'retention': '5 years',
      'reason': 'Fraud prevention and security',
      'data_kept': 'Fraud flags, suspicious activity logs',
    },
  };

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        return !_hasActiveItems;
      case 2:
        return _understandImpact;
      case 3:
        return _confirmDeletion &&
            _confirmationText.toLowerCase() == 'delete my account';
      default:
        return false;
    }
  }

  bool get _hasActiveItems {
    return _activeItems['active_rentals'] > 0 ||
        _activeItems['pending_payments'] > 0 ||
        _activeItems['listed_vehicles'] > 0;
  }

  void _nextStep() {
    if (_canProceed && _currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _confirmAccountDeletion() async {
    setState(() {
      _isDeleting = true;
    });

    // Simulate deletion process
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Account Deletion Scheduled'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your account deletion request has been submitted successfully.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline,
                          size: 16, color: Color(0xFF1E88E5)),
                      SizedBox(width: 8),
                      Text(
                        'What happens next:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildNextStepItem(
                      'Your account will be deactivated immediately'),
                  _buildNextStepItem('You have 30 days to cancel this request'),
                  _buildNextStepItem(
                      'After 30 days, your data will be permanently deleted'),
                  if (_downloadDataFirst)
                    _buildNextStepItem(
                        'Data export will be sent to your email within 24 hours'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Deletion Date: ${DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 30)))}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
              Navigator.of(context).pop(); // Go back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    setState(() {
      _isDeleting = false;
    });
  }

  Widget _buildNextStepItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delete Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red[50],
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 4,
                    backgroundColor: Colors.red[100],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Step ${_currentStep + 1} of 4',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(),
            ),
          ),

          // Navigation buttons
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
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed
                        ? (_currentStep == 3
                            ? _confirmAccountDeletion
                            : _nextStep)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStep == 3
                          ? Colors.red
                          : const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _currentStep == 3 ? 'Delete Account' : 'Next',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1ChooseOption();
      case 1:
        return _buildStep2ActiveItems();
      case 2:
        return _buildStep3UnderstandImpact();
      case 3:
        return _buildStep4Confirmation();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1ChooseOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What would you like to delete?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose what data you want to remove from MotoRent',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        _buildDeletionOption(
          value: 'profile_only',
          title: 'Just my profile info',
          description: 'Remove your name, email, and contact details',
          icon: Icons.person_outline,
          color: Colors.orange,
          retained: 'Rental history and transaction records will be kept',
        ),
        const SizedBox(height: 16),
        _buildDeletionOption(
          value: 'everything_except_legal',
          title: 'Everything except legal records',
          description: 'Delete all data except what\'s required by law',
          icon: Icons.delete_sweep,
          color: Colors.red[700]!,
          retained: 'Transaction records kept for 7 years (tax law)',
          recommended: true,
        ),
        const SizedBox(height: 16),
        _buildDeletionOption(
          value: 'everything_possible',
          title: 'Everything legally possible',
          description: 'Maximum deletion allowed under Malaysian law',
          icon: Icons.delete_forever,
          color: Colors.red[900]!,
          retained: 'Only essential legal records kept',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _downloadDataFirst,
                onChanged: (value) {
                  setState(() {
                    _downloadDataFirst = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Download my data first',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Get a copy of your data before deletion (recommended)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeletionOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String retained,
    bool recommended = false,
  }) {
    final isSelected = _deletionOption == value;

    return InkWell(
      onTap: () {
        setState(() {
          _deletionOption = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<String>(
                  value: value,
                  groupValue: _deletionOption,
                  onChanged: (val) {
                    setState(() {
                      _deletionOption = val!;
                    });
                  },
                  activeColor: color,
                ),
                const SizedBox(width: 12),
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (recommended)
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
                                'Recommended',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data retained: $retained',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2ActiveItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Items Check',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Before deleting your account, you need to resolve these items',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        if (_hasActiveItems) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Action Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You must resolve all active items before deletion',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        _buildActiveItemCard(
          'Active Rentals',
          _activeItems['active_rentals'],
          Icons.directions_car,
          Colors.blue,
          'Complete or cancel all active rentals',
        ),
        const SizedBox(height: 12),
        _buildActiveItemCard(
          'Pending Payments',
          _activeItems['pending_payments'],
          Icons.payment,
          Colors.orange,
          'Clear all pending payments',
        ),
        const SizedBox(height: 12),
        _buildActiveItemCard(
          'Listed Vehicles',
          _activeItems['listed_vehicles'],
          Icons.garage,
          Colors.green,
          'Remove or transfer all vehicle listings',
        ),
        const SizedBox(height: 12),
        _buildActiveItemCard(
          'Pending Reviews',
          _activeItems['pending_reviews'],
          Icons.rate_review,
          Colors.purple,
          'Optional - Reviews can be deleted with account',
          optional: true,
        ),
        if (!_hasActiveItems) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'All Clear!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You can proceed with account deletion',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActiveItemCard(
    String title,
    int count,
    IconData icon,
    Color color,
    String description, {
    bool optional = false,
  }) {
    final hasItems = count > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasItems && !optional ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasItems && !optional ? Colors.red[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: hasItems && !optional ? Colors.red : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (optional)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '(Optional)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasItems && !optional)
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildStep3UnderstandImpact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Understand the Impact',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please review what will happen when you delete your account',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),

        // What gets deleted
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.delete_forever, color: Colors.red, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'What Gets Deleted',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildImpactItem(
                  Icons.person, 'Your profile and personal information'),
              _buildImpactItem(
                  Icons.photo, 'Profile photos and uploaded images'),
              _buildImpactItem(Icons.settings, 'App preferences and settings'),
              _buildImpactItem(Icons.notifications, 'Notification preferences'),
              _buildImpactItem(Icons.history, 'Rental history (after 30 days)'),
              _buildImpactItem(Icons.star, 'Reviews and ratings'),
              _buildImpactItem(Icons.chat, 'Messages and communications'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // What gets kept
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield, color: Colors.orange[900], size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'What We Must Keep (Legal Requirements)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._dataRetention.entries.map((entry) {
                final data = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              data['retention'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${data['reason']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Data: ${data['data_kept']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Acknowledgment checkbox
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _understandImpact,
                onChanged: (value) {
                  setState(() {
                    _understandImpact = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'I understand the impact',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'I acknowledge that this action cannot be undone after 30 days and that some data must be kept for legal compliance.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Confirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Final Confirmation',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This is your last chance to cancel',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[300]!, width: 2),
          ),
          child: Column(
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'This Action Cannot Be Undone',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'After 30 days, your account and data will be permanently deleted. You will lose access to all your rentals, reviews, and preferences.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Summary of deletion
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deletion Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Option', _getDeletionOptionText()),
              _buildSummaryRow(
                  'Data Export', _downloadDataFirst ? 'Yes' : 'No'),
              _buildSummaryRow('Grace Period', '30 days'),
              _buildSummaryRow(
                'Deletion Date',
                DateFormat('dd MMM yyyy').format(
                  DateTime.now().add(const Duration(days: 30)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Confirmation checkbox
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _confirmDeletion,
                onChanged: (value) {
                  setState(() {
                    _confirmDeletion = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'I confirm account deletion',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'I understand this action is permanent after 30 days',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Type confirmation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _confirmationText.toLowerCase() == 'delete my account'
                  ? Colors.red
                  : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type "DELETE MY ACCOUNT" to confirm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _confirmationText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'DELETE MY ACCOUNT',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon:
                      _confirmationText.toLowerCase() == 'delete my account'
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getDeletionOptionText() {
    switch (_deletionOption) {
      case 'profile_only':
        return 'Profile Only';
      case 'everything_except_legal':
        return 'Everything Except Legal';
      case 'everything_possible':
        return 'Everything Possible';
      default:
        return '';
    }
  }
}
