/// Models for the typed home feed served by `GET /api/feed` on doctak-node.
///
/// The endpoint returns:
/// ```json
/// { "success": true, "entries": [ ... ], "nextCursor": "...", "hasMore": true }
/// ```
/// Each entry is either an inline `item` or a horizontal `strip` of items.
/// Payloads differ per content type, so each [FeedItem] keeps its raw
/// `payload` map and exposes typed getters via the card widgets.
library;

/// Normalizes feed content type strings from the API.
String normalizeFeedItemType(String raw) {
  switch (raw.toLowerCase()) {
    case 'discuss_case':
    case 'discuss-case':
      return 'case';
    case 'posted_job':
    case 'job_post':
      return 'job';
    default:
      return raw.toLowerCase();
  }
}

class FeedEngagement {
  final int views;
  final int likes;
  final int comments;
  final int shares;

  const FeedEngagement({
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
  });

  factory FeedEngagement.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FeedEngagement();
    int parse(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0;
    return FeedEngagement(
      views: parse(json['views']),
      likes: parse(json['likes']),
      comments: parse(json['comments']),
      shares: parse(json['shares']),
    );
  }

  Map<String, dynamic> toJson() => {
        'views': views,
        'likes': likes,
        'comments': comments,
        'shares': shares,
      };
}

/// A single ranked feed item (mirrors `ClientRankedItem` on the web).
class FeedItem {
  /// Content discriminator: post | blog | case | job | cme | conference |
  /// drug | group_suggestion | group_post | survey.
  final String type;
  final String id;
  final String? createdAt;
  final String? authorId;
  final int? specialtyId;
  final FeedEngagement engagement;
  final bool promoted;
  final Map<String, dynamic> payload;

  const FeedItem({
    required this.type,
    required this.id,
    required this.payload,
    this.createdAt,
    this.authorId,
    this.specialtyId,
    this.engagement = const FeedEngagement(),
    this.promoted = false,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'post').toString();
    return FeedItem(
      type: normalizeFeedItemType(rawType),
      id: (json['id'] ?? '').toString(),
      createdAt: json['createdAt']?.toString(),
      authorId: json['authorId']?.toString(),
      specialtyId: json['specialtyId'] is num
          ? (json['specialtyId'] as num).toInt()
          : int.tryParse('${json['specialtyId'] ?? ''}'),
      engagement: FeedEngagement.fromJson(
        json['engagement'] is Map ? Map<String, dynamic>.from(json['engagement']) : null,
      ),
      promoted: json['promoted'] == true,
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'])
          : <String, dynamic>{},
    );
  }

  /// Convenience accessors for payload values.
  String? str(String key) {
    final v = payload[key];
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  bool flag(String key) {
    final v = payload[key];
    if (v == true || v == 1) return true;
    if (v is String) {
      final lower = v.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  int intVal(String key) {
    final v = payload[key];
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? 0}') ?? 0;
  }

  num? numOrNull(String key) {
    final v = payload[key];
    if (v is num) return v;
    return num.tryParse('${v ?? ''}');
  }

  List<dynamic> listVal(String key) {
    final v = payload[key];
    return v is List ? v : const [];
  }

  Map<String, dynamic>? mapVal(String key) {
    final v = payload[key];
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        if (createdAt != null) 'createdAt': createdAt,
        if (authorId != null) 'authorId': authorId,
        if (specialtyId != null) 'specialtyId': specialtyId,
        'engagement': engagement.toJson(),
        'promoted': promoted,
        'payload': payload,
      };
}

/// Whether the viewer is registered for a CME item in the home feed payload.
bool feedCmeIsRegistered(FeedItem item) {
  if (item.flag('isRegistered') || item.flag('userRegistered')) return true;
  final status = item.str('registrationStatus');
  if (status == null || status.isEmpty) return false;
  if (status == 'cancelled') return false;
  return status == 'registered' || status == 'attended' || status == 'waitlist';
}

/// Human-readable registration status for feed CME tiles and cards.
String feedCmeRegistrationLabel(FeedItem item, {String? overrideStatus}) {
  final status = overrideStatus ?? item.str('registrationStatus');
  switch (status) {
    case 'attended':
      return 'Attended';
    case 'waitlist':
      return 'Waitlist';
    case 'registered':
      return 'Registered';
    default:
      return 'Registered';
  }
}

enum FeedEntryKind { item, strip }

/// A feed stream entry — either an inline card or a horizontal strip.
class FeedEntry {
  final FeedEntryKind kind;

  /// Present when [kind] == item.
  final FeedItem? item;

  /// Present when [kind] == strip. One of jobs | groups | cme | conferences | surveys.
  final String? stripType;

  /// Present when [kind] == strip.
  final List<FeedItem> items;

  const FeedEntry.itemEntry(this.item)
      : kind = FeedEntryKind.item,
        stripType = null,
        items = const [];

  const FeedEntry.stripEntry(this.stripType, this.items)
      : kind = FeedEntryKind.strip,
        item = null;

  factory FeedEntry.fromJson(Map<String, dynamic> json) {
    if ((json['kind'] ?? '') == 'strip') {
      final rawItems = json['items'] is List ? json['items'] as List : const [];
      return FeedEntry.stripEntry(
        json['stripType']?.toString(),
        rawItems
            .whereType<Map>()
            .map((e) => FeedItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    }
    final rawItem = json['item'];
    return FeedEntry.itemEntry(
      rawItem is Map ? FeedItem.fromJson(Map<String, dynamic>.from(rawItem)) : null,
    );
  }

  /// A stable key for de-duplication across pages.
  String get dedupeKey {
    if (kind == FeedEntryKind.strip) {
      return 'strip_${stripType}_${items.map((e) => e.id).join('_')}';
    }
    final i = item;
    return i == null ? 'item_null' : '${i.type}_${i.id}';
  }

  Map<String, dynamic> toJson() {
    if (kind == FeedEntryKind.strip) {
      return {
        'kind': 'strip',
        'stripType': stripType,
        'items': items.map((e) => e.toJson()).toList(),
      };
    }
    return {
      'kind': 'item',
      'item': item?.toJson(),
    };
  }
}

/// Full response from `GET /api/feed`.
class FeedResponse {
  final bool success;
  final List<FeedEntry> entries;
  final String? nextCursor;
  final bool hasMore;
  final String? message;

  const FeedResponse({
    required this.success,
    required this.entries,
    this.nextCursor,
    this.hasMore = false,
    this.message,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] is List ? json['entries'] as List : const [];
    return FeedResponse(
      success: json['success'] == true,
      entries: rawEntries
          .whereType<Map>()
          .map((e) => FeedEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      nextCursor: json['nextCursor']?.toString(),
      hasMore: json['hasMore'] == true,
      message: json['message']?.toString(),
    );
  }
}
