import 'package:doctak_app/core/utils/app/AppData.dart';

class OrganizationPublicProfileModel {
  OrganizationPublicProfileModel({
    required this.organization,
    required this.typeProfile,
    required this.sections,
    this.viewer,
  });

  factory OrganizationPublicProfileModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : json;
    return OrganizationPublicProfileModel(
      organization: OrganizationSummary.fromJson(
        Map<String, dynamic>.from(profile['organization'] as Map? ?? {}),
      ),
      typeProfile: Map<String, dynamic>.from(profile['type_profile'] as Map? ?? {}),
      sections: OrganizationSections.fromJson(
        Map<String, dynamic>.from(profile['sections'] as Map? ?? {}),
      ),
      viewer: profile['viewer'] is Map
          ? OrganizationViewer.fromJson(
              Map<String, dynamic>.from(profile['viewer'] as Map),
            )
          : null,
    );
  }

  final OrganizationSummary organization;
  final Map<String, dynamic> typeProfile;
  final OrganizationSections sections;
  final OrganizationViewer? viewer;

  OrganizationPublicProfileModel copyWith({
    OrganizationSummary? organization,
    OrganizationViewer? viewer,
  }) {
    return OrganizationPublicProfileModel(
      organization: organization ?? this.organization,
      typeProfile: typeProfile,
      sections: sections,
      viewer: viewer ?? this.viewer,
    );
  }
}

class OrganizationSummary {
  OrganizationSummary({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.name,
    required this.slug,
    this.description,
    this.email,
    this.phone,
    this.website,
    this.address,
    this.city,
    this.establishedAt,
    this.logoUrl,
    this.coverUrl,
    this.memberCount = 0,
    this.followerCount = 0,
    this.verificationBadge,
    required this.stats,
  });

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationSummary(
      id: _str(json['id']),
      type: _str(json['type']),
      typeLabel: _str(json['type_label'] ?? json['typeLabel']),
      name: _str(json['name']),
      slug: _str(json['slug']),
      description: _nullableStr(json['description']),
      email: _nullableStr(json['email']),
      phone: _nullableStr(json['phone']),
      website: _nullableStr(json['website']),
      address: _nullableStr(json['address']),
      city: _nullableStr(json['city']),
      establishedAt: _nullableStr(json['established_at'] ?? json['establishedAt']),
      logoUrl: _resolvedImageUrl(json['logo_url'] ?? json['logoUrl']),
      coverUrl: _resolvedImageUrl(json['cover_url'] ?? json['coverUrl']),
      memberCount: _int(json['member_count'] ?? json['memberCount']),
      followerCount: _int(json['follower_count'] ?? json['followerCount']),
      verificationBadge:
          _nullableStr(json['verification_badge'] ?? json['verificationBadge']),
      stats: OrganizationStats.fromJson(
        Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
      ),
    );
  }

  final String id;
  final String type;
  final String typeLabel;
  final String name;
  final String slug;
  final String? description;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final String? city;
  final String? establishedAt;
  final String? logoUrl;
  final String? coverUrl;
  final int memberCount;
  final int followerCount;
  final String? verificationBadge;
  final OrganizationStats stats;

  bool get isVerified => verificationBadge == 'verified';

  String get locationLine {
    return [address, city].where((v) => (v ?? '').trim().isNotEmpty).join(', ');
  }

  OrganizationSummary copyWith({
    int? followerCount,
  }) {
    return OrganizationSummary(
      id: id,
      type: type,
      typeLabel: typeLabel,
      name: name,
      slug: slug,
      description: description,
      email: email,
      phone: phone,
      website: website,
      address: address,
      city: city,
      establishedAt: establishedAt,
      logoUrl: logoUrl,
      coverUrl: coverUrl,
      memberCount: memberCount,
      followerCount: followerCount ?? this.followerCount,
      verificationBadge: verificationBadge,
      stats: stats,
    );
  }
}

class OrganizationStats {
  OrganizationStats({
    this.posts = 0,
    this.jobs = 0,
    this.cmeEvents = 0,
    this.drugPromotions = 0,
    this.surveys = 0,
  });

  factory OrganizationStats.fromJson(Map<String, dynamic> json) {
    return OrganizationStats(
      posts: _int(json['posts']),
      jobs: _int(json['jobs']),
      cmeEvents: _int(json['cme_events'] ?? json['cmeEvents']),
      drugPromotions: _int(json['drug_promotions'] ?? json['drugPromotions']),
      surveys: _int(json['surveys']),
    );
  }

  final int posts;
  final int jobs;
  final int cmeEvents;
  final int drugPromotions;
  final int surveys;
}

class OrganizationViewer {
  OrganizationViewer({
    required this.userId,
    this.isMember = false,
    this.canManage = false,
    this.isFollowingOrganization = false,
    this.ownerUserId,
    this.ownerName,
    this.connectionStatus,
  });

  factory OrganizationViewer.fromJson(Map<String, dynamic> json) {
    return OrganizationViewer(
      userId: _str(json['user_id'] ?? json['userId']),
      isMember: json['is_member'] == true || json['isMember'] == true,
      canManage: json['can_manage'] == true || json['canManage'] == true,
      isFollowingOrganization: json['is_following_organization'] == true ||
          json['isFollowingOrganization'] == true,
      ownerUserId: _nullableStr(json['owner_user_id'] ?? json['ownerUserId']),
      ownerName: _nullableStr(json['owner_name'] ?? json['ownerName']),
      connectionStatus:
          _nullableStr(json['connection_status'] ?? json['connectionStatus']),
    );
  }

  final String userId;
  final bool isMember;
  final bool canManage;
  final bool isFollowingOrganization;
  final String? ownerUserId;
  final String? ownerName;
  final String? connectionStatus;

  OrganizationViewer copyWith({bool? isFollowingOrganization}) {
    return OrganizationViewer(
      userId: userId,
      isMember: isMember,
      canManage: canManage,
      isFollowingOrganization:
          isFollowingOrganization ?? this.isFollowingOrganization,
      ownerUserId: ownerUserId,
      ownerName: ownerName,
      connectionStatus: connectionStatus,
    );
  }
}

class OrganizationSections {
  OrganizationSections({
    this.posts = const [],
    this.jobs = const [],
    this.cmeEvents = const [],
    this.drugPromotions = const [],
    this.surveys = const [],
  });

  factory OrganizationSections.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(dynamic raw, T Function(Map<String, dynamic>) builder) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((item) => builder(Map<String, dynamic>.from(item)))
          .toList();
    }

    return OrganizationSections(
      posts: mapList(json['posts'], OrganizationPostSummary.fromJson),
      jobs: mapList(json['jobs'], OrganizationJobSummary.fromJson),
      cmeEvents: mapList(
        json['cme_events'] ?? json['cmeEvents'],
        OrganizationCmeSummary.fromJson,
      ),
      drugPromotions: mapList(
        json['drug_promotions'] ?? json['drugPromotions'],
        OrganizationDrugPromotionSummary.fromJson,
      ),
      surveys: mapList(json['surveys'], OrganizationSurveySummary.fromJson),
    );
  }

  final List<OrganizationPostSummary> posts;
  final List<OrganizationJobSummary> jobs;
  final List<OrganizationCmeSummary> cmeEvents;
  final List<OrganizationDrugPromotionSummary> drugPromotions;
  final List<OrganizationSurveySummary> surveys;
}

class OrganizationPostSummary {
  OrganizationPostSummary({
    required this.id,
    this.userId,
    this.body,
    this.title,
    this.createdAt,
    this.privacy,
    this.mediaUrl,
    List<String>? mediaUrls,
    this.mediaType,
    this.mediaCount = 0,
    List<OrganizationPostMediaFile>? mediaFiles,
    this.commentsCount = 0,
    this.likesCount = 0,
  })  : mediaUrls = List<String>.from(mediaUrls ?? const []),
        mediaFiles = List<OrganizationPostMediaFile>.from(
          mediaFiles ?? const [],
        );

  factory OrganizationPostSummary.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['media_files'] ?? json['mediaFiles'];
    final mediaFiles = _parseOrganizationPostMediaFiles(rawFiles);

    final rawUrls = json['media_urls'] ?? json['mediaUrls'];
    final mediaUrls = rawUrls is List
        ? rawUrls
            .map((item) => AppData.fullImageUrl(item?.toString()))
            .where((url) => url.isNotEmpty)
            .toList()
        : const <String>[];

    return OrganizationPostSummary(
      id: _str(json['id']),
      userId: _nullableStr(json['user_id'] ?? json['userId']),
      body: _nullableStr(json['body']),
      title: _nullableStr(json['title']),
      createdAt: _nullableStr(json['created_at'] ?? json['createdAt']),
      privacy: _nullableStr(json['privacy']),
      mediaUrl: _resolvedImageUrl(json['media_url'] ?? json['mediaUrl']),
      mediaUrls: mediaUrls,
      mediaType: _nullableStr(json['media_type'] ?? json['mediaType']),
      mediaCount: _int(json['media_count'] ?? json['mediaCount']),
      mediaFiles: mediaFiles,
      commentsCount: _int(json['comments_count'] ?? json['commentsCount']),
      likesCount: _int(json['likes_count'] ?? json['likesCount']),
    );
  }

  final String id;
  final String? userId;
  final String? body;
  final String? title;
  final String? createdAt;
  final String? privacy;
  final String? mediaUrl;
  final List<String> mediaUrls;
  final String? mediaType;
  final int mediaCount;
  final List<OrganizationPostMediaFile> mediaFiles;
  final int commentsCount;
  final int likesCount;

  /// Always returns a concrete list — never null.
  List<OrganizationPostMediaFile> get resolvedMediaFiles =>
      List<OrganizationPostMediaFile>.from(mediaFiles);

  String get preview {
    final value = (body ?? title ?? '').trim();
    return value.isEmpty ? 'Post' : value;
  }
}

class OrganizationPostMediaFile {
  const OrganizationPostMediaFile({required this.url, this.type});

  factory OrganizationPostMediaFile.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'] ??
        json['media_url'] ??
        json['mediaUrl'] ??
        json['media_path'] ??
        json['mediaPath'];
    final resolved = _resolvedImageUrl(rawUrl) ?? '';
    return OrganizationPostMediaFile(
      url: resolved,
      type: _nullableStr(
        json['type'] ?? json['media_type'] ?? json['mediaType'],
      ),
    );
  }

  final String url;
  final String? type;
}

class OrganizationJobSummary {
  OrganizationJobSummary({
    required this.id,
    required this.title,
    this.location,
    this.country,
    this.jobType,
    this.createdAt,
    this.applicants = 0,
  });

  factory OrganizationJobSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationJobSummary(
      id: _str(json['id']),
      title: _str(json['title']),
      location: _nullableStr(json['location']),
      country: _nullableStr(json['country']),
      jobType: _nullableStr(json['job_type'] ?? json['jobType']),
      createdAt: _nullableStr(json['created_at'] ?? json['createdAt']),
      applicants: _int(json['applicants']),
    );
  }

  final String id;
  final String title;
  final String? location;
  final String? country;
  final String? jobType;
  final String? createdAt;
  final int applicants;
}

class OrganizationCmeSummary {
  OrganizationCmeSummary({
    required this.id,
    required this.title,
    this.status,
    this.eventType,
    this.description,
    this.coverImage,
    this.startDate,
    this.endDate,
    this.registrationsCount = 0,
  });

  factory OrganizationCmeSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationCmeSummary(
      id: _str(json['id']),
      title: _str(json['title']),
      status: _nullableStr(json['status']),
      eventType: _nullableStr(json['event_type'] ?? json['eventType']),
      description: _nullableStr(json['description']),
      coverImage: AppData.fullImageUrl(
        _nullableStr(json['cover_image'] ?? json['coverImage']),
      ),
      startDate: _nullableStr(json['start_date'] ?? json['startDate']),
      endDate: _nullableStr(json['end_date'] ?? json['endDate']),
      registrationsCount:
          _int(json['registrations_count'] ?? json['registrationsCount']),
    );
  }

  final String id;
  final String title;
  final String? status;
  final String? eventType;
  final String? description;
  final String? coverImage;
  final String? startDate;
  final String? endDate;
  final int registrationsCount;
}

class OrganizationDrugPromotionSummary {
  OrganizationDrugPromotionSummary({
    required this.id,
    required this.drugName,
    this.genericName,
    this.description,
    this.imageUrl,
    this.status,
    this.planName,
    this.impressions = 0,
    this.clicks = 0,
  });

  factory OrganizationDrugPromotionSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationDrugPromotionSummary(
      id: _str(json['id']),
      drugName: _str(json['drug_name'] ?? json['drugName']),
      genericName: _nullableStr(json['generic_name'] ?? json['genericName']),
      description: _nullableStr(json['description']),
      imageUrl: AppData.fullImageUrl(
        _nullableStr(json['image_url'] ?? json['imageUrl']),
      ),
      status: _nullableStr(json['status']),
      planName: _nullableStr(json['plan_name'] ?? json['planName']),
      impressions: _int(json['impressions']),
      clicks: _int(json['clicks']),
    );
  }

  final String id;
  final String drugName;
  final String? genericName;
  final String? description;
  final String? imageUrl;
  final String? status;
  final String? planName;
  final int impressions;
  final int clicks;
}

class OrganizationSurveySummary {
  OrganizationSurveySummary({
    required this.id,
    required this.title,
    this.description,
    this.surveyType,
    this.status,
    this.responseCount = 0,
    this.questionCount = 0,
  });

  factory OrganizationSurveySummary.fromJson(Map<String, dynamic> json) {
    return OrganizationSurveySummary(
      id: _str(json['id']),
      title: _str(json['title']),
      description: _nullableStr(json['description']),
      surveyType: _nullableStr(json['survey_type'] ?? json['surveyType']),
      status: _nullableStr(json['status']),
      responseCount: _int(json['response_count'] ?? json['responseCount']),
      questionCount: _int(json['question_count'] ?? json['questionCount']),
    );
  }

  final String id;
  final String title;
  final String? description;
  final String? surveyType;
  final String? status;
  final int responseCount;
  final int questionCount;
}

String _str(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String? _nullableStr(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _resolvedImageUrl(dynamic value) {
  final resolved = AppData.fullImageUrl(_nullableStr(value));
  return resolved.isEmpty ? null : resolved;
}

List<OrganizationPostMediaFile> _parseOrganizationPostMediaFiles(dynamic raw) {
  if (raw is! List) return const [];

  final files = <OrganizationPostMediaFile>[];
  for (final item in raw) {
    if (item is! Map) continue;
    try {
      final file = OrganizationPostMediaFile.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (file.url.isNotEmpty) {
        files.add(file);
      }
    } catch (_) {
      continue;
    }
  }
  return files;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

enum OrganizationPeopleListKind { followers, members }

class OrganizationPersonSummary {
  const OrganizationPersonSummary({
    required this.userId,
    required this.name,
    this.profilePic,
    this.role,
    this.followedAt,
    this.username,
  });

  factory OrganizationPersonSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationPersonSummary(
      userId: _str(json['user_id'] ?? json['userId']),
      name: _str(json['name'], 'Member'),
      profilePic: _resolvedImageUrl(
        json['profile_pic'] ?? json['profilePic'],
      ),
      role: _nullableStr(json['role']),
      followedAt: _nullableStr(json['followed_at'] ?? json['followedAt']),
      username: _nullableStr(json['username']),
    );
  }

  final String userId;
  final String name;
  final String? profilePic;
  final String? role;
  final String? followedAt;
  final String? username;
}

class OrganizationPeoplePage {
  const OrganizationPeoplePage({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory OrganizationPeoplePage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => OrganizationPersonSummary.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((person) => person.userId.isNotEmpty)
            .toList()
        : const <OrganizationPersonSummary>[];

    return OrganizationPeoplePage(
      items: items,
      total: _int(json['total']),
      page: _int(json['page']),
      perPage: _int(json['per_page'] ?? json['perPage']),
    );
  }

  final List<OrganizationPersonSummary> items;
  final int total;
  final int page;
  final int perPage;

  bool get hasMore => page * perPage < total;
}

const organizationTypeProfileLabels = <String, String>{
  'departments': 'Departments',
  'bedCount': 'Bed count',
  'accreditations': 'Accreditations',
  'servicesOffered': 'Services offered',
  'emergencyServices': 'Emergency services',
  'companySize': 'Company size',
  'industryFocus': 'Industry focus',
  'specialtiesHired': 'Specialties hired',
  'recruitmentAreas': 'Recruitment areas',
  'accreditationBody': 'Accreditation body',
  'creditTypesOffered': 'Credit types offered',
  'specialtiesServed': 'Specialties served',
  'keyProducts': 'Key products',
  'targetMarket': 'Target market',
  'companyType': 'Company type',
};
