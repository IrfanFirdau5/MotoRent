import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/firebase_admin_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AdminMonthlyReportPage extends StatefulWidget {
  const AdminMonthlyReportPage({Key? key}) : super(key: key);

  @override
  State<AdminMonthlyReportPage> createState() => _AdminMonthlyReportPageState();
}

class _AdminMonthlyReportPageState extends State<AdminMonthlyReportPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime _selectedMonth = DateTime.now();

  final FirebaseAdminService _adminService = FirebaseAdminService();
  // Report data
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final reportData = await _adminService.getMonthlyReportData(
        _selectedMonth.month,
        _selectedMonth.year,
      );

      setState(() {
        _reportData = reportData;
        _reportData['month'] = DateFormat('MMMM yyyy').format(_selectedMonth);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load report data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = picked;
      });
      _loadReportData();
    }
  }

  Future<void> _exportReport() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating PDF Report...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Generate PDF
      final pdf = await _generatePDF();
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Save and share the PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'MotoRent_Report_${DateFormat('MMMM_yyyy').format(_selectedMonth)}.pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final revenue = _reportData['revenue'];
    final expenses = _reportData['expenses'];
    final users = _reportData['users'];
    final vehicles = _reportData['vehicles'];
    final bookings = _reportData['bookings'];
    final issues = _reportData['issues'];
    final ratings = _reportData['ratings'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MotoRent Monthly Report',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _reportData['month'],
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Financial Overview
            _buildPDFSection('Financial Overview'),
            pw.SizedBox(height: 15),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildPDFStatBox(
                    'Total Revenue',
                    'RM ${NumberFormat('#,##0.00').format(revenue['total'])}',
                    '+${revenue['growth_percentage']}% vs last month',
                    PdfColors.green,
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: _buildPDFStatBox(
                    'Total Expenses',
                    'RM ${NumberFormat('#,##0.00').format(expenses['total'])}',
                    '',
                    PdfColors.orange,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            _buildPDFStatBox(
              'Net Profit',
              'RM ${NumberFormat('#,##0.00').format(_reportData['profit'])}',
              '${_reportData['profit_margin'].toStringAsFixed(1)}% profit margin',
              PdfColors.blue,
            ),
            pw.SizedBox(height: 30),

            // Revenue Breakdown
            _buildPDFSection('Revenue Breakdown'),
            pw.SizedBox(height: 15),
            _buildPDFTable([
              ['Source', 'Amount', 'Percentage'],
              [
                'Vehicle Rentals',
                'RM ${NumberFormat('#,##0.00').format(revenue['vehicle_rentals'])}',
                '${((revenue['vehicle_rentals'] / revenue['total']) * 100).toStringAsFixed(1)}%'
              ],
              [
                'Driver Services',
                'RM ${NumberFormat('#,##0.00').format(revenue['driver_services'])}',
                '${((revenue['driver_services'] / revenue['total']) * 100).toStringAsFixed(1)}%'
              ],
            ]),
            pw.SizedBox(height: 30),

            // User Statistics
            _buildPDFSection('User Statistics'),
            pw.SizedBox(height: 15),
            _buildPDFTable([
              ['Metric', 'Count'],
              ['New Registrations', '${users['new_registrations']}'],
              ['Total Users', '${users['total_users']}'],
              ['Active Users', '${users['active_users']}'],
              ['New Customers', '${users['by_type']['customers']}'],
              ['New Owners', '${users['by_type']['owners']}'],
              ['New Drivers', '${users['by_type']['drivers']}'],
            ]),
            pw.SizedBox(height: 30),

            // Vehicle Statistics
            _buildPDFSection('Vehicle Statistics'),
            pw.SizedBox(height: 15),
            _buildPDFTable([
              ['Metric', 'Count'],
              ['Total Vehicles', '${vehicles['total_listed']}'],
              ['New Listings', '${vehicles['new_listings']}'],
              ['Active Listings', '${vehicles['active_listings']}'],
              ['Pending Approval', '${vehicles['pending_approval']}'],
            ]),
            pw.SizedBox(height: 30),

            // Booking Statistics
            _buildPDFSection('Booking Statistics'),
            pw.SizedBox(height: 15),
            _buildPDFTable([
              ['Metric', 'Count'],
              ['Total Bookings', '${bookings['total']}'],
              ['Completed', '${bookings['completed']}'],
              ['Ongoing', '${bookings['ongoing']}'],
              ['Cancelled', '${bookings['cancelled']} (${bookings['cancellation_rate']}%)'],
            ]),
            pw.SizedBox(height: 30),

            // Issues & Ratings
            _buildPDFSection('Issues & Support'),
            pw.SizedBox(height: 15),
            _buildPDFTable([
              ['Metric', 'Value'],
              ['Total Reports', '${issues['total_reports']}'],
              ['Resolved', '${issues['resolved']}'],
              ['Pending', '${issues['pending']}'],
              ['Resolution Rate', '${issues['resolution_rate']}%'],
              ['Avg Vehicle Rating', '${ratings['average_vehicle_rating'].toStringAsFixed(1)} ⭐'],
              ['Avg Driver Rating', '${ratings['average_driver_rating'].toStringAsFixed(1)} ⭐'],
              ['Total Reviews', '${ratings['total_reviews']}'],
            ]),
            pw.SizedBox(height: 30),

            // Top Vehicles
            _buildPDFSection('Top Performing Vehicles'),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              context: null,
              data: [
                ['Rank', 'Vehicle', 'Bookings', 'Revenue'],
                ..._buildTopVehiclesRows(),
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue700,
              ),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
            ),
            pw.SizedBox(height: 30),

            // Top Owners
            _buildPDFSection('Top Performing Owners'),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              context: null,
              data: [
                ['Rank', 'Owner', 'Vehicles', 'Revenue'],
                ..._buildTopOwnersRows(),
              ],
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue700,
              ),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
            ),

            // Footer
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'End of Report - Generated by MotoRent Admin System',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  List<List<String>> _buildTopVehiclesRows() {
    final topVehicles = (_reportData['top_vehicles'] as List?) ?? [];
    final List<List<String>> rows = [];
    
    if (topVehicles.isEmpty) {
      rows.add(['1', 'No data available', '0', 'RM 0.00']);
      return rows;
    }
    
    for (int i = 0; i < topVehicles.length; i++) {
      final vehicle = topVehicles[i] as Map<String, dynamic>;
      rows.add([
        '${i + 1}',
        vehicle['name']?.toString() ?? 'Unknown',
        '${vehicle['bookings'] ?? 0}',
        'RM ${NumberFormat('#,##0.00').format(vehicle['revenue'] ?? 0.0)}',
      ]);
    }
    
    return rows;
  }

  List<List<String>> _buildTopOwnersRows() {
    final topOwners = (_reportData['top_owners'] as List?) ?? [];
    final List<List<String>> rows = [];
    
    if (topOwners.isEmpty) {
      rows.add(['1', 'No data available', '0', 'RM 0.00']);
      return rows;
    }
    
    for (int i = 0; i < topOwners.length; i++) {
      final owner = topOwners[i] as Map<String, dynamic>;
      rows.add([
        '${i + 1}',
        owner['name']?.toString() ?? 'Unknown',
        '${owner['vehicles'] ?? 0}',
        'RM ${NumberFormat('#,##0.00').format(owner['revenue'] ?? 0.0)}',
      ]);
    }
    
    return rows;
  }

  pw.Widget _buildPDFSection(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.blue700,
            width: 2,
          ),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue700,
        ),
      ),
    );
  }

  pw.Widget _buildPDFStatBox(String label, String value, String subtitle, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPDFTable(List<List<String>> data) {
    return pw.Table.fromTextArray(
      context: null,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue700,
      ),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
      ),
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
      ),
    );
  }
  // CONTINUATION OF admin_monthly_report_page.dart
  // Add this after the PDF generation methods

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monthly Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
            onPressed: _isLoading ? null : _exportReport,
          ),
        ],
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
                        onPressed: _loadReportData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReportData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month Selector
                        _buildMonthSelector(),
                        const SizedBox(height: 20),

                        // Financial Overview
                        _buildSectionTitle('Financial Overview'),
                        const SizedBox(height: 12),
                        _buildFinancialCards(),
                        const SizedBox(height: 20),

                        // Revenue Breakdown
                        _buildSectionTitle('Revenue Breakdown'),
                        const SizedBox(height: 12),
                        _buildRevenueBreakdown(),
                        const SizedBox(height: 20),

                        // User Statistics
                        _buildSectionTitle('User Statistics'),
                        const SizedBox(height: 12),
                        _buildUserStats(),
                        const SizedBox(height: 20),

                        // Vehicle Statistics
                        _buildSectionTitle('Vehicle Statistics'),
                        const SizedBox(height: 12),
                        _buildVehicleStats(),
                        const SizedBox(height: 20),

                        // Booking Statistics
                        _buildSectionTitle('Booking Statistics'),
                        const SizedBox(height: 12),
                        _buildBookingStats(),
                        const SizedBox(height: 20),

                        // Issues & Support
                        _buildSectionTitle('Issues & Support'),
                        const SizedBox(height: 12),
                        _buildIssuesStats(),
                        const SizedBox(height: 20),

                        // Top Performers
                        _buildSectionTitle('Top Performers'),
                        const SizedBox(height: 12),
                        _buildTopPerformers(),
                        const SizedBox(height: 20),

                        // Export Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _exportReport,
                            icon: const Icon(Icons.file_download),
                            label: const Text(
                              'Export Full Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _selectMonth,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF1E88E5),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Period',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _reportData['month'] ?? 'Select Month',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFinancialCards() {
    final revenue = _reportData['revenue'] ?? {};
    final expenses = _reportData['expenses'] ?? {};
    final profit = _reportData['profit'] ?? 0.0;
    final profitMargin = _reportData['profit_margin'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Revenue',
                'RM ${NumberFormat('#,##0.00').format(revenue['total'] ?? 0.0)}',
                Icons.trending_up,
                Colors.green,
                subtitle: '+${revenue['growth_percentage'] ?? 0}% vs last month',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Expenses',
                'RM ${NumberFormat('#,##0.00').format(expenses['total'] ?? 0.0)}',
                Icons.trending_down,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Net Profit',
                'RM ${NumberFormat('#,##0.00').format(profit)}',
                Icons.account_balance_wallet,
                Colors.blue,
                subtitle: '${profitMargin.toStringAsFixed(1)}% margin',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown() {
    final revenue = _reportData['revenue'] ?? {};
    final expenses = _reportData['expenses'] ?? {};

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
            const Text(
              'Revenue Sources',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBreakdownItem(
              'Vehicle Rentals',
              (revenue['vehicle_rentals'] ?? 0.0).toDouble(),
              (revenue['total'] ?? 1.0).toDouble(),
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'Driver Services',
              (revenue['driver_services'] ?? 0.0).toDouble(),
              (revenue['total'] ?? 1.0).toDouble(),
              Colors.green,
            ),
            const Divider(height: 32),
            const Text(
              'Expense Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBreakdownItem(
              'Maintenance',
              (expenses['maintenance'] ?? 0.0).toDouble(),
              (expenses['total'] ?? 1.0).toDouble(),
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'Insurance',
              (expenses['insurance'] ?? 0.0).toDouble(),
              (expenses['total'] ?? 1.0).toDouble(),
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'Platform Fees',
              (expenses['platform_fees'] ?? 0.0).toDouble(),
              (expenses['total'] ?? 1.0).toDouble(),
              Colors.purple,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              'Marketing',
              (expenses['marketing'] ?? 0.0).toDouble(),
              (expenses['total'] ?? 1.0).toDouble(),
              Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, double amount, double total, Color color) {
    final percentage = total > 0 ? (amount / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'RM ${NumberFormat('#,##0.00').format(amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserStats() {
    final users = _reportData['users'] ?? {};
    final byType = users['by_type'] ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'New Users',
                '${users['new_registrations'] ?? 0}',
                Icons.person_add,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Users',
                '${users['total_users'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Active Users', '${users['active_users'] ?? 0}', Icons.check_circle),
                const Divider(height: 24),
                _buildInfoRow('New Customers', '${byType['customers'] ?? 0}', Icons.person),
                const SizedBox(height: 8),
                _buildInfoRow('New Owners', '${byType['owners'] ?? 0}', Icons.business),
                const SizedBox(height: 8),
                _buildInfoRow('New Drivers', '${byType['drivers'] ?? 0}', Icons.drive_eta),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleStats() {
    final vehicles = _reportData['vehicles'] ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Vehicles',
                '${vehicles['total_listed'] ?? 0}',
                Icons.directions_car,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'New Listings',
                '${vehicles['new_listings'] ?? 0}',
                Icons.add_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Active Listings', '${vehicles['active_listings'] ?? 0}', Icons.check_circle),
                const SizedBox(height: 12),
                _buildInfoRow('Pending Approval', '${vehicles['pending_approval'] ?? 0}', Icons.pending),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingStats() {
    final bookings = _reportData['bookings'] ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Bookings',
                '${bookings['total'] ?? 0}',
                Icons.book_online,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                '${bookings['completed'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Ongoing', '${bookings['ongoing'] ?? 0}', Icons.pending_actions),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Cancelled',
                  '${bookings['cancelled'] ?? 0} (${bookings['cancellation_rate'] ?? '0'}%)',
                  Icons.cancel,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIssuesStats() {
    final issues = _reportData['issues'] ?? {};
    final ratings = _reportData['ratings'] ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Reports',
                '${issues['total_reports'] ?? 0}',
                Icons.report_problem,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Resolved',
                '${issues['resolved'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Pending Issues', '${issues['pending'] ?? 0}', Icons.pending),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Resolution Rate',
                  '${issues['resolution_rate'] ?? '0'}%',
                  Icons.trending_up,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  'Avg Vehicle Rating',
                  '${(ratings['average_vehicle_rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
                  Icons.star,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Avg Driver Rating',
                  '${(ratings['average_driver_rating'] ?? 0.0).toStringAsFixed(1)} ⭐',
                  Icons.drive_eta,
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Total Reviews', '${ratings['total_reviews'] ?? 0}', Icons.rate_review),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformers() {
    final topVehicles = (_reportData['top_vehicles'] as List?) ?? [];
    final topOwners = (_reportData['top_owners'] as List?) ?? [];

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text(
                      'Top Vehicles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (topVehicles.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No vehicle data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...topVehicles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final vehicle = entry.value as Map<String, dynamic>;
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? Colors.amber
                                    : index == 1
                                        ? Colors.grey[400]
                                        : Colors.orange[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle['name']?.toString() ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${vehicle['bookings'] ?? 0} bookings',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'RM ${NumberFormat('#,##0').format(vehicle['revenue'] ?? 0.0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text(
                      'Top Owners',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (topOwners.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No owner data available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...topOwners.asMap().entries.map((entry) {
                    final index = entry.key;
                    final owner = entry.value as Map<String, dynamic>;
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? Colors.amber
                                    : index == 1
                                        ? Colors.grey[400]
                                        : Colors.orange[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    owner['name']?.toString() ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${owner['vehicles'] ?? 0} vehicles',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'RM ${NumberFormat('#,##0').format(owner['revenue'] ?? 0.0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}