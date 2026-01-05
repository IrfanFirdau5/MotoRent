// FILE: motorent/lib/screens/owner/subscription_payment_page.dart
// CREATE THIS NEW FILE

// FILE: motorent/lib/screens/owner/subscription_payment_page.dart
// CREATE THIS NEW FILE

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../services/subscription_service.dart';
import '../../services/stripe_payment_service.dart';

class SubscriptionPaymentPage extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;

  const SubscriptionPaymentPage({
    Key? key,
    required this.userId,
    required this.userEmail,
    required this.userName,
  }) : super(key: key);

  @override
  State<SubscriptionPaymentPage> createState() =>
      _SubscriptionPaymentPageState();
}

class _SubscriptionPaymentPageState extends State<SubscriptionPaymentPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final StripePaymentService _stripeService = StripePaymentService();

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe to MotoRent Pro'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pro Badge
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.star,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'MotoRent Pro',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Unlock Premium Features',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Price
            Center(
              child: Column(
                children: [
                  const Text(
                    'RM 50.00',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  Text(
                    'per month',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Features
            const Text(
              'What\'s Included:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.analytics,
              'Detailed Revenue Analytics',
              'Track your monthly revenue, expenses, and profit margins',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.assessment,
              'Performance Insights',
              'Get AI-powered recommendations to optimize your fleet',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.picture_as_pdf,
              'Professional Reports',
              'Generate detailed PDF reports for your business',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.speed,
              'Utilization Tracking',
              'Monitor vehicle utilization rates and booking trends',
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              Icons.trending_up,
              'Profit/Loss Analysis',
              'Identify profitable and loss-making vehicles',
            ),
            const SizedBox(height: 30),

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Subscribe Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Subscribe Now',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Terms
            Center(
              child: Text(
                'By subscribing, you agree to our Terms of Service',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _processSubscription() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {

      // Step 1: Create payment intent
      final paymentResult = await _subscriptionService.createProSubscription(
        userId: widget.userId,
        userEmail: widget.userEmail,
        userName: widget.userName,
      );

      if (paymentResult['success'] != true) {
        throw Exception(paymentResult['message']);
      }

      final clientSecret = paymentResult['client_secret'] as String;
      final paymentIntentId = paymentResult['payment_intent_id'] as String;
      final customerId = paymentResult['customer_id'] as String;


      // Step 2: Present payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'MotoRent',
          customerId: customerId,
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF1E88E5),
            ),
          ),
        ),
      );


      // Step 3: Show payment sheet
      await Stripe.instance.presentPaymentSheet();


      // Step 4: Activate subscription in Firebase
      final activationResult =
          await _subscriptionService.activateProSubscription(
        userId: widget.userId,
        paymentIntentId: paymentIntentId,
        stripeCustomerId: customerId,
      );

      if (activationResult['success'] != true) {
        throw Exception(activationResult['message']);
      }


      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Welcome to Pro!'),
            ],
          ),
          content: const Text(
            'Your MotoRent Pro subscription is now active! '
            'You can now access all premium features including detailed revenue analytics.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Return to dashboard with success
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } on StripeException catch (e) {
      setState(() {
        _errorMessage = e.error.message ?? 'Payment failed';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process subscription: $e';
        _isProcessing = false;
      });
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}