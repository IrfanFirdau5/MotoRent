import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripePaymentService {
  // In production, this MUST be on backend/Cloud Functions
  static const String _secretKey = 'sk_test_51Sh0vdDJJKjBR2ZQjHgSjNvSSltjabW200OYhgUYmp9qKyQBWfA35CevM5jdesM2WiAuKULza3zvQ63VIqLmmpkx00AMq9xalc'; 
  
  // Create payment intent on Stripe
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      // Convert amount to cents (Stripe requirement)
      final amountInCents = (amount * 100).round();
      
      print('💳 Creating payment intent for RM ${amount.toStringAsFixed(2)}');
      
      // Create payment intent via Stripe API
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'amount': amountInCents.toString(),
          'currency': currency,
          'description': description,
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Payment intent created: ${data['id']}');
        return {
          'success': true,
          'paymentIntent': data,
          'clientSecret': data['client_secret'],
        };
      } else {
        print('❌ Failed to create payment intent: ${response.body}');
        return {
          'success': false,
          'error': 'Failed to initialize payment',
        };
      }
    } catch (e) {
      print('❌ Error creating payment intent: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Process payment with card details
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String description,
    String currency = 'myr',
  }) async {
    try {
      // Step 1: Create payment intent
      final paymentIntentResult = await createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
      );

      if (!paymentIntentResult['success']) {
        return paymentIntentResult;
      }

      final clientSecret = paymentIntentResult['clientSecret'];

      // Step 2: Confirm payment with Stripe
      print('💳 Confirming payment...');
      
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      print('✅ Payment successful!');
      
      return {
        'success': true,
        'paymentIntentId': paymentIntentResult['paymentIntent']['id'],
        'amount': amount,
        'message': 'Payment successful!',
      };
    } catch (e) {
      print('❌ Payment failed: $e');
      
      // Handle specific Stripe errors
      if (e is StripeException) {
        return {
          'success': false,
          'error': e.error.localizedMessage ?? 'Payment failed',
        };
      }
      
      return {
        'success': false,
        'error': 'Payment failed: $e',
      };
    }
  }

  // Create refund for cancellations
  Future<Map<String, dynamic>> createRefund({
    required String paymentIntentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final amountInCents = (amount * 100).round();
      
      print('💰 Creating refund for $paymentIntentId');
      
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/refunds'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'payment_intent': paymentIntentId,
          'amount': amountInCents.toString(),
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Refund created: ${data['id']}');
        return {
          'success': true,
          'refund': data,
          'message': 'Refund processed successfully',
        };
      } else {
        print('❌ Refund failed: ${response.body}');
        return {
          'success': false,
          'error': 'Failed to process refund',
        };
      }
    } catch (e) {
      print('❌ Error creating refund: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Get payment details
  Future<Map<String, dynamic>> getPaymentDetails(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'payment': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch payment details',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}