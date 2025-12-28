// FILE PATH: motorent/lib/screens/owner/revenue_overview_page.dart
// ✅ UPDATED: Uses vehicle_revenue collection

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/vehicle_revenue_tracking_service.dart';

class RevenueOverviewPage extends StatefulWidget {
  final int ownerId;

  const RevenueOverviewPage({
    Key? key,
    required this.ownerId,
  }) : super(key: key);

  @override
  State<RevenueOverviewPage> createState() => _RevenueOverviewPageState();
}

class _RevenueOverviewPageState extends State<RevenueOverviewPage> {
  final VehicleRevenueTrackingService _revenueService = VehicleRevenueTrackingService();
  
  bool _isLoading = true;
  List<VehicleRevenue> _vehicleRevenues = [];
  double _totalMonthlyRevenue = 0;
  double _totalMonthlyPayment = 0;
  double _netProfit = 0;
  int _profitableVehicles = 0;
  int _losingVehicles = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  String _generateAdvice(VehicleRevenue vehicle) {
    if (vehicle.isProfit) {
      if (vehicle.utilizationRate >= 0.8) {
        return "🌟 Excellent Performance! Consider adding more ${vehicle.vehicleName} units to your fleet to maximize profits.";
      } else if (vehicle.utilizationRate >= 0.6) {
        return "📈 Good Performance! Increase marketing to boost utilization from ${(vehicle.utilizationRate * 100).toStringAsFixed(0)}% to 80%+.";
      } else {
        return "📢 Underutilized! Profitable but only ${(vehicle.utilizationRate * 100).toStringAsFixed(0)}% utilized. Implement aggressive marketing.";
      }
    } else {
      double lossPercentage = vehicle.monthlyPayment > 0 ? (vehicle.profitLoss.abs() / vehicle.monthlyPayment) * 100 : 0;
      
      if (vehicle.utilizationRate >= 0.7) {
        double rateIncrease = vehicle.utilizationRate > 0 ? ((vehicle.profitLoss.abs() / 30) / vehicle.utilizationRate) : 0;
        return "💰 Pricing Adjustment Needed! High utilization but losing RM ${vehicle.profitLoss.abs().toStringAsFixed(2)}/month. Increase daily rate by RM ${rateIncrease.toStringAsFixed(2)}.";
      } else if (vehicle.utilizationRate >= 0.4) {
        return "⚠️ Action Required! Low utilization causing RM ${vehicle.profitLoss.abs().toStringAsFixed(2)} monthly loss. Reduce price or improve marketing.";
      } else {
        if (lossPercentage > 50) {
          return "🚨 Critical: Consider Selling! ${(vehicle.utilizationRate * 100).toStringAsFixed(0)}% utilized with ${lossPercentage.toStringAsFixed(0)}% loss. Save RM ${(vehicle.profitLoss.abs() * 12).toStringAsFixed(2)}/year.";
        } else {
          return "⚡ Urgent! Very low utilization (${(vehicle.utilizationRate * 100).toStringAsFixed(0)}%). Aggressive action needed.";
        }
      }
    }
  }

  String _generateOverallInsights() {
    if (_profitableVehicles == 0) {
      return "⚠️ URGENT: All vehicles losing money. Review pricing strategy immediately.";
    } else if (_losingVehicles == 0) {
      return "🎉 EXCELLENT: All vehicles profitable! Focus on scaling.";
    } else {
      double profitRatio = _profitableVehicles / _vehicleRevenues.length;
      if (profitRatio >= 0.7) {
        return "✅ STRONG: $_profitableVehicles/${_vehicleRevenues.length} profitable. Fix underperformers.";
      } else {
        return "📊 MIXED: $_profitableVehicles/${_vehicleRevenues.length} profitable. Turn around loss-makers.";
      }
    }
  }

  Future<void> _loadRevenueData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      print('🔍 Loading revenue from vehicle_revenue collection');

      final now = DateTime.now();
      
      // ✅ Fetch from vehicle_revenue collection
      final revenueData = await _revenueService.getOwnerRevenueForMonth(
        ownerId: currentUser.uid,
        month: now.month,
        year: now.year,
      );

      print('📦 Found ${revenueData.length} revenue records');

      if (revenueData.isEmpty) {
        print('ℹ️  No revenue data - checking if backfill needed...');
        
        // Check if there are completed bookings that haven't been recorded
        final completedBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('owner_id', isEqualTo: currentUser.uid)
            .where('booking_status', isEqualTo: 'completed')
            .where('revenue_recorded', isEqualTo: false)
            .limit(1)
            .get();
        
        if (completedBookings.docs.isNotEmpty) {
          print('⚠️  Found unrecorded bookings - suggesting backfill');
          setState(() {
            _errorMessage = 'Revenue data needs to be backfilled. Tap the refresh button to backfill.';
            _isLoading = false;
          });
          return;
        }
      }

      List<VehicleRevenue> vehicleRevenues = [];
      double totalRevenue = 0;
      double totalPayment = 0;
      int profitable = 0;
      int losing = 0;

      for (var data in revenueData) {
        final revenue = VehicleRevenue(
          vehicleId: data['vehicle_id'] ?? '',
          vehicleName: data['vehicle_name'] ?? 'Unknown Vehicle',
          licensePlate: data['license_plate'] ?? '',
          monthlyRevenue: (data['total_revenue'] as num?)?.toDouble() ?? 0.0,
          monthlyPayment: (data['total_monthly_payment'] as num?)?.toDouble() ?? 0.0,
          bookingsThisMonth: (data['total_bookings'] as num?)?.toInt() ?? 0,
          averageBookingValue: (data['average_booking_value'] as num?)?.toDouble() ?? 0.0,
          utilizationRate: (data['utilization_rate'] as num?)?.toDouble() ?? 0.0,
        );

        vehicleRevenues.add(revenue);
        totalRevenue += revenue.monthlyRevenue;
        totalPayment += revenue.monthlyPayment;

        if (revenue.isProfit) {
          profitable++;
        } else {
          losing++;
        }
      }

      print('✅ Revenue loaded successfully');

      setState(() {
        _vehicleRevenues = vehicleRevenues;
        _totalMonthlyRevenue = totalRevenue;
        _totalMonthlyPayment = totalPayment;
        _netProfit = totalRevenue - totalPayment;
        _profitableVehicles = profitable;
        _losingVehicles = losing;
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      print('❌ Error: $e\n$stackTrace');
      setState(() {
        _errorMessage = 'Failed to load revenue data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _backfillRevenue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backfill Revenue Data'),
        content: const Text(
          'This will process all completed bookings and populate revenue data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Backfill'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final result = await _revenueService.backfillAllRevenue(currentUser.uid);

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backfilled ${result['successful']} bookings successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRevenueData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backfill failed: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generatePDFReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final monthYear = DateFormat('MMMM yyyy').format(now);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text('MotoRent Revenue Report', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
            pw.Text(monthYear),
            pw.SizedBox(height: 20),
            pw.Text('Total Revenue: RM ${_totalMonthlyRevenue.toStringAsFixed(2)}'),
            pw.Text('Total Payments: RM ${_totalMonthlyPayment.toStringAsFixed(2)}'),
            pw.Text('Net Profit: RM ${_netProfit.toStringAsFixed(2)}'),
            pw.SizedBox(height: 20),
            ..._vehicleRevenues.map((v) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(v.vehicleName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Revenue: RM ${v.monthlyRevenue.toStringAsFixed(2)}'),
                  pw.Text('Profit/Loss: RM ${v.profitLoss.toStringAsFixed(2)}'),
                  pw.Divider(),
                ],
              ),
            )),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Revenue_${DateFormat('yyyy_MM_dd').format(now)}.pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generated!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Overview'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          if (_errorMessage.contains('backfill'))
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: _backfillRevenue,
              tooltip: 'Backfill Revenue',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRevenueData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _errorMessage.contains('backfill') ? Icons.sync_problem : Icons.error_outline,
                        size: 60,
                        color: _errorMessage.contains('backfill') ? Colors.orange : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_errorMessage, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage.contains('backfill'))
                        ElevatedButton.icon(
                          onPressed: _backfillRevenue,
                          icon: const Icon(Icons.sync),
                          label: const Text('Backfill Revenue Data'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        )
                      else
                        ElevatedButton(onPressed: _loadRevenueData, child: const Text('Retry')),
                    ],
                  ),
                )
              : _vehicleRevenues.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('No revenue data available', style: TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Complete bookings to see revenue', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRevenueData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard('Total Revenue', 'RM ${_totalMonthlyRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.green)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildSummaryCard('Total Payments', 'RM ${_totalMonthlyPayment.toStringAsFixed(2)}', Icons.payment, Colors.orange)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildSummaryCard('Net Profit', 'RM ${_netProfit.toStringAsFixed(2)}', Icons.trending_up, _netProfit >= 0 ? Colors.green : Colors.red)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildSummaryCard('Margin', '${_totalMonthlyRevenue > 0 ? ((_netProfit / _totalMonthlyRevenue) * 100).toStringAsFixed(1) : '0.0'}%', Icons.percent, _netProfit >= 0 ? Colors.blue : Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Vehicle Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildPerformanceIndicator('Profitable', _profitableVehicles, Colors.green),
                                      _buildPerformanceIndicator('Losing', _losingVehicles, Colors.red),
                                      _buildPerformanceIndicator('Total', _vehicleRevenues.length, Colors.blue),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Vehicle Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                                      const SizedBox(width: 6),
                                      Text(DateFormat('MMM yyyy').format(DateTime.now()), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._vehicleRevenues.map((v) => _buildVehicleRevenueCard(v)),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
      floatingActionButton: _vehicleRevenues.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _generatePDFReport,
              backgroundColor: const Color(0xFF1E88E5),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text('Generate Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
          child: Center(child: Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color))),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildVehicleRevenueCard(VehicleRevenue vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.vehicleName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(vehicle.licensePlate, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: vehicle.isProfit ? Colors.green : Colors.red, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(vehicle.isProfit ? Icons.trending_up : Icons.trending_down, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(vehicle.isProfit ? 'PROFIT' : 'LOSS', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  _buildFinancialRow('Revenue', 'RM ${vehicle.monthlyRevenue.toStringAsFixed(2)}', Colors.green),
                  const Divider(height: 16),
                  _buildFinancialRow('Payment', 'RM ${vehicle.monthlyPayment.toStringAsFixed(2)}', Colors.orange),
                  const Divider(height: 16),
                  _buildFinancialRow('Net ${vehicle.isProfit ? "Profit" : "Loss"}', 'RM ${vehicle.profitLoss.abs().toStringAsFixed(2)}', vehicle.isProfit ? Colors.green : Colors.red, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMetricBox('Bookings', vehicle.bookingsThisMonth.toString(), Icons.calendar_today)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricBox('Avg', 'RM ${vehicle.averageBookingValue.toStringAsFixed(0)}', Icons.attach_money)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricBox('Used', '${(vehicle.utilizationRate * 100).toStringAsFixed(0)}%', Icons.speed)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isBold ? 18 : 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1E88E5)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class VehicleRevenue {
  final String vehicleId;
  final String vehicleName;
  final String licensePlate;
  final double monthlyRevenue;
  final double monthlyPayment;
  final int bookingsThisMonth;
  final double averageBookingValue;
  final double utilizationRate;

  VehicleRevenue({
    required this.vehicleId,
    required this.vehicleName,
    required this.licensePlate,
    required this.monthlyRevenue,
    required this.monthlyPayment,
    required this.bookingsThisMonth,
    required this.averageBookingValue,
    required this.utilizationRate,
  });

  double get profitLoss => monthlyRevenue - monthlyPayment;
  bool get isProfit => profitLoss > 0;
}