// Model classes for v6 API subscription and feature data.
// These are returned inside login/register/social-login responses.

class SubscriptionData {
  final bool isPremium;
  final String accountType;
  final String? planName;
  final String? planSlug;
  final String? planExpiresAt;
  final int? daysRemaining;
  final bool autoRenew;
  final bool monetizationEnabled;

  SubscriptionData({
    this.isPremium = false,
    this.accountType = 'free',
    this.planName,
    this.planSlug,
    this.planExpiresAt,
    this.daysRemaining,
    this.autoRenew = false,
    this.monetizationEnabled = false,
  });

  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      isPremium: json['is_premium'] == true,
      accountType: json['account_type']?.toString() ?? 'free',
      planName: json['plan_name']?.toString(),
      planSlug: json['plan_slug']?.toString(),
      planExpiresAt: json['plan_expires_at']?.toString(),
      daysRemaining: json['days_remaining'] != null
          ? int.tryParse(json['days_remaining'].toString())
          : null,
      autoRenew: json['auto_renew'] == true,
      monetizationEnabled: json['monetization_enabled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_premium': isPremium,
      'account_type': accountType,
      'plan_name': planName,
      'plan_slug': planSlug,
      'plan_expires_at': planExpiresAt,
      'days_remaining': daysRemaining,
      'auto_renew': autoRenew,
      'monetization_enabled': monetizationEnabled,
    };
  }

  /// Returns a default free-tier subscription
  factory SubscriptionData.free() => SubscriptionData();

  bool get isExpired =>
      planExpiresAt != null &&
      DateTime.tryParse(planExpiresAt!)?.isBefore(DateTime.now()) == true;

  bool get isActive => isPremium && !isExpired;
}

class FeatureAccess {
  final String slug;
  final String name;
  final bool hasAccess;
  final String accessLevel;
  final int? usageLimit;
  final int? usageCount;
  final int? remaining;

  FeatureAccess({
    required this.slug,
    required this.name,
    this.hasAccess = false,
    this.accessLevel = 'none',
    this.usageLimit,
    this.usageCount,
    this.remaining,
  });

  factory FeatureAccess.fromJson(String slug, Map<String, dynamic> json) {
    return FeatureAccess(
      slug: slug,
      name: json['name']?.toString() ?? slug,
      hasAccess: json['has_access'] == true,
      accessLevel: json['access_level']?.toString() ?? 'none',
      usageLimit: json['usage_limit'] != null
          ? int.tryParse(json['usage_limit'].toString())
          : null,
      usageCount: json['usage_count'] != null
          ? int.tryParse(json['usage_count'].toString())
          : null,
      remaining: json['remaining'] != null
          ? int.tryParse(json['remaining'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'has_access': hasAccess,
      'access_level': accessLevel,
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'remaining': remaining,
    };
  }

  bool get isUnlimited => usageLimit == null && hasAccess;
  bool get hasRemainingUsage => remaining == null || (remaining != null && remaining! > 0);
}

/// Helper to parse the features map from v6 API response
class FeaturesMap {
  final Map<String, FeatureAccess> features;

  FeaturesMap({required this.features});

  factory FeaturesMap.fromJson(Map<String, dynamic>? json) {
    if (json == null) return FeaturesMap(features: {});
    final map = <String, FeatureAccess>{};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        map[key] = FeatureAccess.fromJson(key, value);
      }
    });
    return FeaturesMap(features: map);
  }

  Map<String, dynamic> toJson() {
    return features.map((key, value) => MapEntry(key, value.toJson()));
  }

  /// Check if a feature is accessible
  bool hasAccess(String slug) {
    return features[slug]?.hasAccess ?? false;
  }

  /// Get specific feature data
  FeatureAccess? getFeature(String slug) => features[slug];
}
