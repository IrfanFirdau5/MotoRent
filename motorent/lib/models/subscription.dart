// FILE: motorent/lib/models/subscription.dart
// CREATE THIS NEW FILE

class Subscription {
  final String subscriptionId;
  final String userId;
  final String plan; // 'free' or 'pro'
  final String status; // 'active', 'cancelled', 'expired', 'past_due'
  final DateTime? startDate;
  final DateTime? endDate;
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;
  final double amount;
  final String currency;
  final String interval; // 'month' or 'year'
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool autoRenew;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  Subscription({
    required this.subscriptionId,
    required this.userId,
    required this.plan,
    required this.status,
    this.startDate,
    this.endDate,
    this.stripeSubscriptionId,
    this.stripeCustomerId,
    required this.amount,
    required this.currency,
    required this.interval,
    required this.createdAt,
    required this.updatedAt,
    required this.autoRenew,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      subscriptionId: json['subscription_id'] ?? '',
      userId: json['user_id'] ?? '',
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'expired',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      stripeSubscriptionId: json['stripe_subscription_id'],
      stripeCustomerId: json['stripe_customer_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'MYR',
      interval: json['interval'] ?? 'month',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      autoRenew: json['auto_renew'] ?? false,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      cancellationReason: json['cancellation_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription_id': subscriptionId,
      'user_id': userId,
      'plan': plan,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'stripe_subscription_id': stripeSubscriptionId,
      'stripe_customer_id': stripeCustomerId,
      'amount': amount,
      'currency': currency,
      'interval': interval,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'auto_renew': autoRenew,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
    };
  }

  // Check if subscription is active
  bool get isActive => status == 'active' && (endDate?.isAfter(DateTime.now()) ?? false);

  // Check if user has pro features
  bool get hasProAccess => plan == 'pro' && isActive;

  // Get days remaining
  int get daysRemaining {
    if (endDate == null) return 0;
    final now = DateTime.now();
    if (endDate!.isBefore(now)) return 0;
    return endDate!.difference(now).inDays;
  }

  // Check if subscription is expiring soon (within 7 days)
  bool get isExpiringSoon {
    return daysRemaining > 0 && daysRemaining <= 7;
  }

  // Get status display text
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      case 'past_due':
        return 'Payment Past Due';
      default:
        return status;
    }
  }

  // Get plan display text
  String get planDisplay {
    switch (plan.toLowerCase()) {
      case 'free':
        return 'Free Plan';
      case 'pro':
        return 'MotoRent Pro';
      default:
        return plan;
    }
  }
}