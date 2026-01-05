// FILE: lib/config/payment_config.dart
// Configuration class for accessing Stripe keys from environment variables

import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentConfig {
  // Stripe Publishable Key (safe to use in frontend)
  static String get stripePublishableKey {
    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    if (key.isEmpty) {
    }
    return key;
  }

  // Stripe Secret Key (should only be used in backend/secure contexts)
  // ⚠️ In production, this should NEVER be exposed to the frontend
  static String get stripeSecretKey {
    final key = dotenv.env['STRIPE_SECRET_KEY'] ?? '';
    if (key.isEmpty) {
    }
    return key;
  }

  // Check if keys are properly configured
  static bool get isConfigured {
    return stripePublishableKey.isNotEmpty && stripeSecretKey.isNotEmpty;
  }

  // Get the appropriate key based on environment (test vs live)
  static bool get isTestMode {
    return stripePublishableKey.startsWith('pk_test_');
  }

  // Validate keys format
  static bool validateKeys() {
    if (!isConfigured) {
      return false;
    }

    if (!stripePublishableKey.startsWith('pk_')) {
      return false;
    }

    if (!stripeSecretKey.startsWith('sk_')) {
      return false;
    }

    // Check if both keys are for the same mode (test or live)
    final pubKeyIsTest = stripePublishableKey.startsWith('pk_test_');
    final secretKeyIsTest = stripeSecretKey.startsWith('sk_test_');

    if (pubKeyIsTest != secretKeyIsTest) {
      return false;
    }

    return true;
  }

  // Print configuration status (for debugging)
  static void printStatus() {
  }
}