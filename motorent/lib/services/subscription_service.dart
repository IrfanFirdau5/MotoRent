// FILE: motorent/lib/services/subscription_service.dart
// CREATE THIS NEW FILE

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';
import 'stripe_payment_service.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StripePaymentService _stripeService = StripePaymentService();
  final String _subscriptionsCollection = 'subscriptions';

  // Subscription plans
  static const double proMonthlyPrice = 50.00;
  static const String proPlanId = 'motorent_pro_monthly';

  /// Get user's current subscription
  Future<Subscription?> getUserSubscription(String userId) async {
    try {
      print('🔍 Fetching subscription for user: $userId');

      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('ℹ️  No subscription found - user is on free plan');
        return _createFreeSubscription(userId);
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['subscription_id'] = doc.id;

      // Handle Timestamp conversions
      if (data['created_at'] is Timestamp) {
        data['created_at'] = (data['created_at'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      if (data['updated_at'] is Timestamp) {
        data['updated_at'] = (data['updated_at'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      if (data['start_date'] is Timestamp) {
        data['start_date'] = (data['start_date'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      if (data['end_date'] is Timestamp) {
        data['end_date'] = (data['end_date'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      if (data['cancelled_at'] is Timestamp) {
        data['cancelled_at'] = (data['cancelled_at'] as Timestamp)
            .toDate()
            .toIso8601String();
      }

      final subscription = Subscription.fromJson(data);
      
      print('✅ Subscription found: ${subscription.plan} - ${subscription.status}');
      return subscription;
    } catch (e) {
      print('❌ Error fetching subscription: $e');
      return _createFreeSubscription(userId);
    }
  }

  /// Create a free subscription object (for users without active subscription)
  Subscription _createFreeSubscription(String userId) {
    return Subscription(
      subscriptionId: 'free_$userId',
      userId: userId,
      plan: 'free',
      status: 'active',
      amount: 0.0,
      currency: 'MYR',
      interval: 'month',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      autoRenew: false,
    );
  }

  /// Check if user has Pro access
  Future<bool> hasProAccess(String userId) async {
    final subscription = await getUserSubscription(userId);
    return subscription?.hasProAccess ?? false;
  }

  /// Create Pro subscription with Stripe payment
  Future<Map<String, dynamic>> createProSubscription({
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('💎 CREATING PRO SUBSCRIPTION');
      print('═══════════════════════════════════════');
      print('User ID: $userId');
      print('Email: $userEmail');
      print('Amount: RM $proMonthlyPrice');

      // Create or get Stripe customer
      final customer = await _stripeService.createCustomer(
        email: userEmail,
        name: userName,
        metadata: {
          'user_id': userId,
          'subscription_type': 'motorent_pro',
        },
      );

      if (customer == null) {
        return {
          'success': false,
          'message': 'Failed to create Stripe customer',
        };
      }

      final customerId = customer['id'];
      print('✅ Stripe Customer ID: $customerId');

      // Create payment intent for subscription
      final paymentIntent = await _stripeService.createPaymentIntent(
        amount: proMonthlyPrice,
        currency: 'MYR',
        description: 'MotoRent Pro Monthly Subscription',
        captureMethod: true, // Capture immediately for subscriptions
        metadata: {
          'user_id': userId,
          'customer_id': customerId,
          'subscription_type': proPlanId,
          'plan': 'pro',
          'interval': 'month',
        },
      );

      if (paymentIntent == null) {
        return {
          'success': false,
          'message': 'Failed to create payment intent',
        };
      }

      final paymentIntentId = paymentIntent['id'];
      final clientSecret = paymentIntent['client_secret'];

      print('✅ Payment Intent created: $paymentIntentId');
      print('═══════════════════════════════════════');
      print('');

      return {
        'success': true,
        'payment_intent_id': paymentIntentId,
        'client_secret': clientSecret,
        'customer_id': customerId,
        'amount': proMonthlyPrice,
        'message': 'Payment intent created successfully',
      };
    } catch (e) {
      print('❌ Error creating Pro subscription: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Activate Pro subscription after successful payment
  Future<Map<String, dynamic>> activateProSubscription({
    required String userId,
    required String paymentIntentId,
    required String stripeCustomerId,
  }) async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('✅ ACTIVATING PRO SUBSCRIPTION');
      print('═══════════════════════════════════════');
      print('User ID: $userId');
      print('Payment Intent: $paymentIntentId');

      // Calculate subscription dates
      final now = DateTime.now();
      final startDate = now;
      final endDate = DateTime(now.year, now.month + 1, now.day);

      // Create subscription record
      final subscriptionData = {
        'user_id': userId,
        'plan': 'pro',
        'status': 'active',
        'start_date': Timestamp.fromDate(startDate),
        'end_date': Timestamp.fromDate(endDate),
        'stripe_subscription_id': paymentIntentId,
        'stripe_customer_id': stripeCustomerId,
        'amount': proMonthlyPrice,
        'currency': 'MYR',
        'interval': 'month',
        'auto_renew': false, // For now, manual renewal
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(_subscriptionsCollection)
          .add(subscriptionData);

      print('✅ Subscription activated!');
      print('   Subscription ID: ${docRef.id}');
      print('   Valid until: ${endDate.toString()}');
      print('═══════════════════════════════════════');
      print('');

      return {
        'success': true,
        'subscription_id': docRef.id,
        'message': 'MotoRent Pro activated successfully!',
        'end_date': endDate.toIso8601String(),
      };
    } catch (e) {
      print('❌ Error activating subscription: $e');
      return {
        'success': false,
        'message': 'Failed to activate subscription: $e',
      };
    }
  }

  /// Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription({
    required String subscriptionId,
    String? reason,
  }) async {
    try {
      await _firestore
          .collection(_subscriptionsCollection)
          .doc(subscriptionId)
          .update({
        'status': 'cancelled',
        'auto_renew': false,
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancellation_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Subscription cancelled successfully',
      };
    } catch (e) {
      print('❌ Error cancelling subscription: $e');
      return {
        'success': false,
        'message': 'Failed to cancel subscription: $e',
      };
    }
  }

  /// Check and update expired subscriptions
  Future<void> checkExpiredSubscriptions() async {
    try {
      final now = DateTime.now();

      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('status', isEqualTo: 'active')
          .where('end_date', isLessThan: Timestamp.fromDate(now))
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          'status': 'expired',
          'updated_at': FieldValue.serverTimestamp(),
        });
        print('⏰ Subscription expired: ${doc.id}');
      }
    } catch (e) {
      print('❌ Error checking expired subscriptions: $e');
    }
  }

  /// Get subscription statistics
  Future<Map<String, dynamic>> getSubscriptionStats() async {
    try {
      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .get();

      int totalSubscriptions = querySnapshot.docs.length;
      int activeSubscriptions = 0;
      int expiredSubscriptions = 0;
      double totalRevenue = 0.0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;

        if (status == 'active') {
          activeSubscriptions++;
          totalRevenue += (data['amount'] as num?)?.toDouble() ?? 0.0;
        } else if (status == 'expired' || status == 'cancelled') {
          expiredSubscriptions++;
        }
      }

      return {
        'total_subscriptions': totalSubscriptions,
        'active_subscriptions': activeSubscriptions,
        'expired_subscriptions': expiredSubscriptions,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      print('❌ Error getting subscription stats: $e');
      return {
        'total_subscriptions': 0,
        'active_subscriptions': 0,
        'expired_subscriptions': 0,
        'total_revenue': 0.0,
      };
    }
  }
}