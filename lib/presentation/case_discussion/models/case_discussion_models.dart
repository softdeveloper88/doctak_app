// Models for the Case Discussion module
import 'dart:convert';
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
  final List<RelatedCase>? relatedCases;

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
    this.relatedCases,
  });

  factory CaseDiscussion.fromJson(Map<String, dynamic> json) {
    return CaseDiscussion(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'active',
      specialty: json['specialty'] ?? '',
      specialtyId: json['specialty_id'],
      countryName: json['country_name'],
      countryFlag: json['country_flag'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      author: CaseAuthor.fromJson(json['author'] ?? {}),
      stats: CaseStats.fromJson(json['stats'] ?? {}),
      patientInfo: json['patient_info'] != null
          ? PatientInfo.fromJson(json['patient_info'])
          : null,
      symptoms: json['symptoms'] != null
          ? List<String>.from(json['symptoms'])
          : null,
      diagnosis: json['diagnosis'],
      treatmentPlan: json['treatment_plan'],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((item) => CaseAttachment.fromJson(item))
              .toList()
          : null,
      aiSummary: json['ai_summary'] != null
          ? AISummary.fromJson(json['ai_summary'])
          : null,
      metadata: json['metadata'],
      isFollowing: json['is_following'],
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
  final DateTime generatedAt;
  final String summary;
  final double confidenceScore;
  final List<String>? keyPoints;

  AISummary({
    required this.generatedAt,
    required this.summary,
    required this.confidenceScore,
    this.keyPoints,
  });

  factory AISummary.fromJson(Map<String, dynamic> json) {
    return AISummary(
      generatedAt: DateTime.parse(json['generated_at'] ?? DateTime.now().toIso8601String()),
      summary: json['summary'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 0.0).toDouble(),
      keyPoints: json['key_points'] != null
          ? List<String>.from(json['key_points'])
          : null,
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
  final String? specialtyId;
  final String? attachedFile;
  final PatientInfo? patientInfo;
  final List<String>? symptoms;
  final String? diagnosis;
  final String? treatmentPlan;
  final String? specialty;
  final String privacyLevel;
  final List<AttachmentData>? attachments;

  CreateCaseRequest({
    required this.title,
    required this.description,
    this.tags,
    this.specialtyId,
    this.attachedFile,
    this.patientInfo,
    this.symptoms,
    this.diagnosis,
    this.treatmentPlan,
    this.specialty,
    this.privacyLevel = 'public',
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (tags != null) 'tags': tags,
      if (specialtyId != null) 'specialty_id': specialtyId,
      if (attachedFile != null) 'attached_file': attachedFile,
      if (patientInfo != null) 'patient_info': {
        'age': patientInfo!.age,
        'gender': patientInfo!.gender,
        'medical_history': patientInfo!.medicalHistory,
      },
      if (symptoms != null) 'symptoms': symptoms,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (treatmentPlan != null) 'treatment_plan': treatmentPlan,
      if (specialty != null) 'specialty': specialty,
      'privacy_level': privacyLevel,
      if (attachments != null) 'attachments': attachments?.map((a) => a.toJson()).toList(),
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
