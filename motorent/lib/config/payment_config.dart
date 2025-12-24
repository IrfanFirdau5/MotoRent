// FILE: lib/config/payment_config.dart
// Configuration class for accessing Stripe keys from environment variables

import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentConfig {
  // Stripe Publishable Key (safe to use in frontend)
  static String get stripePublishableKey {
    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    if (key.isEmpty) {
      print('⚠️  WARNING: STRIPE_PUBLISHABLE_KEY not found in .env');
    }
    return key;
  }

  // Stripe Secret Key (should only be used in backend/secure contexts)
  // ⚠️ In production, this should NEVER be exposed to the frontend
  static String get stripeSecretKey {
    final key = dotenv.env['STRIPE_SECRET_KEY'] ?? '';
    if (key.isEmpty) {
      print('⚠️  WARNING: STRIPE_SECRET_KEY not found in .env');
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
      print('❌ Stripe keys are not configured!');
      return false;
    }

    if (!stripePublishableKey.startsWith('pk_')) {
      print('❌ Invalid Stripe publishable key format!');
      return false;
    }

    if (!stripeSecretKey.startsWith('sk_')) {
      print('❌ Invalid Stripe secret key format!');
      return false;
    }

    // Check if both keys are for the same mode (test or live)
    final pubKeyIsTest = stripePublishableKey.startsWith('pk_test_');
    final secretKeyIsTest = stripeSecretKey.startsWith('sk_test_');

    if (pubKeyIsTest != secretKeyIsTest) {
      print('⚠️  WARNING: Publishable and Secret keys are from different modes!');
      return false;
    }

    print('✅ Stripe keys validated successfully (${isTestMode ? 'TEST' : 'LIVE'} mode)');
    return true;
  }

  // Print configuration status (for debugging)
  static void printStatus() {
    print('');
    print('═══════════════════════════════════════');
    print('🔐 STRIPE CONFIGURATION STATUS');
    print('═══════════════════════════════════════');
    print('Configured: ${isConfigured ? '✅' : '❌'}');
    print('Mode: ${isTestMode ? '🧪 TEST' : '🚀 LIVE'}');
    print('Publishable Key: ${stripePublishableKey.isNotEmpty ? '${stripePublishableKey.substring(0, 15)}...' : 'NOT SET'}');
    print('Secret Key: ${stripeSecretKey.isNotEmpty ? '${stripeSecretKey.substring(0, 12)}...' : 'NOT SET'}');
    print('Valid: ${validateKeys() ? '✅' : '❌'}');
    print('═══════════════════════════════════════');
    print('');
  }
}