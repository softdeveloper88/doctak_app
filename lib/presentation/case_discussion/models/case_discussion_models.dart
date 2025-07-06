// Models for the Case Discussion module
import 'dart:convert';

// Separate model for discussion list items (simplified data)
class CaseDiscussionListItem {
  final int id;
  final String title;
  final String? tags;
  final int likes;
  final int views;
  final String? attachedFile;
  final int promoted;
  final DateTime createdAt;
  final String name;
  final String? profilePic;
  final String? specialty;
  final int comments;

  CaseDiscussionListItem({
    required this.id,
    required this.title,
    this.tags,
    required this.likes,
    required this.views,
    this.attachedFile,
    required this.promoted,
    required this.createdAt,
    required this.name,
    this.profilePic,
    this.specialty,
    required this.comments,
  });

  factory CaseDiscussionListItem.fromJson(Map<String, dynamic> json) {
    return CaseDiscussionListItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      tags: json['tags'],
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
      attachedFile: json['attached_file'],
      promoted: json['promoted'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      name: json['name'] ?? 'Unknown User',
      profilePic: json['profile_pic'],
      specialty: json['specialty'],
      comments: json['comments'] ?? 0,
    );
  }

  // Parse tags to extract clean values - now expects simple comma-separated format
  List<String> get parsedTags {
    if (tags == null || tags!.isEmpty || tags == 'null') return [];
    
    try {
      // Handle comma-separated format: "tag1,tag2,tag3" or "tag1, tag2, tag3"
      if (tags!.contains(',')) {
        return tags!
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
      } else {
        // Handle single tag
        return [tags!.trim()];
      }
    } catch (e) {
      print('Error parsing tags: $e');
      return [tags!];
    }
  }

  // Get author info in consistent format
  CaseAuthor get author {
    return CaseAuthor(
      id: id, // Use case id since user_id not available in list
      name: name,
      specialty: specialty ?? 'Medical Professional',
      profilePic: profilePic,
    );
  }

  // Get stats in consistent format
  CaseStats get stats {
    return CaseStats(
      commentsCount: comments,
      followersCount: 0, // Not available in list
      updatesCount: 0, // Not available in list
      likes: likes,
      views: views,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'tags': tags,
      'likes': likes,
      'views': views,
      'attached_file': attachedFile,
      'promoted': promoted,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'profile_pic': profilePic,
      'specialty': specialty,
      'comments': comments,
    };
  }
}
class CaseDiscussion {
  final int id;
  final String title;
  final String description;
  final String status;
  final String specialty;
  final int? specialtyId;
  final String? countryName;
  final String? countryFlag;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CaseAuthor author;
  final CaseStats stats;
  final PatientInfo? patientInfo;
  final List<String>? symptoms;
  final String? diagnosis;
  final String? treatmentPlan;
  final List<CaseAttachment>? attachments;
  final AISummary? aiSummary;
  
  // Additional fields from new API
  final Map<String, dynamic>? metadata;
  final bool? isFollowing;
  final bool? isLiked;
  final List<RelatedCase>? relatedCases;
  final CaseMetadata? caseMetadata;
  final List<DecisionSupport>? decisionSupports;
  final List<CaseUpdate>? updates;
  final int? followersCount;

  CaseDiscussion({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.specialty,
    this.specialtyId,
    this.countryName,
    this.countryFlag,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.stats,
    this.patientInfo,
    this.symptoms,
    this.diagnosis,
    this.treatmentPlan,
    this.attachments,
    this.aiSummary,
    this.metadata,
    this.isFollowing,
    this.isLiked,
    this.relatedCases,
    this.caseMetadata,
    this.decisionSupports,
    this.updates,
    this.followersCount,
  });

  factory CaseDiscussion.fromJson(Map<String, dynamic> json) {
    // Handle new detailed API structure where case data is nested under 'case' key
    Map<String, dynamic> caseData;
    if (json.containsKey('case') && json['case'] is Map<String, dynamic>) {
      // New detailed API structure
      caseData = json['case'] as Map<String, dynamic>;
    } else {
      // Legacy structure or direct case data
      caseData = json;
    }

    // Handle tags parsing - now expects simple comma-separated format from API
    List<String>? parsedTags;
    if (caseData['tags'] != null && caseData['tags'].toString().isNotEmpty && caseData['tags'] != "\"[]\"") {
      try {
        final tagsString = caseData['tags'].toString();
        // Handle comma-separated format: "tag1,tag2,tag3" or "tag1, tag2, tag3"
        if (tagsString.contains(',')) {
          parsedTags = tagsString.split(',').map((e) => e.trim()).where((tag) => tag.isNotEmpty).toList();
        } else if (tagsString.isNotEmpty) {
          // Single tag
          parsedTags = [tagsString.trim()];
        }
      } catch (e) {
        print('Error parsing tags: $e');
      }
    }

    // Handle attachments parsing
    List<CaseAttachment>? attachments;
    if (caseData['attached_file'] != null && caseData['attached_file'].toString() != "\"[]\"") {
      try {
        final attachedFileString = caseData['attached_file'].toString();
        if (attachedFileString.startsWith('[') && attachedFileString.endsWith(']')) {
          final parsed = jsonDecode(attachedFileString) as List;
          attachments = parsed.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            if (item is String) {
              return CaseAttachment(
                id: index,
                type: 'image',
                url: item,
                description: 'Attachment ${index + 1}',
              );
            }
            return CaseAttachment.fromJson(item);
          }).toList();
        }
      } catch (e) {
        print('Error parsing attached files: $e');
      }
    }

    return CaseDiscussion(
      id: caseData['id'] ?? 0,
      title: caseData['title'] ?? '',
      description: caseData['description'] ?? '',
      status: caseData['status'] ?? 'active',
      specialty: caseData['specialty'] ?? 'General',
      specialtyId: caseData['specialty_id'],
      countryName: caseData['country_name'],
      countryFlag: caseData['country_flag'],
      createdAt: DateTime.parse(caseData['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(caseData['updated_at'] ?? DateTime.now().toIso8601String()),
      author: CaseAuthor.fromJson({
        'id': caseData['user_id'] ?? caseData['id'] ?? 0,
        'name': caseData['name'] ?? 'Unknown User',
        'specialty': caseData['specialty'] ?? '',
        'profile_pic': caseData['profile_pic'],
      }),
      stats: CaseStats.fromJson({
        'comments_count': caseData['comments'] ?? 0,
        'followers_count': json['followers_count'] ?? 0, // From top level
        'updates_count': 0,
        'likes': caseData['likes'] ?? 0,
        'views': caseData['views'] ?? 0,
      }),
      patientInfo: caseData['patient_info'] != null
          ? PatientInfo.fromJson(caseData['patient_info'])
          : null,
      symptoms: parsedTags,
      diagnosis: caseData['diagnosis'],
      treatmentPlan: caseData['treatment_plan'],
      attachments: attachments,
      aiSummary: json['ai_summary'] != null
          ? AISummary.fromJson(json['ai_summary'])
          : null,
      metadata: json['metadata'], // Top-level metadata map
      isFollowing: json['is_following'],
      isLiked: json['is_like'],
      followersCount: json['followers_count'],
      caseMetadata: json['metadata'] != null
          ? CaseMetadata.fromJson(json['metadata'])
          : null,
      decisionSupports: json['decision_supports'] != null
          ? (json['decision_supports'] as List)
              .map((item) => DecisionSupport.fromJson(item))
              .toList()
          : [],
      updates: json['updates'] != null
          ? (json['updates'] as List)
              .map((item) => CaseUpdate.fromJson(item))
              .toList()
          : [],
      relatedCases: json['related_cases'] != null
          ? (json['related_cases'] as List)
              .map((item) => RelatedCase.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'specialty': specialty,
      'specialty_id': specialtyId,
      'country_name': countryName,
      'country_flag': countryFlag,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'author': author.toJson(),
      'stats': stats.toJson(),
      if (patientInfo != null) 'patient_info': patientInfo!.toJson(),
      if (symptoms != null) 'symptoms': symptoms,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (treatmentPlan != null) 'treatment_plan': treatmentPlan,
      if (attachments != null)
        'attachments': attachments!.map((a) => a.toJson()).toList(),
      if (aiSummary != null) 'ai_summary': aiSummary!.toJson(),
    };
  }
}

class CaseAuthor {
  final dynamic id;
  final String name;
  final String specialty;
  final String? profilePic;

  CaseAuthor({
    required this.id,
    required this.name,
    required this.specialty,
    this.profilePic,
  });

  factory CaseAuthor.fromJson(Map<String, dynamic> json) {
    return CaseAuthor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'profile_pic': profilePic,
    };
  }
}

class CaseStats {
  final int commentsCount;
  final int followersCount;
  final int updatesCount;
  final int likes;
  final int views;

  CaseStats({
    required this.commentsCount,
    required this.followersCount,
    required this.updatesCount,
    required this.likes,
    required this.views,
  });

  factory CaseStats.fromJson(Map<String, dynamic> json) {
    return CaseStats(
      commentsCount: json['comments_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      updatesCount: json['updates_count'] ?? 0,
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comments_count': commentsCount,
      'followers_count': followersCount,
      'updates_count': updatesCount,
      'likes': likes,
      'views': views,
    };
  }
}

class PatientInfo {
  final int age;
  final String gender;
  final String medicalHistory;

  PatientInfo({
    required this.age,
    required this.gender,
    required this.medicalHistory,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    return PatientInfo(
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      medicalHistory: json['medical_history'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'medical_history': medicalHistory,
    };
  }
}

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
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'description': description,
    };
  }
}

class AISummary {
  final int? id;
  final int? discussCaseId;
  final DateTime generatedAt;
  final String summary;
  final double confidenceScore;
  final List<String>? keyPoints;
  final int? version;
  final DateTime? lastGeneratedAt;

  AISummary({
    this.id,
    this.discussCaseId,
    required this.generatedAt,
    required this.summary,
    required this.confidenceScore,
    this.keyPoints,
    this.version,
    this.lastGeneratedAt,
  });

  factory AISummary.fromJson(Map<String, dynamic> json) {
    // Parse key points
    List<String>? parsedKeyPoints;
    if (json['key_points'] != null) {
      try {
        if (json['key_points'] is String) {
          final keyPointsString = json['key_points'] as String;
          if (keyPointsString.startsWith('[') && keyPointsString.endsWith(']')) {
            final parsed = jsonDecode(keyPointsString) as List;
            parsedKeyPoints = parsed.map((item) => item.toString()).toList();
          }
        } else if (json['key_points'] is List) {
          parsedKeyPoints = List<String>.from(json['key_points']);
        }
      } catch (e) {
        print('Error parsing AI summary key points: $e');
      }
    }

    return AISummary(
      id: json['id'],
      discussCaseId: json['discuss_case_id'],
      generatedAt: DateTime.parse(json['last_generated_at'] ?? json['generated_at'] ?? DateTime.now().toIso8601String()),
      summary: json['summary_text'] ?? json['summary'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      keyPoints: parsedKeyPoints,
      version: json['version'],
      lastGeneratedAt: json['last_generated_at'] != null ? DateTime.parse(json['last_generated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt.toIso8601String(),
      'summary': summary,
      'confidence_score': confidenceScore,
      if (keyPoints != null) 'key_points': keyPoints,
    };
  }
}

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
  final bool? isLiked;
  final bool? isDisliked;

  CaseComment({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.comment,
    this.clinicalTags,
    required this.likes,
    required this.dislikes,
    required this.createdAt,
    this.updatedAt,
    required this.author,
    required this.repliesCount,
    this.isLiked,
    this.isDisliked,
  });

  factory CaseComment.fromJson(Map<String, dynamic> json) {
    // Handle user data - could be nested under 'user' or directly in json
    Map<String, dynamic> userData = {};
    if (json['user'] != null && json['user'] is Map) {
      userData = json['user'] as Map<String, dynamic>;
    } else {
      // Use fields directly from comment if no nested user object
      userData = {
        'id': json['user_id'] ?? 0,
        'name': json['user_name'] ?? 'Unknown User',
        'first_name': json['user_name']?.split(' ').first ?? 'Unknown',
        'last_name': json['user_name']?.split(' ').skip(1).join(' ') ?? '',
        'specialty': json['specialty'] ?? '',
        'profile_pic': json['profile_pic'],
      };
    }
    
    return CaseComment(
      id: json['id'] ?? 0,
      caseId: json['discuss_case_id'] ?? json['case_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      comment: json['comment'] ?? '',
      clinicalTags: json['clinical_tags'] ?? json['specialty'],
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      author: CaseAuthor.fromJson(userData),
      repliesCount: json['replies_count'] ?? 0,
      isLiked: json['is_liked'],
      isDisliked: json['is_disliked'],
    );
  }
}

class CreateCaseRequest {
  final String title;
  final String description;
  final String? tags;
  // final String? specialtyId;
  final Map<String, dynamic>? patientDemographics;
  final String? clinicalComplexity;
  final String? teachingValue;
  final bool? isAnonymized;
  final List<String>? attachedFiles;

  CreateCaseRequest({
    required this.title,
    required this.description,
    this.tags,
    // this.specialtyId,
    this.patientDemographics,
    this.clinicalComplexity,
    this.teachingValue,
    this.isAnonymized,
    this.attachedFiles,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (tags != null) 'tags': tags,
      // if (specialtyId != null) 'specialty_id': specialtyId,
      if (patientDemographics != null) 'patient_demographics': patientDemographics,
      if (clinicalComplexity != null) 'clinical_complexity': clinicalComplexity,
      if (teachingValue != null) 'teaching_value': teachingValue,
      if (isAnonymized != null) 'is_anonymized': isAnonymized,
      if (attachedFiles != null) 'attached_files': attachedFiles,
    };
  }
}

class AttachmentData {
  final String type;
  final String file; // base64 encoded
  final String description;

  AttachmentData({
    required this.type,
    required this.file,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'file': file,
      'description': description,
    };
  }
}

class ApiResponse<T> {
  final String status;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final ApiMeta meta;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
    this.errors,
    required this.meta,
  });

  bool get isSuccess => status == 'success';

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      errors: json['errors'],
      meta: ApiMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

class ApiMeta {
  final DateTime timestamp;
  final String version;

  ApiMeta({
    required this.timestamp,
    required this.version,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      version: json['version'] ?? 'v3',
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta pagination;

  PaginatedResponse({
    required this.items,
    required this.pagination,
  });
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
      perPage: json['per_page'] ?? 15,
      total: json['total'] ?? 0,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
}

// Filter models for case discussions
class SpecialtyFilter {
  final int id;
  final String name;
  final String slug;
  final bool isActive;

  SpecialtyFilter({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  factory SpecialtyFilter.fromJson(Map<String, dynamic> json) {
    return SpecialtyFilter(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialtyFilter && other.id == id;
  }

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
    required this.flag,
  });

  factory CountryFilter.fromJson(Map<String, dynamic> json) {
    return CountryFilter(
      id: json['id'] ?? 0,
      name: json['countryName'] ?? json['name'] ?? '',
      code: json['countryCode'] ?? json['code'] ?? '',
      flag: json['flag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'flag': flag,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryFilter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CountryFilter(id: $id, name: $name)';
}

class CaseDiscussionFilters {
  final String? searchQuery;
  final SpecialtyFilter? selectedSpecialty;
  final CountryFilter? selectedCountry;
  final String? sortBy;
  final String? sortOrder;
  final CaseStatus? status;

  const CaseDiscussionFilters({
    this.searchQuery,
    this.selectedSpecialty,
    this.selectedCountry,
    this.sortBy,
    this.sortOrder,
    this.status,
  });

  CaseDiscussionFilters copyWith({
    String? searchQuery,
    SpecialtyFilter? selectedSpecialty,
    CountryFilter? selectedCountry,
    String? sortBy,
    String? sortOrder,
    CaseStatus? status,
    bool clearSpecialty = false,
    bool clearCountry = false,
    bool clearSort = false,
    bool clearStatus = false,
  }) {
    return CaseDiscussionFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSpecialty:
          clearSpecialty ? null : (selectedSpecialty ?? this.selectedSpecialty),
      selectedCountry:
          clearCountry ? null : (selectedCountry ?? this.selectedCountry),
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
      sortOrder: clearSort ? null : (sortOrder ?? this.sortOrder),
      status: clearStatus ? null : (status ?? this.status),
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
    if (sortBy != null) {
      params['sort'] = sortBy;
    }
    if (status != null) {
      params['status'] = status!.value;
    }
    
    return params;
  }
}

enum CaseStatus {
  active('active'),
  closed('closed'),
  pending('pending'),
  resolved('resolved');

  const CaseStatus(this.value);
  final String value;

  static CaseStatus? fromString(String? value) {
    try {
      return CaseStatus.values
          .firstWhere((status) => status.value == value);
    } catch (e) {
      return null;
    }
  }
}

// Related Case model for displaying related cases
class RelatedCase {
  final int id;
  final String title;
  final String description;
  final String? tags;
  final int likes;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? attachedFile;

  RelatedCase({
    required this.id,
    required this.title,
    required this.description,
    this.tags,
    required this.likes,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
    this.attachedFile,
  });

  factory RelatedCase.fromJson(Map<String, dynamic> json) {
    return RelatedCase(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      tags: json['tags'],
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      attachedFile: json['attached_file'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tags': tags,
      'likes': likes,
      'views': views,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attached_file': attachedFile,
    };
  }

  // Parse tags if they are in JSON format
  List<String>? get parsedTags {
    if (tags == null || tags!.isEmpty) return null;
    try {
      if (tags!.startsWith('[') && tags!.endsWith(']')) {
        final parsed = json.decode(tags!) as List;
        return parsed.map((tag) => tag['value'].toString()).toList();
      }
    } catch (e) {
      print('Error parsing related case tags: $e');
    }
    return null;
  }
}

// New models for the updated API response structure
class CaseMetadata {
  final int id;
  final int discussCaseId;
  final String? patientDemographics;
  final String? clinicalComplexity;
  final String? teachingValue;
  final String? evidenceLevel;
  final bool? isAnonymized;
  final String? clinicalKeywords;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaseMetadata({
    required this.id,
    required this.discussCaseId,
    this.patientDemographics,
    this.clinicalComplexity,
    this.teachingValue,
    this.evidenceLevel,
    this.isAnonymized,
    this.clinicalKeywords,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseMetadata.fromJson(Map<String, dynamic> json) {
    return CaseMetadata(
      id: json['id'] ?? 0,
      discussCaseId: json['discuss_case_id'] ?? 0,
      patientDemographics: json['patient_demographics'],
      clinicalComplexity: json['clinical_complexity'],
      teachingValue: json['teaching_value'],
      evidenceLevel: json['evidence_level'],
      isAnonymized: json['is_anonymized'],
      clinicalKeywords: json['clinical_keywords'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'discuss_case_id': discussCaseId,
      'patient_demographics': patientDemographics,
      'clinical_complexity': clinicalComplexity,
      'teaching_value': teachingValue,
      'evidence_level': evidenceLevel,
      'is_anonymized': isAnonymized,
      'clinical_keywords': clinicalKeywords,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to parse patient demographics
  Map<String, dynamic>? get parsedPatientDemographics {
    if (patientDemographics == null || patientDemographics!.isEmpty) return null;
    try {
      final decoded = json.decode(patientDemographics!);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is List && decoded.isNotEmpty) {
        // If it's a list, try to use the first item as a map
        final firstItem = decoded.first;
        if (firstItem is Map<String, dynamic>) {
          return firstItem;
        }
      }
      // If neither Map nor usable List, return null
      return null;
    } catch (e) {
      print('Error parsing patient demographics: $e');
      return null;
    }
  }

  // Helper method to parse clinical keywords
  List<String>? get parsedClinicalKeywords {
    if (clinicalKeywords == null || clinicalKeywords!.isEmpty) return null;
    try {
      if (clinicalKeywords!.startsWith('[') && clinicalKeywords!.endsWith(']')) {
        final parsed = json.decode(clinicalKeywords!);
        if (parsed is List) {
          return parsed.map((item) => item.toString()).toList();
        }
      }
    } catch (e) {
      print('Error parsing clinical keywords: $e');
    }
    return null;
  }
}

class DecisionSupport {
  final int id;
  final int discussCaseId;
  final String type;
  final String content;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;

  DecisionSupport({
    required this.id,
    required this.discussCaseId,
    required this.type,
    required this.content,
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DecisionSupport.fromJson(Map<String, dynamic> json) {
    return DecisionSupport(
      id: json['id'] ?? 0,
      discussCaseId: json['discuss_case_id'] ?? 0,
      type: json['type'] ?? '',
      content: json['content'] ?? '',
      source: json['source'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'discuss_case_id': discussCaseId,
      'type': type,
      'content': content,
      'source': source,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CaseUpdate {
  final int id;
  final int discussCaseId;
  final String updateType;
  final String content;
  final String? authorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaseUpdate({
    required this.id,
    required this.discussCaseId,
    required this.updateType,
    required this.content,
    this.authorId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseUpdate.fromJson(Map<String, dynamic> json) {
    return CaseUpdate(
      id: json['id'] ?? 0,
      discussCaseId: json['discuss_case_id'] ?? 0,
      updateType: json['update_type'] ?? '',
      content: json['content'] ?? '',
      authorId: json['author_id']?.toString(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'discuss_case_id': discussCaseId,
      'update_type': updateType,
      'content': content,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
