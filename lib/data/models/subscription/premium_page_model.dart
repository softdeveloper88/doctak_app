/// Models for /api/v6/subscription/premium-page response.
/// Mirrors the exact data rendered on the /try-premium web page.

class PremiumPageResponse {
  final bool success;
  final String currentPlan;
  final PremiumHero hero;
  final List<PremiumPlan> plans;
  final PremiumGuarantee? guarantee;

  PremiumPageResponse({
    this.success = false,
    this.currentPlan = 'free',
    required this.hero,
    this.plans = const [],
    this.guarantee,
  });

  factory PremiumPageResponse.fromJson(Map<String, dynamic> json) {
    return PremiumPageResponse(
      success: json['success'] == true,
      currentPlan: json['current_plan']?.toString() ?? 'free',
      hero: json['hero'] != null
          ? PremiumHero.fromJson(json['hero'] as Map<String, dynamic>)
          : PremiumHero(),
      plans: (json['plans'] as List<dynamic>? ?? [])
          .map((p) => PremiumPlan.fromJson(p as Map<String, dynamic>))
          .toList(),
      guarantee: json['guarantee'] != null
          ? PremiumGuarantee.fromJson(json['guarantee'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PremiumHero {
  final String badge;
  final String title;
  final String subtitle;

  PremiumHero({
    this.badge = 'Premium Plans',
    this.title = 'Choose Your Professional Plan',
    this.subtitle = '',
  });

  factory PremiumHero.fromJson(Map<String, dynamic> json) {
    return PremiumHero(
      badge: json['badge']?.toString() ?? 'Premium Plans',
      title: json['title']?.toString() ?? 'Choose Your Professional Plan',
      subtitle: json['subtitle']?.toString() ?? '',
    );
  }
}

class PremiumPlan {
  final int id;
  final String slug;
  final String name;
  final String? description;
  final double priceMonthly;
  final double priceYearly;
  final String currency;
  final bool isFree;
  final bool isCurrent;
  final String? badge; // 'most_popular', 'best_value', or null
  final List<PlanHighlight> highlights;

  PremiumPlan({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.priceMonthly = 0,
    this.priceYearly = 0,
    this.currency = 'USD',
    this.isFree = true,
    this.isCurrent = false,
    this.badge,
    this.highlights = const [],
  });

  factory PremiumPlan.fromJson(Map<String, dynamic> json) {
    return PremiumPlan(
      id: _parseInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      priceMonthly: _parseDouble(json['price_monthly']),
      priceYearly: _parseDouble(json['price_yearly']),
      currency: json['currency']?.toString() ?? 'USD',
      isFree: json['is_free'] == true,
      isCurrent: json['is_current'] == true,
      badge: json['badge']?.toString(),
      highlights: (json['highlights'] as List<dynamic>? ?? [])
          .map((h) => PlanHighlight.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _parseInt(dynamic val) =>
      val == null ? 0 : int.tryParse(val.toString()) ?? 0;
  static double _parseDouble(dynamic val) =>
      val == null ? 0.0 : double.tryParse(val.toString()) ?? 0.0;
}

class PlanHighlight {
  final String icon; // material icon name from web: 'check_circle', 'verified', 'remove_circle_outline'
  final String type; // 'included', 'limited', 'unlimited'
  final String text;

  PlanHighlight({
    required this.icon,
    required this.type,
    required this.text,
  });

  factory PlanHighlight.fromJson(Map<String, dynamic> json) {
    return PlanHighlight(
      icon: json['icon']?.toString() ?? 'check_circle',
      type: json['type']?.toString() ?? 'included',
      text: json['text']?.toString() ?? '',
    );
  }
}

class PremiumGuarantee {
  final String title;
  final String description;

  PremiumGuarantee({
    this.title = '',
    this.description = '',
  });

  factory PremiumGuarantee.fromJson(Map<String, dynamic> json) {
    return PremiumGuarantee(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
