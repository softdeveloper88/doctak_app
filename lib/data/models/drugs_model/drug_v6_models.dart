/// v6 Drug API Models
/// Matches /api/v6/drugs/* response structures exactly.

// ─────────────────────────────────────────────────────────────────────────────
// DRUG ITEM (used in list & detail)
// ─────────────────────────────────────────────────────────────────────────────

class DrugV6Item {
  final int id;
  final String? tradeName;
  final String? genericName;
  final String? strength;
  final String? packageSize;
  final String? mrp;
  final String? manufacturerName;
  final String? formulation;
  final String? indications;
  final String? currency;
  final String? source; // 'legacy' | 'country_drugs'

  const DrugV6Item({
    required this.id,
    this.tradeName,
    this.genericName,
    this.strength,
    this.packageSize,
    this.mrp,
    this.manufacturerName,
    this.formulation,
    this.indications,
    this.currency,
    this.source,
  });

  factory DrugV6Item.fromJson(Map<String, dynamic> json) {
    return DrugV6Item(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tradeName: json['trade_name']?.toString(),
      genericName: json['generic_name']?.toString(),
      strength: json['strength']?.toString(),
      packageSize: json['package_size']?.toString(),
      mrp: json['mrp']?.toString(),
      manufacturerName: json['manufacturer_name']?.toString(),
      formulation: json['formulation']?.toString(),
      indications: json['indications']?.toString(),
      currency: json['currency']?.toString(),
      source: json['source']?.toString(),
    );
  }

  String get displayName => tradeName?.isNotEmpty == true ? tradeName! : genericName ?? '';
  String get subtitle => genericName?.isNotEmpty == true && tradeName?.isNotEmpty == true ? genericName! : '';
  bool get hasPrice => mrp != null && mrp!.isNotEmpty;
  bool get hasIndications => indications != null && indications!.isNotEmpty;
  bool get hasFormulation => formulation != null && formulation!.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// DRUGS LIST RESPONSE (GET /v6/drugs)
// ─────────────────────────────────────────────────────────────────────────────

class DrugV6ListResponse {
  final bool success;
  final List<DrugV6Item> data;
  final DrugV6Meta meta;
  final String currency;
  final String? countryId;
  final String? dataSource;
  final Map<String, dynamic> appliedFilters;

  const DrugV6ListResponse({
    required this.success,
    required this.data,
    required this.meta,
    this.currency = '',
    this.countryId,
    this.dataSource,
    this.appliedFilters = const {},
  });

  factory DrugV6ListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<DrugV6Item> items = [];
    if (rawData is List) {
      items = rawData
          .whereType<Map<String, dynamic>>()
          .map(DrugV6Item.fromJson)
          .toList();
    }
    return DrugV6ListResponse(
      success: json['success'] == true,
      data: items,
      meta: json['meta'] != null
          ? DrugV6Meta.fromJson(json['meta'] as Map<String, dynamic>)
          : DrugV6Meta.empty(),
      currency: json['currency']?.toString() ?? '',
      countryId: json['country_id']?.toString(),
      dataSource: json['data_source']?.toString(),
      appliedFilters: (json['applied_filters'] as Map<String, dynamic>?) ?? {},
    );
  }

  bool get hasMore => meta.hasMore;
  bool get isEmpty => data.isEmpty;
}

class DrugV6Meta {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final bool hasMore;

  const DrugV6Meta({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
  });

  factory DrugV6Meta.fromJson(Map<String, dynamic> json) {
    return DrugV6Meta(
      total: (json['total'] as num?)?.toInt() ?? 0,
      perPage: (json['per_page'] as num?)?.toInt() ?? 15,
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      hasMore: json['has_more'] == true,
    );
  }

  factory DrugV6Meta.empty() =>
      const DrugV6Meta(total: 0, perPage: 15, currentPage: 1, lastPage: 1, hasMore: false);
}

// ─────────────────────────────────────────────────────────────────────────────
// DRUG FILTERS (GET /v6/drugs/filters)
// ─────────────────────────────────────────────────────────────────────────────

class DrugV6Filters {
  final String currency;
  final List<DrugFilterCategory> categories;
  final List<DrugFilterManufacturer> manufacturers;
  final List<String> formulations;
  final List<String> strengths;
  final List<DrugPriceRange> priceRanges;
  final DrugPriceStats? priceStats;

  const DrugV6Filters({
    this.currency = '',
    this.categories = const [],
    this.manufacturers = const [],
    this.formulations = const [],
    this.strengths = const [],
    this.priceRanges = const [],
    this.priceStats,
  });

  factory DrugV6Filters.fromJson(Map<String, dynamic> json) {
    return DrugV6Filters(
      currency: json['currency']?.toString() ?? '',
      categories: (json['categories'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DrugFilterCategory.fromJson)
          .toList(),
      manufacturers: (json['manufacturers'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DrugFilterManufacturer.fromJson)
          .toList(),
      formulations: (json['formulations'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      strengths: (json['strengths'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      priceRanges: (json['price_ranges'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DrugPriceRange.fromJson)
          .toList(),
      priceStats: json['price_stats'] != null && json['price_stats'] is Map
          ? DrugPriceStats.fromJson(json['price_stats'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isEmpty =>
      categories.isEmpty && manufacturers.isEmpty && formulations.isEmpty && strengths.isEmpty;
}

class DrugFilterCategory {
  final String genericName;
  final int totalDrugs;
  DrugFilterCategory({required this.genericName, required this.totalDrugs});
  factory DrugFilterCategory.fromJson(Map<String, dynamic> j) => DrugFilterCategory(
        genericName: j['generic_name']?.toString() ?? '',
        totalDrugs: (j['total_drugs'] as num?)?.toInt() ?? 0,
      );
}

class DrugFilterManufacturer {
  final String manufacturerName;
  final int totalDrugs;
  DrugFilterManufacturer({required this.manufacturerName, required this.totalDrugs});
  factory DrugFilterManufacturer.fromJson(Map<String, dynamic> j) => DrugFilterManufacturer(
        manufacturerName: j['manufacturer_name']?.toString() ?? '',
        totalDrugs: (j['total_drugs'] as num?)?.toInt() ?? 0,
      );
}

class DrugPriceRange {
  final String label;
  final String value;
  DrugPriceRange({required this.label, required this.value});
  factory DrugPriceRange.fromJson(Map<String, dynamic> j) =>
      DrugPriceRange(label: j['label']?.toString() ?? '', value: j['value']?.toString() ?? '');
}

class DrugPriceStats {
  final double? minPrice;
  final double? maxPrice;
  final double? avgPrice;
  DrugPriceStats({this.minPrice, this.maxPrice, this.avgPrice});
  factory DrugPriceStats.fromJson(Map<String, dynamic> j) => DrugPriceStats(
        minPrice: (j['min_price'] as num?)?.toDouble(),
        maxPrice: (j['max_price'] as num?)?.toDouble(),
        avgPrice: (j['avg_price'] as num?)?.toDouble(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE FILTER SET (applied in requests)
// ─────────────────────────────────────────────────────────────────────────────

class DrugActiveFilters {
  final String? keyword;
  final String? category;
  final String? manufacturer;
  final String? strength;
  final String? formulation;
  final String? priceRange;
  final String sort;

  const DrugActiveFilters({
    this.keyword,
    this.category,
    this.manufacturer,
    this.strength,
    this.formulation,
    this.priceRange,
    this.sort = 'name_asc',
  });

  bool get hasActiveFilters =>
      category != null ||
      manufacturer != null ||
      strength != null ||
      formulation != null ||
      priceRange != null;

  int get activeFilterCount => [category, manufacturer, strength, formulation, priceRange]
      .where((v) => v != null)
      .length;

  DrugActiveFilters copyWith({
    String? keyword,
    String? category,
    String? manufacturer,
    String? strength,
    String? formulation,
    String? priceRange,
    String? sort,
    bool clearCategory = false,
    bool clearManufacturer = false,
    bool clearStrength = false,
    bool clearFormulation = false,
    bool clearPriceRange = false,
  }) {
    return DrugActiveFilters(
      keyword: keyword ?? this.keyword,
      category: clearCategory ? null : (category ?? this.category),
      manufacturer: clearManufacturer ? null : (manufacturer ?? this.manufacturer),
      strength: clearStrength ? null : (strength ?? this.strength),
      formulation: clearFormulation ? null : (formulation ?? this.formulation),
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      sort: sort ?? this.sort,
    );
  }

  DrugActiveFilters clearAll() => DrugActiveFilters(keyword: keyword, sort: sort);

  Map<String, String> toQueryParams() {
    final map = <String, String>{};
    if (keyword?.isNotEmpty == true) map['keyword'] = keyword!;
    if (category?.isNotEmpty == true) map['category'] = category!;
    if (manufacturer?.isNotEmpty == true) map['manufacturer'] = manufacturer!;
    if (strength?.isNotEmpty == true) map['strength'] = strength!;
    if (formulation?.isNotEmpty == true) map['formulation'] = formulation!;
    if (priceRange?.isNotEmpty == true) map['price_range'] = priceRange!;
    map['sort'] = sort;
    return map;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURED DRUGS (GET /v6/drugs/featured)
// ─────────────────────────────────────────────────────────────────────────────

class DrugV6Featured {
  final bool success;
  final List<DrugV6Item> data;

  const DrugV6Featured({required this.success, required this.data});

  factory DrugV6Featured.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DrugV6Item.fromJson)
        .toList();
    return DrugV6Featured(success: json['success'] == true, data: list);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH SUGGESTIONS (GET /v6/drugs/search-suggestions)
// ─────────────────────────────────────────────────────────────────────────────

class DrugV6Suggestions {
  final bool success;
  final List<String> data;
  final String type;

  const DrugV6Suggestions({required this.success, required this.data, required this.type});

  factory DrugV6Suggestions.fromJson(Map<String, dynamic> json) {
    return DrugV6Suggestions(
      success: json['success'] == true,
      data: (json['data'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      type: json['type']?.toString() ?? 'Brand',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI USAGE (GET /v6/drugs/ai/usage)
// ─────────────────────────────────────────────────────────────────────────────

class DrugAIUsage {
  final bool success;
  final String planSlug;
  final String planName;
  final int dailyLimit;
  final int dailyUsed;
  final int dailyRemaining;
  final bool canUse;

  const DrugAIUsage({
    required this.success,
    required this.planSlug,
    required this.planName,
    required this.dailyLimit,
    required this.dailyUsed,
    required this.dailyRemaining,
    required this.canUse,
  });

  factory DrugAIUsage.fromJson(Map<String, dynamic> json) {
    final usage = (json['usage'] as Map<String, dynamic>?) ?? {};
    return DrugAIUsage(
      success: json['success'] == true,
      planSlug: json['plan_slug']?.toString() ?? 'free',
      planName: json['plan_name']?.toString() ?? 'Free',
      dailyLimit: (usage['daily_limit'] as num?)?.toInt() ?? 5,
      dailyUsed: (usage['daily_used'] as num?)?.toInt() ?? 0,
      dailyRemaining: (usage['daily_remaining'] as num?)?.toInt() ?? 5,
      // Default to true — only lock when the API explicitly says false.
      // Avoids the bug where missing/null `can_use` disabled the input for
      // free-plan users who haven't yet used any of their daily queries.
      canUse: usage['can_use'] != false,
    );
  }

  double get usagePercent => dailyLimit > 0 ? dailyUsed / dailyLimit : 0.0;
  bool get isLimitReached => !canUse || dailyRemaining <= 0;
  bool get isPremium => planSlug != 'free';
}

// ─────────────────────────────────────────────────────────────────────────────
// AI SESSION & MESSAGES (POST /v6/drugs/ai/session)
// ─────────────────────────────────────────────────────────────────────────────

class DrugAISession {
  final int id;
  final String name;
  final String type;
  final bool isExisting;
  final List<DrugAIMessage> messages;

  const DrugAISession({
    required this.id,
    required this.name,
    required this.type,
    required this.isExisting,
    required this.messages,
  });

  factory DrugAISession.fromJson(Map<String, dynamic> json) {
    final sessionMap = (json['session'] as Map<String, dynamic>?) ?? {};
    final msgList = (json['messages'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DrugAIMessage.fromJson)
        .toList();
    return DrugAISession(
      id: (sessionMap['id'] as num?)?.toInt() ?? 0,
      name: sessionMap['name']?.toString() ?? '',
      type: sessionMap['type']?.toString() ?? 'drug',
      isExisting: json['is_existing'] == true,
      messages: msgList,
    );
  }
}

class DrugAIMessage {
  final int id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime? createdAt;
  final List<Map<String, dynamic>>? sources;

  const DrugAIMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
    this.sources,
  });

  factory DrugAIMessage.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? parsedSources;
    if (json['sources'] != null && json['sources'] is List) {
      parsedSources = (json['sources'] as List)
          .whereType<Map<String, dynamic>>()
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
    }
    return DrugAIMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      sources: parsedSources,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

// ─────────────────────────────────────────────────────────────────────────────
// AI ASK RESPONSE (POST /v6/drugs/ai/ask)
// ─────────────────────────────────────────────────────────────────────────────

class DrugAIAskResponse {
  final bool success;
  final String message;
  final bool limitReached;
  final bool cached;
  final int? aiRemaining;
  final String? planSlug;
  final int? dailyLimit;
  final List<Map<String, dynamic>>? sources;

  const DrugAIAskResponse({
    required this.success,
    required this.message,
    required this.limitReached,
    required this.cached,
    this.aiRemaining,
    this.planSlug,
    this.dailyLimit,
    this.sources,
  });

  factory DrugAIAskResponse.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>>? parsedSources;
    if (json['sources'] != null && json['sources'] is List) {
      parsedSources = (json['sources'] as List)
          .whereType<Map<String, dynamic>>()
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
    }
    return DrugAIAskResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      limitReached: json['limit_reached'] == true,
      cached: json['cached'] == true,
      aiRemaining: (json['ai_remaining'] as num?)?.toInt(),
      planSlug: json['plan_slug']?.toString(),
      dailyLimit: (json['daily_limit'] as num?)?.toInt(),
      sources: parsedSources,
    );
  }
}
