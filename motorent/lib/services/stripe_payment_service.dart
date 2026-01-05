// FILE: lib/services/stripe_payment_service.dart
// ✅ COMPLETE VERSION - Uses environment variables + Payment Authorization

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
    } else {
      if (PaymentConfig.isTestMode) {
      } else {
      }
    }
  }

  /// Create a Payment Intent with AUTHORIZATION (hold funds, don't capture yet)
  /// This should ideally be done from your backend server for security
  Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    String? description,
    Map<String, dynamic>? metadata,
    bool captureMethod = false, // ✅ NEW: If false, only authorize (hold) the payment
  }) async {
    try {
      // Validate configuration
      if (!PaymentConfig.isConfigured) {
        throw Exception('Stripe is not configured. Check your .env file.');
      }

      // Convert amount to cents (Stripe expects smallest currency unit)
      final amountInCents = (amount * 100).toInt();


      // ✅ Build body with proper metadata formatting + capture_method
      final body = <String, String>{
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
        'capture_method': captureMethod ? 'automatic' : 'manual', // ✅ Hold funds if manual
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
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// ✅ NEW: Capture a held payment (release funds after owner approval)
  Future<Map<String, dynamic>?> capturePayment(String paymentIntentId) async {
    try {
      if (!PaymentConfig.isConfigured) {
        throw Exception('Stripe is not configured. Check your .env file.');
      }


      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/capture'),
        headers: {
          'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
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
        return data;
      } else {
        return null;
      }
    } catch (e) {
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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Cancel Payment Intent (release held funds)
  Future<bool> cancelPaymentIntent(String paymentIntentId) async {
    try {
      if (!PaymentConfig.isConfigured) {
        throw Exception('Stripe is not configured. Check your .env file.');
      }


      final response = await http.post(
        Uri.parse('$_baseUrl/payment_intents/$paymentIntentId/cancel'),
        headers: {
          'Authorization': 'Bearer ${PaymentConfig.stripeSecretKey}', // ✅ From .env
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return true;
      } else {
        return false;
      }
    } catch (e) {
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

      if (amount != null) {
      } else {
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
        return data;
      } else {
        return null;
      }
    } catch (e) {
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

  /// Process a booking payment with AUTHORIZATION (hold funds)
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

      // Create payment intent with MANUAL capture (hold funds)
      final paymentIntent = await createPaymentIntent(
        amount: totalAmount,
        currency: currency,
        description: 'MotoRent Booking #$bookingId - $vehicleName',
        captureMethod: false, // ✅ MANUAL = Hold funds
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


      return {
        'success': true,
        'payment_intent_id': paymentIntentId,
        'client_secret': clientSecret,
        'customer_id': customerId,
        'amount': totalAmount,
        'currency': currency,
        'status': paymentIntent['status'],
        'message': 'Payment intent created successfully (funds will be held)',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Simple payment processing method (for stripe_payment_page.dart compatibility)
  /// This creates a payment intent with AUTHORIZATION
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    String? description,
    String currency = 'MYR',
    Map<String, dynamic>? metadata,
  }) async {
    try {

      // Create payment intent with MANUAL capture (hold funds)
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
        captureMethod: false, // ✅ MANUAL = Hold funds
        metadata: metadata,
      );

      if (paymentIntent == null) {
        return {
          'success': false,
          'error': 'Failed to create payment intent',
        };
      }

      final clientSecret = paymentIntent['client_secret'];
      final paymentIntentId = paymentIntent['id'];


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

    switch (eventType) {
      case 'payment_intent.succeeded':
        // TODO: Update booking status in Firebase
        break;
      case 'payment_intent.payment_failed':
        // TODO: Handle payment failure
        break;
      case 'payment_intent.canceled':
        // TODO: Handle cancellation
        break;
      case 'charge.refunded':
        // TODO: Handle refund
        break;
      case 'payment_intent.amount_capturable_updated':
        // TODO: Notify owner to approve booking
        break;
      default:
    }
  }
}