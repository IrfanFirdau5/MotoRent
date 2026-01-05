// FILE: motorent/lib/screens/admin/admin_driver_payments_page.dart
// CREATE THIS NEW FILE

// ignore_for_file: unused_field, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADD THIS
import '../../services/firebase_driver_payment_service.dart';
import '../../services/stripe_payment_service.dart';

class AdminDriverPaymentsPage extends StatefulWidget {
  final String adminId;

  const AdminDriverPaymentsPage({
    Key? key,
    required this.adminId,
  }) : super(key: key);

  @override
  State<AdminDriverPaymentsPage> createState() => _AdminDriverPaymentsPageState();
}

class _AdminDriverPaymentsPageState extends State<AdminDriverPaymentsPage> {
  final FirebaseDriverPaymentService _paymentService = FirebaseDriverPaymentService();
  final StripePaymentService _stripeService = StripePaymentService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingWithdrawals = [];
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      
      final pending = await _paymentService.getPendingWithdrawals();
      final stats = await _paymentService.getWithdrawalStatistics();


      setState(() {
        _pendingWithdrawals = pending;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _approveWithdrawal(Map<String, dynamic> withdrawal) async {
    final withdrawalId = withdrawal['withdrawal_id'];
    final amount = (withdrawal['amount'] as num).toDouble();
    final driverName = withdrawal['driver_name'];
    final driverEmail = withdrawal['driver_email'];
    final bankName = withdrawal['bank_name'];
    final accountNumber = withdrawal['account_number'];

    // Show payment method selection dialog
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card, color: Color(0xFF635BFF)),
              title: const Text('Stripe Transfer (Test Mode)'),
              subtitle: const Text('Automated payment via Stripe'),
              onTap: () => Navigator.pop(context, 'stripe'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.blue),
              title: const Text('Manual Bank Transfer'),
              subtitle: const Text('Transfer manually and enter reference'),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
          ],
        ),
      ),
    );

    if (paymentMethod == null) return;

    if (paymentMethod == 'stripe') {
      await _approveWithStripe(withdrawal);
    } else {
      await _approveManually(withdrawal);
    }
  }

  Future<void> _approveWithStripe(Map<String, dynamic> withdrawal) async {
    final withdrawalId = withdrawal['withdrawal_id'];
    final amount = (withdrawal['amount'] as num).toDouble();
    final driverName = withdrawal['driver_name'];
    final driverEmail = withdrawal['driver_email'];

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve with Stripe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver: $driverName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Amount: RM ${amount.toStringAsFixed(2)}'),
            Text('Email: $driverEmail'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test Mode: This will simulate a Stripe transfer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
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
              backgroundColor: const Color(0xFF635BFF),
            ),
            child: const Text(
              'Process with Stripe',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await _paymentService.approveWithdrawalWithStripe(
        withdrawalId: withdrawalId,
        adminId: widget.adminId,
        driverEmail: driverEmail,
        amount: amount,
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal processed via Stripe!\nRef: ${result['transfer_reference']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to process withdrawal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading if still open
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveManually(Map<String, dynamic> withdrawal) async {
    final withdrawalId = withdrawal['withdrawal_id'];
    final amount = (withdrawal['amount'] as num).toDouble();
    final driverName = withdrawal['driver_name'];
    final bankName = withdrawal['bank_name'];
    final accountNumber = withdrawal['account_number'];

        // Show transfer reference input
    final transferRef = await _showTransferReferenceDialog();
    
    if (transferRef == null) return;

    // Approve withdrawal
    try {
      final success = await _paymentService.approveWithdrawal(
        withdrawalId: withdrawalId,
        adminId: widget.adminId,
        transferReference: transferRef,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Withdrawal approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to approve withdrawal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showTransferReferenceDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Reference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the bank transfer reference number or transaction ID:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Reference Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectWithdrawal(Map<String, dynamic> withdrawal) async {
    final withdrawalId = withdrawal['withdrawal_id'];
    final driverName = withdrawal['driver_name'];

    // Show reason input dialog
    final reason = await _showRejectionReasonDialog();
    
    if (reason == null) return;

    try {
      final success = await _paymentService.rejectWithdrawal(
        withdrawalId: withdrawalId,
        adminId: widget.adminId,
        reason: reason,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Withdrawal rejected for $driverName'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject withdrawal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showRejectionReasonDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a reason for rejection:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawalDetails(Map<String, dynamic> withdrawal) {
    final amount = (withdrawal['amount'] as num).toDouble();
    final driverName = withdrawal['driver_name'];
    final driverEmail = withdrawal['driver_email'];
    final bankName = withdrawal['bank_name'];
    final accountNumber = withdrawal['account_number'];
    final accountHolder = withdrawal['account_holder_name'];
    final requestedAt = withdrawal['created_at'] as DateTime?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Withdrawal Details',
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
                    
                    _buildDetailRow('Driver', driverName, Icons.person),
                    _buildDetailRow('Email', driverEmail, Icons.email),
                    _buildDetailRow(
                      'Amount',
                      'RM ${amount.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                    _buildDetailRow('Bank', bankName, Icons.account_balance),
                    _buildDetailRow(
                      'Account Number',
                      accountNumber,
                      Icons.credit_card,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: accountNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account number copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildDetailRow(
                      'Account Holder',
                      accountHolder,
                      Icons.person_outline,
                    ),
                    if (requestedAt != null)
                      _buildDetailRow(
                        'Requested At',
                        DateFormat('dd MMM yyyy, HH:mm').format(requestedAt),
                        Icons.access_time,
                      ),
                    
                    const SizedBox(height: 30),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _rejectWithdrawal(withdrawal);
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _approveWithdrawal(withdrawal);
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Payments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 🐛 DEBUG: Button to check withdrawals directly
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh & Debug',
            onPressed: () async {
              
                final snapshot = await FirebaseFirestore.instance
                    .collection('driver_withdrawals')
                    .get();
                
                
                for (var doc in snapshot.docs) {
                  final data = doc.data();
                }
                
                
                final pendingSnapshot = await FirebaseFirestore.instance
                    .collection('driver_withdrawals')
                    .where('status', isEqualTo: 'pending')
                    .get();
                
                
              
              
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            _statistics['pending']?.toString() ?? '0',
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            _statistics['completed']?.toString() ?? '0',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Paid',
                            'RM ${(_statistics['total_completed'] ?? 0.0).toStringAsFixed(0)}',
                            Icons.attach_money,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Rejected',
                            _statistics['rejected']?.toString() ?? '0',
                            Icons.cancel,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Pending Withdrawals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pending Withdrawals',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_pendingWithdrawals.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_pendingWithdrawals.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_pendingWithdrawals.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No pending withdrawals',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._pendingWithdrawals.map((withdrawal) =>
                        _buildWithdrawalCard(withdrawal)
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> withdrawal) {
    final amount = (withdrawal['amount'] as num).toDouble();
    final driverName = withdrawal['driver_name'];
    final requestedAt = withdrawal['created_at'] as DateTime?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showWithdrawalDetails(withdrawal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    // ignore: deprecated_member_use
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    child: Text(
                      driverName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (requestedAt != null)
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(requestedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'RM ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectWithdrawal(withdrawal),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveWithdrawal(withdrawal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}