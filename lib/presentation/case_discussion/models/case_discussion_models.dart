// ============================================================================
// Case Discussion Models - v6 API
// Clean, type-safe models matching the v6 API response structure.
// ============================================================================

import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/display_identity.dart';
import 'clinical_snapshot.dart';

/// Safely parse a dynamic value to int (handles String, int, double, null).
int _parseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST ITEM MODEL (for paginated list)
// ─────────────────────────────────────────────────────────────────────────────

class CaseDiscussionListItem {
  final int id;
  final String title;
  final String? description;
  final String? tags;
  final int likes;
  final int dislikes;
  final int views;
  final String? attachedFile;
  final bool promoted;
  final DateTime createdAt;
  final String name;
  final String? profilePic;
  final String? specialty;
  final int commentsCount;
  final bool isLiked;
  final bool isDisliked;
  final bool isBookmarked;
  final bool isOwner;
  final bool isVerified;

  CaseDiscussionListItem({
    required this.id,
    required this.title,
    this.description,
    this.tags,
    required this.likes,
    this.dislikes = 0,
    required this.views,
    this.attachedFile,
    this.promoted = false,
    required this.createdAt,
    required this.name,
    this.profilePic,
    this.specialty,
    required this.commentsCount,
    this.isLiked = false,
    this.isDisliked = false,
    this.isBookmarked = false,
    this.isOwner = false,
    this.isVerified = false,
  });

  factory CaseDiscussionListItem.fromJson(Map<String, dynamic> json) {
    // attached_file may be a List (Eloquent array cast) or String
    String? attachedFile;
    final rawFile = json['attached_file'];
    if (rawFile is String) {
      attachedFile = rawFile;
    } else if (rawFile is List) {
      attachedFile = jsonEncode(rawFile);
    }

    return CaseDiscussionListItem(
      id: _parseInt(json['id']),
      title: json['title'] ?? '',
      description: json['description']?.toString(),
      tags: json['tags']?.toString(),
      likes: _parseInt(json['likes']),
      dislikes: _parseInt(json['dislikes']),
      views: _parseInt(json['views']),
      attachedFile: attachedFile,
      promoted: json['promoted'] == 1 || json['promoted'] == true,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      name: formatDisplayName(json['name']?.toString(), 'Unknown User'),
      profilePic: AppData.fullImageUrl(json['profile_pic']),
      specialty: json['specialty']?.toString(),
      commentsCount: _parseInt(json['comments_count'] ?? json['comments']),
      isLiked: json['is_liked'] == true || json['is_liked'] == 1 || (json['user_vote'] == 'up' || json['user_vote'] == 'like'),
      isDisliked: json['is_disliked'] == true || json['is_disliked'] == 1 || (json['user_vote'] == 'down' || json['user_vote'] == 'dislike'),
      isBookmarked: json['is_bookmarked'] == true || json['is_bookmarked'] == 1,
      isOwner: json['is_owner'] == true || json['is_owner'] == 1,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
    );
  }

  /// Parse comma-separated tags into a clean list.
  List<String> get parsedTags {
    if (tags == null || tags!.isEmpty || tags == 'null') return [];
    try {
      return tags!
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    } catch (_) {
      return [tags!.trim()];
    }
  }

  /// Get parsed image URLs from attachedFile field.
  List<String> get imageUrls {
    if (attachedFile == null || attachedFile!.isEmpty) return [];
    try {
      final str = attachedFile!;
      if (str.startsWith('[')) {
        final parsed = jsonDecode(str) as List;
        return parsed.map((e) => AppData.fullImageUrl(e.toString())).toList();
      }
      return [AppData.fullImageUrl(str)];
    } catch (_) {
      return [];
    }
  }

  CaseAuthor get author => CaseAuthor(
        id: 0,
        name: name,
        specialty: specialty ?? '',
        profilePic: profilePic,
      );

  int get score => likes - dislikes;

  CaseDiscussionListItem copyWith({
    int? likes,
    int? dislikes,
    bool? isLiked,
    bool? isDisliked,
    bool? isBookmarked,
    int? commentsCount,
  }) {
    return CaseDiscussionListItem(
      id: id,
      title: title,
      description: description,
      tags: tags,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      views: views,
      attachedFile: attachedFile,
      promoted: promoted,
      createdAt: createdAt,
      name: name,
      profilePic: profilePic,
      specialty: specialty,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isOwner: isOwner,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'tags': tags,
        'likes': likes,
        'views': views,
        'attached_file': attachedFile,
        'promoted': promoted ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'name': name,
        'profile_pic': profilePic,
        'specialty': specialty,
        'comments_count': commentsCount,
        'is_liked': isLiked,
        'is_bookmarked': isBookmarked,
        'is_owner': isOwner,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL MODEL (full case data)
// ─────────────────────────────────────────────────────────────────────────────

class CaseDiscussion {
  final int id;
  final String title;
  final String description;
  final String? tags;
  final int likes;
  final int dislikes;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CaseAuthor author;
  final String? specialty;
  final int? specialtyId;
  final String? countryName;
  final int? countryId;
  final String? countryFlag;
  final List<CaseAttachment> attachments;
  final AISummary? aiSummary;
  final CaseMetadata? metadata;
  final List<CaseUpdate> updates;
  final List<DecisionSupport> decisionSupports;
  final List<RelatedCase> relatedCases;
  final int commentsCount;
  final int followersCount;
  final bool isLiked;
  final bool isDisliked;
  final bool isBookmarked;
  final bool isFollowing;
  final bool isOwner;
  final bool isPaid;
  final int? aiSummaryRemaining;
  final int aiSummaryDailyLimit;

  CaseDiscussion({
    required this.id,
    required this.title,
    required this.description,
    this.tags,
    required this.likes,
    this.dislikes = 0,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    this.specialty,
    this.specialtyId,
    this.countryName,
    this.countryId,
    this.countryFlag,
    this.attachments = const [],
    this.aiSummary,
    this.metadata,
    this.updates = const [],
    this.decisionSupports = const [],
    this.relatedCases = const [],
    this.commentsCount = 0,
    this.followersCount = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.isBookmarked = false,
    this.isFollowing = false,
    this.isOwner = false,
    this.isPaid = false,
    this.aiSummaryRemaining,
    this.aiSummaryDailyLimit = 5,
  });

  factory CaseDiscussion.fromJson(Map<String, dynamic> json) {
    // The v6 API nests case under 'case' key in detail response
    final data = json.containsKey('case') ? json : {'case': json};
    final caseData = data['case'] as Map<String, dynamic>? ?? json;

    // Parse user/author
    CaseAuthor author;
    if (caseData['user'] is Map<String, dynamic>) {
      final u = caseData['user'] as Map<String, dynamic>;
      author = CaseAuthor(
        id: u['id'] ?? 0,
        name: formatDisplayName(
          '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim().isNotEmpty
              ? '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim()
              : u['name']?.toString(),
          'Unknown User',
        ),
        specialty: u['specialty'] ?? caseData['specialty'] ?? '',
        profilePic: AppData.fullImageUrl(u['profile_pic']),
      );
    } else {
      author = CaseAuthor(
        id: caseData['user_id'] ?? 0,
        name: formatDisplayName(caseData['name']?.toString(), 'Unknown User'),
        specialty: caseData['specialty'] ?? '',
        profilePic: AppData.fullImageUrl(caseData['profile_pic']),
        isVerified: caseData['is_verified'] == true ||
            caseData['is_verified'] == 1 ||
            data['is_verified'] == true ||
            data['is_verified'] == 1,
      );
    }

    // Parse attachments
    List<CaseAttachment> attachments = [];
    if (caseData['attached_file'] != null) {
      attachments = _parseAttachments(caseData['attached_file']);
    }

    // Parse AI summary
    AISummary? aiSummary;
    if (data['ai_summary'] != null) {
      aiSummary = AISummary.fromJson(data['ai_summary']);
    }

    // Parse metadata
    CaseMetadata? metadata;
    if (data['metadata'] != null && data['metadata'] is Map<String, dynamic>) {
      metadata = CaseMetadata.fromJson(data['metadata']);
    }

    // Parse updates
    List<CaseUpdate> updates = [];
    if (data['updates'] is List) {
      updates = (data['updates'] as List)
          .map((item) => CaseUpdate.fromJson(item))
          .toList();
    }

    // Parse decision supports
    List<DecisionSupport> decisionSupports = [];
    if (data['decision_supports'] is List) {
      decisionSupports = (data['decision_supports'] as List)
          .map((item) => DecisionSupport.fromJson(item))
          .toList();
    }

    // Parse related cases
    List<RelatedCase> relatedCases = [];
    if (data['related_cases'] is List) {
      relatedCases = (data['related_cases'] as List)
          .map((item) => RelatedCase.fromJson(item))
          .toList();
    }

    return CaseDiscussion(
      id: _parseInt(caseData['id']),
      title: caseData['title'] ?? '',
      description: caseData['description'] ?? '',
      tags: caseData['tags']?.toString(),
      likes: _parseInt(caseData['likes']),
      dislikes: _parseInt(caseData['dislikes']),
      views: _parseInt(caseData['views']),
      createdAt: DateTime.parse(
          caseData['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          caseData['updated_at'] ?? DateTime.now().toIso8601String()),
      author: author,
      specialty: caseData['specialty']?.toString(),
      specialtyId: caseData['specialty_id'] != null
          ? _parseInt(caseData['specialty_id'])
          : null,
      countryName: caseData['country_name']?.toString(),
      countryId: caseData['country_id'] != null
          ? _parseInt(caseData['country_id'])
          : null,
      countryFlag: caseData['country_flag']?.toString(),
      attachments: attachments,
      aiSummary: aiSummary,
      metadata: metadata,
      updates: updates,
      decisionSupports: decisionSupports,
      relatedCases: relatedCases,
      commentsCount: _parseInt(caseData['comments_count'] ?? caseData['comments']),
      followersCount: _parseInt(data['followers_count']),
      isLiked: data['is_liked'] == true || data['is_liked'] == 1 || (data['user_vote'] == 'up' || data['user_vote'] == 'like'),
      isDisliked: data['is_disliked'] == true || data['is_disliked'] == 1 || (data['user_vote'] == 'down' || data['user_vote'] == 'dislike'),
      isBookmarked:
          data['is_bookmarked'] == true || data['is_bookmarked'] == 1,
      isFollowing:
          data['is_following'] == true || data['is_following'] == 1,
      isOwner: data['is_owner'] == true || data['is_owner'] == 1,
      isPaid: data['is_paid'] == true || data['is_paid'] == 1,
      aiSummaryRemaining: data['ai_summary_remaining'] != null
          ? _parseInt(data['ai_summary_remaining'])
          : null,
      aiSummaryDailyLimit: data['ai_summary_daily_limit'] != null
          ? _parseInt(data['ai_summary_daily_limit'])
          : 5,
    );
  }

  /// Parse comma-separated tags
  List<String> get parsedTags {
    if (tags == null || tags!.isEmpty || tags == 'null') return [];
    try {
      return tags!
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  int get score => likes - dislikes;

  CaseDiscussion copyWith({
    int? likes,
    int? dislikes,
    int? commentsCount,
    int? followersCount,
    bool? isLiked,
    bool? isDisliked,
    bool? isBookmarked,
    bool? isFollowing,
    AISummary? aiSummary,
    List<CaseUpdate>? updates,
    bool? isPaid,
    int? aiSummaryRemaining,
    int? aiSummaryDailyLimit,
  }) {
    return CaseDiscussion(
      id: id,
      title: title,
      description: description,
      tags: tags,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      views: views,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author,
      specialty: specialty,
      specialtyId: specialtyId,
      countryName: countryName,
      countryId: countryId,
      countryFlag: countryFlag,
      attachments: attachments,
      aiSummary: aiSummary ?? this.aiSummary,
      metadata: metadata,
      updates: updates ?? this.updates,
      decisionSupports: decisionSupports,
      relatedCases: relatedCases,
      commentsCount: commentsCount ?? this.commentsCount,
      followersCount: followersCount ?? this.followersCount,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFollowing: isFollowing ?? this.isFollowing,
      isOwner: isOwner,
      isPaid: isPaid ?? this.isPaid,
      aiSummaryRemaining: aiSummaryRemaining ?? this.aiSummaryRemaining,
      aiSummaryDailyLimit: aiSummaryDailyLimit ?? this.aiSummaryDailyLimit,
    );
  }

  static List<CaseAttachment> _parseAttachments(dynamic attachedFile) {
    if (attachedFile == null) return [];
    try {
      final str = attachedFile.toString();
      if (str.isEmpty || str == 'null' || str == '[]' || str == '"[]"') {
        return [];
      }

      // Clean up escaped JSON strings
      String cleanStr = str;
      if (cleanStr.startsWith('"') && cleanStr.endsWith('"')) {
        cleanStr = cleanStr.substring(1, cleanStr.length - 1);
        cleanStr =
            cleanStr.replaceAll('\\"', '"').replaceAll('\\\\', '\\');
      }

      if (cleanStr.startsWith('[') && cleanStr.endsWith(']')) {
        final parsed = jsonDecode(cleanStr) as List;
        return parsed.asMap().entries.map((entry) {
          final url = entry.value.toString();
          return CaseAttachment(
            id: entry.key,
            type: _fileTypeFromUrl(url),
            url: AppData.fullImageUrl(url),
            description: 'Attachment ${entry.key + 1}',
          );
        }).toList();
      }
      // Single file
      return [
        CaseAttachment(
          id: 0,
          type: _fileTypeFromUrl(cleanStr),
          url: AppData.fullImageUrl(cleanStr),
          description: 'Attachment',
        ),
      ];
    } catch (_) {
      return [];
    }
  }

  static String _fileTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return 'image';
    } else if (lower.endsWith('.pdf')) {
      return 'pdf';
    } else if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return 'document';
    }
    return 'image';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTHOR
// ─────────────────────────────────────────────────────────────────────────────

class CaseAuthor {
  final dynamic id;
  final String name;
  final String specialty;
  final String? profilePic;
  final bool isVerified;

  CaseAuthor({
    required this.id,
    required this.name,
    required this.specialty,
    this.profilePic,
    this.isVerified = false,
  });

  factory CaseAuthor.fromJson(Map<String, dynamic> json) {
    String name = json['name']?.toString() ?? '';
    if (name.isEmpty) {
      name =
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim();
    }
    return CaseAuthor(
      id: json['id'] ?? 0,
      name: formatDisplayName(name, 'Unknown User'),
      specialty: json['specialty'] ?? '',
      profilePic: AppData.fullImageUrl(json['profile_pic']),
      isVerified: json['is_verified'] == true ||
          json['is_verified'] == 1 ||
          json['verified'] == true ||
          json['verified'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'profile_pic': profilePic,
        'is_verified': isVerified,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTACHMENT
// ─────────────────────────────────────────────────────────────────────────────

class CaseAttachment {
  final int id;
  final String type;
  final String url;
  final String description;

  CaseAttachment({
    required this.id,
    required this.type,
    required this.url,
    required this.description,
  });

  factory CaseAttachment.fromJson(Map<String, dynamic> json) {
    return CaseAttachment(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'image',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'url': url,
        'description': description,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// AI SUMMARY
// ─────────────────────────────────────────────────────────────────────────────

class AISummary {
  final int? id;
  final int? discussCaseId;
  final String summary;
  final double confidenceScore;
  final List<String> keyPoints;
  final int? version;
  final DateTime? generatedAt;

  AISummary({
    this.id,
    this.discussCaseId,
    required this.summary,
    this.confidenceScore = 0.0,
    this.keyPoints = const [],
    this.version,
    this.generatedAt,
  });

  factory AISummary.fromJson(Map<String, dynamic> json) {
    // Parse key points from string or list
    List<String> keyPoints = [];
    if (json['key_points'] != null) {
      try {
        if (json['key_points'] is String) {
          final str = json['key_points'] as String;
          if (str.startsWith('[')) {
            keyPoints = (jsonDecode(str) as List)
                .map((e) => e.toString())
                .toList();
          }
        } else if (json['key_points'] is List) {
          keyPoints = List<String>.from(json['key_points']);
        }
      } catch (_) {}
    }

    return AISummary(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      discussCaseId: json['discuss_case_id'] != null
          ? _parseInt(json['discuss_case_id'])
          : null,
      summary: json['summary_text'] ?? json['summary'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      keyPoints: keyPoints,
      version: json['version'],
      generatedAt: json['last_generated_at'] != null
          ? DateTime.tryParse(json['last_generated_at'])
          : (json['generated_at'] != null
              ? DateTime.tryParse(json['generated_at'])
              : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'summary': summary,
        'confidence_score': confidenceScore,
        'key_points': keyPoints,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMENT
// ─────────────────────────────────────────────────────────────────────────────

class CaseComment {
  final int id;
  final int caseId;
  final dynamic userId;
  final String comment;
  final String? clinicalTags;
  final int likes;
  final int dislikes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final CaseAuthor author;
  final int repliesCount;
  final bool isLiked;
  final bool isDisliked;
  final bool isOwner;
  final List<CaseReply> replies;

  CaseComment({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.comment,
    this.clinicalTags,
    required this.likes,
    this.dislikes = 0,
    required this.createdAt,
    this.updatedAt,
    required this.author,
    this.repliesCount = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.isOwner = false,
    this.replies = const [],
  });

  factory CaseComment.fromJson(Map<String, dynamic> json) {
    // Build author from nested user or flat fields
    CaseAuthor author;
    if (json['user'] is Map<String, dynamic>) {
      author = CaseAuthor.fromJson(json['user']);
    } else {
      author = CaseAuthor(
        id: json['user_id'] ?? 0,
        name: json['user_name'] ?? 'Unknown User',
        specialty: json['specialty'] ?? '',
        profilePic: AppData.fullImageUrl(json['profile_pic']),
        isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      );
    }

    // Parse replies if present
    List<CaseReply> replies = [];
    if (json['replies'] is List) {
      replies = (json['replies'] as List)
          .map((r) => CaseReply.fromJson(r))
          .toList();
    }

    return CaseComment(
      id: _parseInt(json['id']),
      caseId: _parseInt(json['discuss_case_id'] ?? json['case_id']),
      userId: json['user_id'] ?? 0,
      comment: json['comment'] ?? '',
      clinicalTags: json['clinical_tags'],
      likes: _parseInt(json['likes']),
      dislikes: _parseInt(json['dislikes']),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      author: author,
      repliesCount: _parseInt(json['replies_count'],
          replies.isNotEmpty ? replies.length : 0),
      isLiked: json['is_liked'] == true || json['is_liked'] == 1 || (json['user_vote'] == 'up' || json['user_vote'] == 'like'),
      isDisliked: json['is_disliked'] == true || json['is_disliked'] == 1 || (json['user_vote'] == 'down' || json['user_vote'] == 'dislike'),
      isOwner: json['is_owner'] == true || json['is_owner'] == 1,
      replies: replies,
    );
  }

  CaseComment copyWith({
    String? comment,
    int? likes,
    int? dislikes,
    bool? isLiked,
    bool? isDisliked,
    int? repliesCount,
    List<CaseReply>? replies,
  }) {
    return CaseComment(
      id: id,
      caseId: caseId,
      userId: userId,
      comment: comment ?? this.comment,
      clinicalTags: clinicalTags,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author,
      repliesCount: repliesCount ?? this.repliesCount,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isOwner: isOwner,
      replies: replies ?? this.replies,
    );
  }

  /// Parse clinical tags into a list
  List<String> get parsedClinicalTags {
    if (clinicalTags == null || clinicalTags!.isEmpty) return [];
    return clinicalTags!
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPLY
// ─────────────────────────────────────────────────────────────────────────────

class CaseReply {
  final int id;
  final int commentId;
  final dynamic userId;
  final String reply;
  final DateTime createdAt;
  final CaseAuthor author;
  final int likes;
  final int dislikes;
  final bool isLiked;
  final bool isDisliked;
  final bool isOwner;

  CaseReply({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.reply,
    required this.createdAt,
    required this.author,
    this.likes = 0,
    this.dislikes = 0,
    this.isLiked = false,
    this.isDisliked = false,
    this.isOwner = false,
  });

  int get score => likes - dislikes;

  CaseReply copyWith({
    String? reply,
    int? likes,
    int? dislikes,
    bool? isLiked,
    bool? isDisliked,
    bool? isOwner,
  }) {
    return CaseReply(
      id: id,
      commentId: commentId,
      userId: userId,
      reply: reply ?? this.reply,
      createdAt: createdAt,
      author: author,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  factory CaseReply.fromJson(Map<String, dynamic> json) {
    CaseAuthor author;
    if (json['user'] is Map<String, dynamic>) {
      author = CaseAuthor.fromJson(json['user']);
    } else {
      author = CaseAuthor(
        id: json['user_id'] ?? 0,
        name: json['user_name'] ?? 'Unknown User',
        specialty: '',
        profilePic: AppData.fullImageUrl(json['profile_pic']?.toString()),
        isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      );
    }

    return CaseReply(
      id: _parseInt(json['id']),
      commentId: _parseInt(json['comment_id'] ?? json['discuss_case_comment_id']),
      userId: json['user_id'] ?? 0,
      reply: json['comment'] ?? json['reply'] ?? '',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      author: author,
      likes: _parseInt(json['likes']),
      dislikes: _parseInt(json['dislikes']),
      isLiked: json['is_liked'] == true || json['is_liked'] == 1 || (json['user_vote'] == 'up' || json['user_vote'] == 'like'),
      isDisliked: json['is_disliked'] == true || json['is_disliked'] == 1 || (json['user_vote'] == 'down' || json['user_vote'] == 'dislike'),
      isOwner: json['is_owner'] == true || json['is_owner'] == 1,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RELATED CASE
// ─────────────────────────────────────────────────────────────────────────────

class RelatedCase {
  final int id;
  final String title;
  final String description;
  final String? tags;
  final int likes;
  final int views;
  final DateTime createdAt;
  final String? attachedFile;

  RelatedCase({
    required this.id,
    required this.title,
    required this.description,
    this.tags,
    required this.likes,
    required this.views,
    required this.createdAt,
    this.attachedFile,
  });

  factory RelatedCase.fromJson(Map<String, dynamic> json) {
    // attached_file may be a List (Eloquent array cast) or String
    String? attachedFile;
    final rawFile = json['attached_file'];
    if (rawFile is String) {
      attachedFile = rawFile;
    } else if (rawFile is List) {
      attachedFile = jsonEncode(rawFile);
    }

    return RelatedCase(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      tags: json['tags']?.toString(),
      likes: _parseInt(json['likes']),
      views: _parseInt(json['views']),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      attachedFile: attachedFile,
    );
  }

  List<String> get parsedTags {
    if (tags == null || tags!.isEmpty) return [];
    return tags!
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// METADATA
// ─────────────────────────────────────────────────────────────────────────────

class CaseMetadata {
  final int id;
  final int discussCaseId;
  final String? patientDemographics;
  final String? clinicalComplexity;
  final String? teachingValue;
  final String? evidenceLevel;
  final bool isAnonymized;
  final String? clinicalKeywords;

  CaseMetadata({
    required this.id,
    required this.discussCaseId,
    this.patientDemographics,
    this.clinicalComplexity,
    this.teachingValue,
    this.evidenceLevel,
    this.isAnonymized = false,
    this.clinicalKeywords,
  });

  factory CaseMetadata.fromJson(Map<String, dynamic> json) {
    // patient_demographics and clinical_keywords may come as Map/List (Eloquent array cast)
    // or as a JSON string (raw DB query). Normalize to String? for storage.
    String? demographics;
    final rawDem = json['patient_demographics'];
    if (rawDem is String) {
      demographics = rawDem;
    } else if (rawDem is Map || rawDem is List) {
      demographics = jsonEncode(rawDem);
    }

    String? keywords;
    final rawKw = json['clinical_keywords'];
    if (rawKw is String) {
      keywords = rawKw;
    } else if (rawKw is Map || rawKw is List) {
      keywords = jsonEncode(rawKw);
    }

    return CaseMetadata(
      id: _parseInt(json['id']),
      discussCaseId: _parseInt(json['discuss_case_id']),
      patientDemographics: demographics,
      clinicalComplexity: json['clinical_complexity']?.toString(),
      teachingValue: json['teaching_value']?.toString(),
      evidenceLevel: json['evidence_level']?.toString(),
      isAnonymized:
          json['is_anonymized'] == true || json['is_anonymized'] == 1,
      clinicalKeywords: keywords,
    );
  }

  /// Parse patient demographics JSON string
  Map<String, dynamic>? get parsedDemographics {
    if (patientDemographics == null || patientDemographics!.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(patientDemographics!);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return decoded.first as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  ClinicalSnapshot get clinicalSnapshot =>
      ClinicalSnapshot.fromDemographics(parsedDemographics);

  /// Parse clinical keywords
  List<String> get parsedKeywords {
    if (clinicalKeywords == null || clinicalKeywords!.isEmpty) return [];
    try {
      if (clinicalKeywords!.startsWith('[')) {
        return (jsonDecode(clinicalKeywords!) as List)
            .map((e) => e.toString())
            .toList();
      }
      return clinicalKeywords!
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DECISION SUPPORT
// ─────────────────────────────────────────────────────────────────────────────

class DecisionSupport {
  final int id;
  final int discussCaseId;
  final String type;
  final String content;
  final String? source;
  final DateTime createdAt;

  DecisionSupport({
    required this.id,
    required this.discussCaseId,
    required this.type,
    required this.content,
    this.source,
    required this.createdAt,
  });

  factory DecisionSupport.fromJson(Map<String, dynamic> json) {
    return DecisionSupport(
      id: _parseInt(json['id']),
      discussCaseId: _parseInt(json['discuss_case_id']),
      type: json['type']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      source: json['source']?.toString(),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CASE UPDATE (Timeline)
// ─────────────────────────────────────────────────────────────────────────────

class CaseUpdate {
  final int id;
  final int discussCaseId;
  final String updateType;
  final String content;
  final String? authorId;
  final DateTime createdAt;
  final List<String> attachedFiles;

  CaseUpdate({
    required this.id,
    required this.discussCaseId,
    required this.updateType,
    required this.content,
    this.authorId,
    required this.createdAt,
    this.attachedFiles = const [],
  });

  factory CaseUpdate.fromJson(Map<String, dynamic> json) {
    // Handle attached_files: can be List, JSON string, or double-encoded string
    var rawFiles = json['attached_files'];
    if (rawFiles is String) {
      try {
        rawFiles = jsonDecode(rawFiles);
      } catch (_) {}
    }
    // After one decode it might still be a string (double-encoded)
    if (rawFiles is String) {
      try {
        rawFiles = jsonDecode(rawFiles);
      } catch (_) {}
    }
    final files = rawFiles is List
        ? rawFiles.map((e) => e.toString()).toList()
        : <String>[];
    return CaseUpdate(
      id: _parseInt(json['id']),
      discussCaseId: _parseInt(json['discuss_case_id']),
      updateType: json['update_title']?.toString() ?? json['update_type']?.toString() ?? '',
      content: json['update_content']?.toString() ?? json['content']?.toString() ?? '',
      authorId: json['user_id']?.toString() ?? json['author_id']?.toString(),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      attachedFiles: files,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE / UPDATE REQUEST
// ─────────────────────────────────────────────────────────────────────────────

class CreateCaseRequest {
  final String title;
  final String description;
  final String? tags;
  final Map<String, dynamic>? patientDemographics;
  final String? clinicalComplexity;
  final String? teachingValue;
  final bool? isAnonymized;
  final List<String>? attachedFiles;
  final List<String>? existingFileUrls;
  final int? specialtyId;
  final int? countryId;

  CreateCaseRequest({
    required this.title,
    required this.description,
    this.tags,
    this.patientDemographics,
    this.clinicalComplexity,
    this.teachingValue,
    this.isAnonymized,
    this.attachedFiles,
    this.existingFileUrls,
    this.specialtyId,
    this.countryId,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        if (tags != null) 'tags': tags,
        if (patientDemographics != null)
          'patient_demographics': patientDemographics,
        if (clinicalComplexity != null)
          'clinical_complexity': clinicalComplexity,
        if (teachingValue != null) 'teaching_value': teachingValue,
        if (isAnonymized != null) 'is_anonymized': isAnonymized,
        if (specialtyId != null) 'specialty_id': specialtyId,
        if (countryId != null) 'country_id': countryId,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGINATION
// ─────────────────────────────────────────────────────────────────────────────

class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta pagination;

  PaginatedResponse({required this.items, required this.pagination});
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: int.tryParse(json['per_page']?.toString() ?? '12') ?? 12,
      total: json['total'] ?? 0,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTERS
// ─────────────────────────────────────────────────────────────────────────────

class SpecialtyFilter {
  final int id;
  final String name;
  final String? slug;

  SpecialtyFilter({required this.id, required this.name, this.slug});

  factory SpecialtyFilter.fromJson(Map<String, dynamic> json) {
    return SpecialtyFilter(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['specialty_name'] ?? '',
      slug: json['slug'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpecialtyFilter && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SpecialtyFilter(id: $id, name: $name)';
}

class CountryFilter {
  final int id;
  final String name;
  final String code;
  final String flag;

  CountryFilter({
    required this.id,
    required this.name,
    required this.code,
    this.flag = '',
  });

  factory CountryFilter.fromJson(Map<String, dynamic> json) {
    return CountryFilter(
      id: json['id'] ?? 0,
      name: json['countryName'] ?? json['name'] ?? '',
      code: json['countryCode'] ?? json['code'] ?? '',
      flag: json['flag'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CountryFilter && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CountryFilter(id: $id, name: $name)';
}

/// Filter state for case discussions
class CaseDiscussionFilters {
  final String? searchQuery;
  final SpecialtyFilter? selectedSpecialty;
  final CountryFilter? selectedCountry;
  final String? sortBy; // newest, most_viewed, most_discussed
  final String? tab; // null=all, my, saved, following

  const CaseDiscussionFilters({
    this.searchQuery,
    this.selectedSpecialty,
    this.selectedCountry,
    this.sortBy,
    this.tab,
  });

  CaseDiscussionFilters copyWith({
    String? searchQuery,
    SpecialtyFilter? selectedSpecialty,
    CountryFilter? selectedCountry,
    String? sortBy,
    String? tab,
    bool clearSpecialty = false,
    bool clearCountry = false,
    bool clearSort = false,
    bool clearTab = false,
    bool clearSearch = false,
  }) {
    return CaseDiscussionFilters(
      searchQuery:
          clearSearch ? null : (searchQuery ?? this.searchQuery),
      selectedSpecialty: clearSpecialty
          ? null
          : (selectedSpecialty ?? this.selectedSpecialty),
      selectedCountry: clearCountry
          ? null
          : (selectedCountry ?? this.selectedCountry),
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
      tab: clearTab ? null : (tab ?? this.tab),
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['keyword'] = searchQuery;
    }
    if (selectedSpecialty != null) {
      params['specialty'] = selectedSpecialty!.id.toString();
    }
    if (selectedCountry != null) {
      params['country'] = selectedCountry!.id.toString();
    }
    if (sortBy != null) params['sort'] = sortBy;
    if (tab != null) params['tab'] = tab;
    return params;
  }

  bool get hasActiveFilters =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      selectedSpecialty != null ||
      selectedCountry != null ||
      sortBy != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM EXCEPTIONS
// ─────────────────────────────────────────────────────────────────────────────

class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  ValidationException(this.message, [this.errors]);
  @override
  String toString() => 'ValidationException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
  @override
  String toString() => 'ForbiddenException: $message';
}
