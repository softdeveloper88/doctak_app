// Models for /api/v6/subscription/plans and /api/v6/subscription/status responses.

import 'package:doctak_app/data/models/subscription/subscription_data_model.dart';

// ── Plans response ────────────────────────────────────────────────────────────

class SubscriptionPlansResponse {
  final bool success;
  final bool monetizationEnabled;
  final bool plansVisible;
  final List<SubscriptionPlanItem> plans;
  final String? message;

  SubscriptionPlansResponse({
    this.success = false,
    this.monetizationEnabled = false,
    this.plansVisible = false,
    this.plans = const [],
    this.message,
  });

  factory SubscriptionPlansResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlansResponse(
      success: json['success'] == true,
      monetizationEnabled: json['monetization_enabled'] == true,
      plansVisible: json['plans_visible'] == true,
      plans: (json['plans'] as List<dynamic>? ?? [])
          .map((p) => SubscriptionPlanItem.fromJson(p as Map<String, dynamic>))
          .toList(),
      message: json['message']?.toString(),
    );
  }
}

class SubscriptionPlanItem {
  final int id;
  final String slug;
  final String name;
  final String? description;
  final double priceMonthly;
  final double priceYearly;
  final String currency;
  final bool isDefault;
  final bool isFree;
  final Map<String, PlanFeatureRow> features;

  SubscriptionPlanItem({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.priceMonthly = 0,
    this.priceYearly = 0,
    this.currency = 'USD',
    this.isDefault = false,
    this.isFree = true,
    this.features = const {},
  });

  factory SubscriptionPlanItem.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'] as Map<String, dynamic>? ?? {};
    final features = featuresJson.map((key, val) =>
        MapEntry(key, PlanFeatureRow.fromJson(val as Map<String, dynamic>)));

    return SubscriptionPlanItem(
      id: _parseInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      priceMonthly: _parseDouble(json['price_monthly']),
      priceYearly: _parseDouble(json['price_yearly']),
      currency: json['currency']?.toString() ?? 'USD',
      isDefault: json['is_default'] == true,
      isFree: json['is_free'] == true,
      features: features,
    );
  }

  static int _parseInt(dynamic val) => val == null ? 0 : int.tryParse(val.toString()) ?? 0;
  static double _parseDouble(dynamic val) => val == null ? 0.0 : double.tryParse(val.toString()) ?? 0.0;

  String get formattedMonthlyPrice =>
      isFree ? 'Free' : '\$$priceMonthly/mo';

  String get formattedYearlyPrice =>
      isFree ? 'Free' : '\$$priceYearly/yr';
}

class PlanFeatureRow {
  final String name;
  final String? category;
  final bool hasAccess;
  final String accessLevel;
  final int? dailyLimit;
  final int? monthlyLimit;
  final String? tierDescription;

  PlanFeatureRow({
    required this.name,
    this.category,
    this.hasAccess = false,
    this.accessLevel = 'none',
    this.dailyLimit,
    this.monthlyLimit,
    this.tierDescription,
  });

  factory PlanFeatureRow.fromJson(Map<String, dynamic> json) {
    return PlanFeatureRow(
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString(),
      hasAccess: json['has_access'] == true,
      accessLevel: json['access_level']?.toString() ?? 'none',
      dailyLimit: json['daily_limit'] != null ? int.tryParse(json['daily_limit'].toString()) : null,
      monthlyLimit: json['monthly_limit'] != null ? int.tryParse(json['monthly_limit'].toString()) : null,
      tierDescription: json['tier_description']?.toString(),
    );
  }
}

// ── Subscription status response ──────────────────────────────────────────────

class SubscriptionStatusResponse {
  final bool success;
  final SubscriptionData subscription;
  final FeaturesMap features;

  SubscriptionStatusResponse({
    this.success = false,
    required this.subscription,
    required this.features,
  });

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusResponse(
      success: json['success'] == true,
      subscription: json['subscription'] != null
          ? SubscriptionData.fromJson(json['subscription'])
          : SubscriptionData.free(),
      features: json['features'] != null
          ? FeaturesMap.fromJson(Map<String, dynamic>.from(json['features']))
          : FeaturesMap(features: {}),
    );
  }
}

// ── Subscription history ──────────────────────────────────────────────────────

class SubscriptionHistoryItem {
  final int id;
  final String planName;
  final String planSlug;
  final double amount;
  final String? billingPeriod;
  final String? paymentMethod;
  final String status;
  final String? startedAt;
  final String? expiresAt;
  final String? createdAt;

  SubscriptionHistoryItem({
    required this.id,
    required this.planName,
    required this.planSlug,
    this.amount = 0,
    this.billingPeriod,
    this.paymentMethod,
    this.status = '',
    this.startedAt,
    this.expiresAt,
    this.createdAt,
  });

  factory SubscriptionHistoryItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      planName: json['plan_name']?.toString() ?? '',
      planSlug: json['plan_slug']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      billingPeriod: json['billing_period']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      status: json['status']?.toString() ?? '',
      startedAt: json['started_at']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
