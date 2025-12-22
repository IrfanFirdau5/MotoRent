// FILE: motorent/lib/screens/customer/stripe_payment_page.dart
// CREATE THIS NEW FILE

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card; // ✅ FIXED: Hide Stripe's Card
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../../services/stripe_payment_service.dart';
import '../../services/firebase_booking_service.dart';
import 'booking_confirmation_page.dart';

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
  
  bool _isProcessing = false;
  bool _isStripeReady = false; // ✅ Track Stripe initialization
  CardFieldInputDetails? _cardDetails;

  @override
  void initState() {
    super.initState();
    _ensureStripeInitialized();
  }

  // ✅ Ensure Stripe is initialized before showing card field
  Future<void> _ensureStripeInitialized() async {
    try {
      // Check if publishable key is set
      if (Stripe.publishableKey.isEmpty || Stripe.publishableKey.contains('xxx')) {
        throw Exception('Stripe publishable key not set! Please update main.dart');
      }
      
      // Apply settings again to be safe
      await Stripe.instance.applySettings();
      
      setState(() {
        _isStripeReady = true;
      });
      
      print('✅ Stripe ready for payment page');
    } catch (e) {
      print('❌ Stripe initialization check failed: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment system error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handlePayment() async {
    // Validate card details
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
      // Create payment description
      final description = 'Booking #${widget.booking.bookingId} - '
          '${widget.vehicle.fullName} - '
          '${DateFormat('dd MMM').format(widget.booking.startDate)} to '
          '${DateFormat('dd MMM yyyy').format(widget.booking.endDate)}';

      // Process payment
      final result = await _paymentService.processPayment(
        amount: widget.booking.totalPrice,
        description: description,
      );

      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      if (result['success']) {
        // Payment successful - update booking in Firestore
        await _bookingService.updateBookingStatus(
          widget.booking.bookingId.toString(),
          'confirmed', // Change from pending to confirmed
        );

        // Navigate to confirmation page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmationPage(
              booking: widget.booking,
              vehicle: widget.vehicle,
            ),
          ),
        );
      } else {
        // Payment failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Payment failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Powered by Stripe',
                          style: TextStyle(
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
                  // Booking Summary Card
                  Card( // ✅ This is Flutter's Card widget - no conflict now!
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
                          'Amount to Pay',
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
                      // ✅ FIXED: Removed style parameter as it's not supported in newer versions
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        hintText: 'Card number, expiry, CVC',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Test Card Info
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

                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isProcessing || !_isStripeReady) ? null : _handlePayment, // ✅ Disable until ready
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
                              'Pay Now',
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