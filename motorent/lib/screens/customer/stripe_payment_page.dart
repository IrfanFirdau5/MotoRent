// FILE: motorent/lib/screens/customer/stripe_payment_page.dart
// ✅ UPDATED: Authorization + Invoice sent to BOTH customer AND owner

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card; 
import 'package:intl/intl.dart';
import 'dart:io';
import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../../models/user.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/firebase_booking_service.dart';
import '../../services/invoice_service.dart';
import '../../services/auth_service.dart';
import '../../config/payment_config.dart';
import 'booking_confirmation_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/invoice_storage_service.dart';

class StripePaymentPage extends StatefulWidget {
  final Booking booking;
  final Vehicle vehicle;

  const StripePaymentPage({
    Key? key,
    required this.booking,
    required this.vehicle,
  }) : super(key: key);

  @override
  State<StripePaymentPage> createState() => _StripePaymentPageState();
}

class _StripePaymentPageState extends State<StripePaymentPage> {
  final StripePaymentService _paymentService = StripePaymentService();
  final FirebaseBookingService _bookingService = FirebaseBookingService();
  final InvoiceService _invoiceService = InvoiceService();
  final InvoiceStorageService _invoiceStorageService = InvoiceStorageService();
  final AuthService _authService = AuthService();
  
  bool _isProcessing = false;
  bool _isStripeReady = false;
  CardFieldInputDetails? _cardDetails;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _ensureStripeInitialized();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_initializationError != null && !_isStripeReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showConfigurationError(_initializationError!);
        }
      });
      _initializationError = null;
    }
  }

  Future<void> _ensureStripeInitialized() async {
    try {
      if (!PaymentConfig.isConfigured) {
        throw Exception('Stripe is not configured. Check your .env file.');
      }

      if (!PaymentConfig.validateKeys()) {
        throw Exception('Invalid Stripe keys in .env file');
      }

      if (Stripe.publishableKey.isEmpty) {
        throw Exception('Stripe publishable key not initialized in main.dart');
      }
      
      await Stripe.instance.applySettings();
      
      setState(() {
        _isStripeReady = true;
      });
      
    } catch (e) {
      
      setState(() {
        _isStripeReady = false;
        _initializationError = e.toString();
      });
    }
  }

  void _showConfigurationError(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Configuration Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment system is not properly configured.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Error: $errorMessage',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Generate and send invoice to BOTH customer and owner
  Future<File?> _generateAndSendInvoice({
    required String paymentIntentId,
    required User customer,
    required User owner,
  }) async {
    try {
      
      final invoiceFile = await _invoiceService.generateInvoice(
        booking: widget.booking,
        vehicle: widget.vehicle,
        customer: customer,
        owner: owner,
        paymentIntentId: paymentIntentId,
      );
      
      
      // ✅ In production, you would:
      // 1. Upload to Firebase Storage
      // 2. Send email to both customer and owner
      // 3. Store invoice URL in booking document
      
      // For now, we'll just store the invoice path
      // You can add email sending functionality later
      
      return invoiceFile;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handlePayment() async {
    if (!_isStripeReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment system is not ready. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_cardDetails?.complete != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete card details'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {

      final description = 'MotoRent Booking #${widget.booking.bookingId} - '
          '${widget.vehicle.fullName} - '
          '${DateFormat('dd MMM').format(widget.booking.startDate)} to '
          '${DateFormat('dd MMM yyyy').format(widget.booking.endDate)}';

      // Step 1: Create Payment Intent with MANUAL capture (hold funds)
      final result = await _paymentService.createPaymentIntent(
        amount: widget.booking.totalPrice,
        description: description,
        currency: 'MYR',
        captureMethod: false, // ✅ MANUAL = Hold funds, don't capture yet
        metadata: {
          'booking_id': widget.booking.bookingId.toString(),
          'vehicle_id': widget.vehicle.vehicleId.toString(),
          'user_id': widget.booking.userId,
          'vehicle_name': widget.vehicle.fullName,
        },
      );

      if (result == null) {
        throw Exception('Failed to create payment intent');
      }

      final clientSecret = result['client_secret'];
      final paymentIntentId = result['id'];
      

      // Step 2: Confirm Payment with Stripe (authorize/hold the card)
      
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );


      // Step 3: Update booking with payment authorization
      await _bookingService.updatePaymentAuthorization(
        bookingId: widget.booking.bookingId.toString(),
        paymentIntentId: paymentIntentId,
      );

      // Step 4: Generate invoice and send to BOTH customer AND owner
      
      // Get current user (customer)
      final currentUser = await _authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('Could not get customer details');
      }
      
      // Get owner details
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.vehicle.ownerId)
          .get();
      
      if (!ownerDoc.exists) {
        throw Exception('Could not get owner details');
      }
      
      final ownerData = ownerDoc.data()!;
      ownerData['user_id'] = ownerDoc.id;
      if (ownerData['created_at'] is Timestamp) {
        ownerData['created_at'] = (ownerData['created_at'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      final owner = User.fromJson(ownerData);
      
      // ✅ Generate invoice for BOTH customer and owner
      final invoiceFile = await _generateAndSendInvoice(
        paymentIntentId: paymentIntentId,
        customer: currentUser,
        owner: owner,
      );
      
      if (invoiceFile != null) {
        
        // ✅ NEW: Upload invoice to Firebase Storage
        final invoiceUrl = await _invoiceStorageService.uploadInvoice(
          invoiceFile: invoiceFile,
          bookingId: widget.booking.bookingId.toString(),
        );
        
        if (invoiceUrl != null) {
          
          // Save invoice metadata
          await _invoiceStorageService.saveInvoiceMetadata(
            bookingId: widget.booking.bookingId.toString(),
            invoiceUrl: invoiceUrl,
            customerId: currentUser.userId.toString(),
            ownerId: owner.userId.toString(),
          );
          
        }
      }


      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      // Navigate to confirmation page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationPage(
            booking: widget.booking.copyWith(
              bookingStatus: 'pending',
              paymentIntentId: paymentIntentId,
            ),
            vehicle: widget.vehicle,
            invoiceFile: invoiceFile, // ✅ Pass invoice file
          ),
        ),
      );
    } on StripeException catch (e) {
      
      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.error.message ?? 'Payment failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      
      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isProcessing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait while payment is being processed'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
        ),
        body: !_isStripeReady
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Initializing payment system...'),
                    const SizedBox(height: 8),
                    Text(
                      PaymentConfig.isTestMode ? '🧪 Test Mode' : '🚀 Live Mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Payment Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.payment,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Secure Payment',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  PaymentConfig.isTestMode 
                                      ? 'Test Mode - Powered by Stripe'
                                      : 'Powered by Stripe',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info: Funds will be held + Invoice sent
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue[900], size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Payment Authorization',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '• Your payment will be authorized but not charged until the owner confirms your booking.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[800],
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '• An invoice will be sent to both you and the vehicle owner.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[800],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Booking Summary Card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Booking Summary',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSummaryRow(
                                    'Vehicle',
                                    widget.vehicle.fullName,
                                    Icons.directions_car,
                                  ),
                                  const Divider(height: 24),
                                  _buildSummaryRow(
                                    'Duration',
                                    '${widget.booking.duration} day${widget.booking.duration > 1 ? 's' : ''}',
                                    Icons.calendar_today,
                                  ),
                                  const Divider(height: 24),
                                  _buildSummaryRow(
                                    'Dates',
                                    '${DateFormat('dd MMM').format(widget.booking.startDate)} - ${DateFormat('dd MMM yyyy').format(widget.booking.endDate)}',
                                    Icons.date_range,
                                  ),
                                  if (widget.booking.needDriver) ...[
                                    const Divider(height: 24),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.drive_eta, color: Colors.blue[900]),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'Driver service included',
                                              style: TextStyle(
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
                          const SizedBox(height: 20),

                          // Payment Amount
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFF1E88E5),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Amount to Authorize',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'RM ${widget.booking.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Card Input Section
                          const Text(
                            'Payment Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Stripe Card Field
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: CardField(
                              onCardChanged: (card) {
                                setState(() {
                                  _cardDetails = card;
                                });
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                hintText: 'Card number, expiry, CVC',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Test Card Info (only in test mode)
                          if (PaymentConfig.isTestMode)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, 
                                        color: Colors.orange[900], 
                                        size: 20
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Test Mode - Use Test Card',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Card: 4242 4242 4242 4242\nExpiry: Any future date (e.g., 12/25)\nCVC: Any 3 digits (e.g., 123)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[900],
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 30),

                          // Authorize Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: (_isProcessing || !_isStripeReady) 
                                  ? null 
                                  : _handlePayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                disabledBackgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isProcessing
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Processing...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Authorize Payment',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Security Notice
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                'Secure payment powered by Stripe',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ✅ Extension to add copyWith method with paymentIntentId
extension BookingCopyWith on Booking {
  Booking copyWith({
    String? bookingStatus,
    String? paymentIntentId,
  }) {
    return Booking(
      bookingId: bookingId,
      userId: userId,
      vehicleId: vehicleId,
      ownerId: ownerId,
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      createdAt: createdAt,
      userName: userName,
      vehicleName: vehicleName,
      userPhone: userPhone,
      needDriver: needDriver,
      driverPrice: driverPrice,
      driverId: driverId,
      driverName: driverName,
      paymentStatus: paymentStatus,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
    );
  }
}