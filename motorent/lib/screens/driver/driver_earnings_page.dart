import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/driver_earning.dart';
import '../../services/driver_service.dart';

class DriverEarningsPage extends StatefulWidget {
  final User driver;

  const DriverEarningsPage({
    Key? key,
    required this.driver,
  }) : super(key: key);

  @override
  State<DriverEarningsPage> createState() => _DriverEarningsPageState();
}

class _DriverEarningsPageState extends State<DriverEarningsPage> {
  final DriverService _driverService = DriverService();
  
  List<DriverEarning> _earnings = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  double _totalEarnings = 0.0;
  double _thisMonthEarnings = 0.0;
  double _pendingEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final earnings = await _driverService.fetchEarnings(widget.driver.userId);
      
      setState(() {
        _earnings = earnings;
        _calculateTotals();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load earnings: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateTotals() {
    _totalEarnings = _earnings.fold(0.0, (sum, earning) => sum + earning.amount);
    
    final now = DateTime.now();
    _thisMonthEarnings = _earnings
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, earning) => sum + earning.amount);
    
    _pendingEarnings = _earnings
        .where((e) => e.status == 'pending')
        .fold(0.0, (sum, earning) => sum + earning.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Earnings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: SpinKitFadingCircle(
                color: const Color(0xFF1E88E5),
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
                        onPressed: _loadEarnings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEarnings,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Earnings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'RM ${_totalEarnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'This Month',
                                'RM ${_thisMonthEarnings.toStringAsFixed(2)}',
                                Icons.calendar_month,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Pending',
                                'RM ${_pendingEarnings.toStringAsFixed(2)}',
                                Icons.pending,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Payment Notice (Since payment system not implemented)
                        Card(
                          color: Colors.blue[50],
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Payment withdrawal system coming soon. Your earnings are being tracked.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Earnings History
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Earnings History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_earnings.length} transactions',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_earnings.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No earnings yet',
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
                          ..._earnings.map((earning) => _buildEarningCard(earning)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(String label, String amount, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningCard(DriverEarning earning) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(earning.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(earning.status),
                color: _getStatusColor(earning.status),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    earning.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(earning.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(earning.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      earning.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(earning.status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'RM ${earning.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'processing':
        return Icons.sync;
      default:
        return Icons.info;
    }
  }
}