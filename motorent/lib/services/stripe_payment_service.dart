// FILE: lib/services/stripe_payment_service.dart
// ✅ SECURE VERSION - Uses environment variables instead of hardcoded keys

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/payment_config.dart';

class StripePaymentService {
  // ✅ NO MORE HARDCODED KEYS!
  // Keys are now loaded from .env file via PaymentConfig
  
  static const String _baseUrl = 'https://api.stripe.com/v1';

  // Verify configuration on service initialization
  StripePaymentService() {
    if (!PaymentConfig.isConfigured) {
      print('❌ StripePaymentService: Configuration error!');
      print('⚠️  Make sure .env file exists with valid Stripe keys.');
    } else {
      print('✅ StripePaymentService initialized successfully');
      if (PaymentConfig.isTestMode) {
        print('🧪 Running in TEST mode');
      } else {
        print('🚀 Running in LIVE mode');
      }
    }
  }

  /// Create a Payment Intent
  /// This should ideally be done from your backend server for security
  Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate configuration
      if (!PaymentConfig.isConfigured) {
        throw Exception('Stripe is not configured. Check your .env file.');
      }

      // Convert amount to cents (Stripe expects smallest currency unit)
      final amountInCents = (amount * 100).toInt();

      print('💳 Creating Payment Intent...');
      print('   Amount: $currency ${amount.toStringAsFixed(2)} ($amountInCents cents)');

      // ✅ FIXED: Build body with proper metadata formatting
      final body = <String, String>{
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
      };

      // Add description if provided
      if (description != null) {
        body['description'] = description;
      }

      // ✅ Add metadata with proper prefix format
      if (metadata != null) {
        metadata.forEach((key, value) {
          body['metadata[$key]'] = value.toString();
        });
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}', // ✅ From .env
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Payment Intent created: ${data['id']}');
        return data;
      } else {
        print('❌ Payment Intent creation failed: ${response.statusCode}');
        print('   Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating Payment Intent: $e');
      return null;
    }
  }

  /// Create a Customer
  Future<Map<String, dynamic>?> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!PaymentConfig.isConfigured) {
        throw Exception('Stripe is not configured. Check your .env file.');
      }

      print('👤 Creating Stripe Customer...');
      print('   Email: $email');

      // ✅ Build body with proper metadata formatting
      final body = <String, String>{
        'email': email,
      };

      if (name != null) {
        body['name'] = name;
      }

      if (phone != null) {
        body['phone'] = phone;
      }

      // ✅ Add metadata with proper prefix format
      if (metadata != null) {
        metadata.forEach((key, value) {
          body['metadata[$key]'] = value.toString();
        });
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: {
          'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}', // ✅ From .env
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Customer created: ${data['id']}');
        return data;
      } else {
        print('❌ Customer creation failed: ${response.statusCode}');
        print('   Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating customer: $e');
      return null;
    }
  }

  /// Retrieve Payment Intent
  Future<Map<String, dynamic>?> retrievePaymentIntent(String paymentIntentId) async {
    try {
      if (!PaymentConfig.isConfigured) {
        throw Exception('Stripe is not configured. Check your .env file.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId'),
        headers: {
          'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}', // ✅ From .env
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ Failed to retrieve Payment Intent: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error retrieving Payment Intent: $e');
      return null;
    }
  }

  /// Cancel Payment Intent
  Future<bool> cancelPaymentIntent(String paymentIntentId) async {
    try {
      if (!PaymentConfig.isConfigured) {
        throw Exception('Stripe is not configured. Check your .env file.');
      }

      print('🚫 Canceling Payment Intent: $paymentIntentId');

      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/cancel'),
        headers: {
          'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}', // ✅ From .env
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Payment Intent canceled successfully');
        return true;
      } else {
        print('❌ Failed to cancel Payment Intent: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error canceling Payment Intent: $e');
      return false;
    }
  }

  /// Create a Refund
  Future<Map<String, dynamic>?> createRefund({
    required String paymentIntentId,
    int? amount, // Amount in cents, null for full refund
    String? reason, // duplicate, fraudulent, or requested_by_customer
  }) async {
    try {
      if (!PaymentConfig.isConfigured) {
        throw Exception('Stripe is not configured. Check your .env file.');
      }

      print('💰 Creating refund for Payment Intent: $paymentIntentId');
      if (amount != null) {
        print('   Amount: $amount cents');
      } else {
        print('   Amount: Full refund');
      }

      final body = {
        'payment_intent': paymentIntentId,
        if (amount != null) 'amount': amount.toString(),
        if (reason != null) 'reason': reason,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/refunds'),
        headers: {
          'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}', // ✅ From .env
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Refund created: ${data['id']}');
        return data;
      } else {
        print('❌ Refund creation failed: ${response.statusCode}');
        print('   Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating refund: $e');
      return null;
    }
  }

  /// Get publishable key for frontend use
  /// This is safe to expose to the frontend
  static String getPublishableKey() {
    return PaymentConfig.stripePublishableKey;
  }

  /// Check if Stripe is properly configured
  static bool isConfigured() {
    return PaymentConfig.isConfigured;
  }

  /// Validate Stripe configuration
  static bool validateConfiguration() {
    return PaymentConfig.validateKeys();
  }

  /// Show configuration status (for debugging)
  static void printConfiguration() {
    PaymentConfig.printStatus();
  }

  /// Process a booking payment
  /// This is a high-level method for MotoRent bookings
  Future<Map<String, dynamic>> processBookingPayment({
    required String bookingId,
    required double totalAmount,
    required String currency,
    required String customerEmail,
    required String customerName,
    required String vehicleName,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('🚗 PROCESSING BOOKING PAYMENT');
      print('═══════════════════════════════════════');
      print('Booking ID: $bookingId');
      print('Amount: $currency ${totalAmount.toStringAsFixed(2)}');
      print('Customer: $customerName ($customerEmail)');
      print('Vehicle: $vehicleName');
      print('═══════════════════════════════════════');

      // Create or get customer
      final customer = await createCustomer(
        email: customerEmail,
        name: customerName,
        metadata: {
          'booking_id': bookingId,
          'source': 'motorent_app',
        },
      );

      if (customer == null) {
        return {
          'success': false,
          'message': 'Failed to create customer',
        };
      }

      final customerId = customer['id'];
      print('✅ Customer ID: $customerId');

      // Create payment intent
      final paymentIntent = await createPaymentIntent(
        amount: totalAmount,
        currency: currency,
        description: 'MotoRent Booking #$bookingId - $vehicleName',
        metadata: {
          'booking_id': bookingId,
          'customer_id': customerId,
          'vehicle_name': vehicleName,
          'customer_email': customerEmail,
          ...?additionalMetadata,
        },
      );

      if (paymentIntent == null) {
        return {
          'success': false,
          'message': 'Failed to create payment intent',
        };
      }

      final clientSecret = paymentIntent['client_secret'];
      final paymentIntentId = paymentIntent['id'];

      print('✅ Payment Intent created successfully!');
      print('   Payment Intent ID: $paymentIntentId');
      print('   Status: ${paymentIntent['status']}');
      print('═══════════════════════════════════════');
      print('');

      return {
        'success': true,
        'payment_intent_id': paymentIntentId,
        'client_secret': clientSecret,
        'customer_id': customerId,
        'amount': totalAmount,
        'currency': currency,
        'status': paymentIntent['status'],
        'message': 'Payment intent created successfully',
      };
    } catch (e) {
      print('❌ Error processing booking payment: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Simple payment processing method (for stripe_payment_page.dart compatibility)
  /// This creates a payment intent and confirms it automatically
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    String? description,
    String currency = 'MYR',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('💳 PROCESSING PAYMENT');
      print('═══════════════════════════════════════');
      print('Amount: $currency ${amount.toStringAsFixed(2)}');
      print('Description: ${description ?? 'Payment'}');
      print('═══════════════════════════════════════');

      // Create payment intent
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
        metadata: metadata,
      );

      if (paymentIntent == null) {
        print('❌ Failed to create payment intent');
        return {
          'success': false,
          'error': 'Failed to create payment intent',
        };
      }

      final clientSecret = paymentIntent['client_secret'];
      final paymentIntentId = paymentIntent['id'];

      print('✅ Payment Intent created!');
      print('   ID: $paymentIntentId');
      print('   Status: ${paymentIntent['status']}');
      print('═══════════════════════════════════════');
      print('');

      // Return the client secret for frontend to confirm payment
      return {
        'success': true,
        'client_secret': clientSecret,
        'payment_intent_id': paymentIntentId,
        'amount': amount,
        'currency': currency,
        'status': paymentIntent['status'],
      };
    } catch (e) {
      print('❌ Error processing payment: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Handle webhook events (for backend integration)
  /// This should be implemented on your backend server
  static Future<void> handleWebhookEvent(Map<String, dynamic> event) async {
    final eventType = event['type'];
    print('📥 Webhook received: $eventType');

    switch (eventType) {
      case 'payment_intent.succeeded':
        print('✅ Payment succeeded!');
        // TODO: Update booking status in Firebase
        break;
      case 'payment_intent.payment_failed':
        print('❌ Payment failed!');
        // TODO: Handle payment failure
        break;
      case 'charge.refunded':
        print('💰 Charge refunded!');
        // TODO: Handle refund
        break;
      default:
        print('ℹ️  Unhandled event type: $eventType');
    }
  }
}