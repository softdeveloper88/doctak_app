/// Job DTOs aligned with doctak-node `lib/server/jobs/types.ts` (camelCase JSON).

import 'package:doctak_app/core/utils/app/AppData.dart';

class JobOrganizationDto {
  final String? id;
  final String? name;
  final String? type;
  final String? logoUrl;

  const JobOrganizationDto({this.id, this.name, this.type, this.logoUrl});

  factory JobOrganizationDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const JobOrganizationDto();
    return JobOrganizationDto(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
      type: json['type']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
    );
  }
}

class JobStatsDto {
  final int views;
  final int clicks;
  final int applicants;
  final int newApplicants;
  final int shortlisted;
  final int hired;
  final int rejected;

  const JobStatsDto({
    this.views = 0,
    this.clicks = 0,
    this.applicants = 0,
    this.newApplicants = 0,
    this.shortlisted = 0,
    this.hired = 0,
    this.rejected = 0,
  });

  factory JobStatsDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const JobStatsDto();
    int n(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    return JobStatsDto(
      views: n(json['views']),
      clicks: n(json['clicks']),
      applicants: n(json['applicants']),
      newApplicants: n(json['newApplicants']),
      shortlisted: n(json['shortlisted']),
      hired: n(json['hired']),
      rejected: n(json['rejected']),
    );
  }
}

class JobCardDto {
  final String id;
  final String title;
  final String? companyName;
  final String? location;
  final String? experience;
  final String? specialty;
  final List<String> specialties;
  final String? jobType;
  final String? salaryRange;
  final String? description;
  final String? image;
  final String? lastDate;
  final String? createdAt;
  final String? country;
  final bool promoted;
  final String? promotionTier;
  final bool isFreeTier;
  final JobOrganizationDto? organization;
  final String? posterUserId;
  final JobStatsDto stats;
  final bool isApplied;
  final bool isBookmarked;
  final int? daysLeft;
  final bool isExpired;

  const JobCardDto({
    required this.id,
    required this.title,
    this.companyName,
    this.location,
    this.experience,
    this.specialty,
    this.specialties = const [],
    this.jobType,
    this.salaryRange,
    this.description,
    this.image,
    this.lastDate,
    this.createdAt,
    this.country,
    this.promoted = false,
    this.promotionTier,
    this.isFreeTier = false,
    this.organization,
    this.posterUserId,
    this.stats = const JobStatsDto(),
    this.isApplied = false,
    this.isBookmarked = false,
    this.daysLeft,
    this.isExpired = false,
  });

  factory JobCardDto.fromJson(Map<String, dynamic> json) {
    final specs = <String>[];
    final rawSpecs = json['specialties'];
    if (rawSpecs is List) {
      for (final s in rawSpecs) {
        if (s == null) continue;
        if (s is String && s.isNotEmpty) {
          specs.add(s);
        } else if (s is Map && s['name'] != null) {
          specs.add(s['name'].toString());
        }
      }
    }
    return JobCardDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['job_title']?.toString() ?? 'Untitled',
      companyName: json['companyName']?.toString() ?? json['company_name']?.toString(),
      location: json['location']?.toString(),
      experience: json['experience']?.toString(),
      specialty: json['specialty']?.toString(),
      specialties: specs,
      jobType: json['jobType']?.toString() ?? json['job_type']?.toString(),
      salaryRange: json['salaryRange']?.toString() ?? json['salary_range']?.toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString() ?? json['job_image']?.toString() ?? json['jobImage']?.toString(),
      lastDate: json['lastDate']?.toString() ?? json['last_date']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      country: json['country']?.toString(),
      promoted: json['promoted'] == true || json['promoted'] == 1,
      promotionTier: json['promotionTier']?.toString(),
      isFreeTier: json['isFreeTier'] == true,
      organization: json['organization'] is Map
          ? JobOrganizationDto.fromJson(Map<String, dynamic>.from(json['organization'] as Map))
          : null,
      posterUserId: json['posterUserId']?.toString() ?? json['user_id']?.toString(),
      stats: JobStatsDto.fromJson(
        json['stats'] is Map ? Map<String, dynamic>.from(json['stats'] as Map) : null,
      ),
      isApplied: json['isApplied'] == true,
      isBookmarked: json['isBookmarked'] == true,
      daysLeft: int.tryParse(json['daysLeft']?.toString() ?? ''),
      isExpired: json['isExpired'] == true,
    );
  }

  JobCardDto copyWith({bool? isBookmarked, bool? isApplied}) {
    return JobCardDto(
      id: id,
      title: title,
      companyName: companyName,
      location: location,
      experience: experience,
      specialty: specialty,
      specialties: specialties,
      jobType: jobType,
      salaryRange: salaryRange,
      description: description,
      image: image,
      lastDate: lastDate,
      createdAt: createdAt,
      country: country,
      promoted: promoted,
      promotionTier: promotionTier,
      isFreeTier: isFreeTier,
      organization: organization,
      posterUserId: posterUserId,
      stats: stats,
      isApplied: isApplied ?? this.isApplied,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      daysLeft: daysLeft,
      isExpired: isExpired,
    );
  }
}

class JobApplicationFieldDto {
  final String id;
  final String fieldKey;
  final String? label;
  final String type;
  final bool required;
  final List<String> options;
  final String? placeholder;
  final bool isCustom;

  const JobApplicationFieldDto({
    required this.id,
    required this.fieldKey,
    this.label,
    this.type = 'text',
    this.required = false,
    this.options = const [],
    this.placeholder,
    this.isCustom = false,
  });

  factory JobApplicationFieldDto.fromJson(Map<String, dynamic> json) {
    final opts = <String>[];
    final raw = json['options'];
    if (raw is List) {
      for (final o in raw) {
        if (o != null) opts.add(o.toString());
      }
    }
    return JobApplicationFieldDto(
      id: json['id']?.toString() ?? json['fieldKey']?.toString() ?? '',
      fieldKey: json['fieldKey']?.toString() ?? json['key']?.toString() ?? '',
      label: json['label']?.toString(),
      type: json['type']?.toString() ?? 'text',
      required: json['required'] == true || json['isRequired'] == true,
      options: opts,
      placeholder: json['placeholder']?.toString(),
      isCustom: json['isCustom'] == true,
    );
  }
}

class JobSavedCvDto {
  final String id;
  final String path;
  final String name;
  final String url;
  final bool isDefault;

  const JobSavedCvDto({
    required this.id,
    required this.path,
    required this.name,
    required this.url,
    this.isDefault = false,
  });

  factory JobSavedCvDto.fromJson(Map<String, dynamic> json) {
    return JobSavedCvDto(
      id: json['id']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      name: json['name']?.toString() ?? 'CV',
      url: json['url']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }
}

class JobDetailDto extends JobCardDto {
  final String? link;
  final String applyType;
  final int? totalJobs;
  final String? preferredLanguage;
  final List<JobApplicationFieldDto> applicationFields;
  final String? applicationId;
  final String? applicationStatus;
  final String? appliedAt;
  final double? aiMatchScore;
  final List<JobSavedCvDto> savedCvs;
  final bool isOwnerView;

  const JobDetailDto({
    required super.id,
    required super.title,
    super.companyName,
    super.location,
    super.experience,
    super.specialty,
    super.specialties,
    super.jobType,
    super.salaryRange,
    super.description,
    super.image,
    super.lastDate,
    super.createdAt,
    super.country,
    super.promoted,
    super.promotionTier,
    super.isFreeTier,
    super.organization,
    super.posterUserId,
    super.stats,
    super.isApplied,
    super.isBookmarked,
    super.daysLeft,
    super.isExpired,
    this.link,
    this.applyType = 'easy_apply',
    this.totalJobs,
    this.preferredLanguage,
    this.applicationFields = const [],
    this.applicationId,
    this.applicationStatus,
    this.appliedAt,
    this.aiMatchScore,
    this.savedCvs = const [],
    this.isOwnerView = false,
  });

  factory JobDetailDto.fromJson(Map<String, dynamic> json) {
    final base = JobCardDto.fromJson(json);
    final fields = <JobApplicationFieldDto>[];
    final rawFields = json['applicationFields'];
    if (rawFields is List) {
      for (final f in rawFields) {
        if (f is Map) {
          fields.add(JobApplicationFieldDto.fromJson(Map<String, dynamic>.from(f)));
        }
      }
    }
    final cvs = <JobSavedCvDto>[];
    final rawCvs = json['savedCvs'];
    if (rawCvs is List) {
      for (final c in rawCvs) {
        if (c is Map) {
          cvs.add(JobSavedCvDto.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    return JobDetailDto(
      id: base.id,
      title: base.title,
      companyName: base.companyName,
      location: base.location,
      experience: base.experience,
      specialty: base.specialty,
      specialties: base.specialties,
      jobType: base.jobType,
      salaryRange: base.salaryRange,
      description: base.description,
      image: base.image,
      lastDate: base.lastDate,
      createdAt: base.createdAt,
      country: base.country,
      promoted: base.promoted,
      promotionTier: base.promotionTier,
      isFreeTier: base.isFreeTier,
      organization: base.organization,
      posterUserId: base.posterUserId,
      stats: base.stats,
      isApplied: base.isApplied,
      isBookmarked: base.isBookmarked,
      daysLeft: base.daysLeft,
      isExpired: base.isExpired,
      link: json['link']?.toString(),
      applyType: json['applyType']?.toString() ?? 'easy_apply',
      totalJobs: int.tryParse(json['totalJobs']?.toString() ?? json['noOfJobs']?.toString() ?? ''),
      preferredLanguage: json['preferredLanguage']?.toString(),
      applicationFields: fields,
      applicationId: json['applicationId']?.toString(),
      applicationStatus: json['applicationStatus']?.toString(),
      appliedAt: json['appliedAt']?.toString(),
      aiMatchScore: double.tryParse(json['aiMatchScore']?.toString() ?? ''),
      savedCvs: cvs,
      isOwnerView: json['isOwnerView'] == true,
    );
  }

  bool get isExternalApply => applyType == 'external' && (link?.isNotEmpty ?? false);
}

class JobFacetsDto {
  final List<JobFacetItem> specialties;
  final List<JobFacetItem> locations;
  final List<JobFacetItem> jobTypes;
  final int total;

  const JobFacetsDto({
    this.specialties = const [],
    this.locations = const [],
    this.jobTypes = const [],
    this.total = 0,
  });

  factory JobFacetsDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const JobFacetsDto();
    List<JobFacetItem> parse(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => JobFacetItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return JobFacetsDto(
      specialties: parse(json['specialties']),
      locations: parse(json['locations']),
      jobTypes: parse(json['jobTypes']),
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
    );
  }
}

class JobFacetItem {
  final String name;
  final int count;

  const JobFacetItem({required this.name, this.count = 0});

  factory JobFacetItem.fromJson(Map<String, dynamic> json) {
    return JobFacetItem(
      name: json['name']?.toString() ?? '',
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
    );
  }
}

class JobListResult {
  final List<JobCardDto> items;
  final String? nextCursor;
  final JobFacetsDto facets;
  final int page;
  final int total;

  const JobListResult({
    required this.items,
    this.nextCursor,
    this.facets = const JobFacetsDto(),
    this.page = 1,
    this.total = 0,
  });
}

class JobCapabilitiesDto {
  final bool canPost;
  final String? userId;
  final String? orgId;
  final String? orgName;
  final String? orgType;
  final String? role;

  const JobCapabilitiesDto({
    this.canPost = false,
    this.userId,
    this.orgId,
    this.orgName,
    this.orgType,
    this.role,
  });

  factory JobCapabilitiesDto.fromJson(Map<String, dynamic> json) {
    final org = json['organization'];
    return JobCapabilitiesDto(
      canPost: json['canPost'] == true,
      userId: (json['user'] is Map) ? (json['user'] as Map)['id']?.toString() : null,
      orgId: org is Map ? org['id']?.toString() : null,
      orgName: org is Map ? org['name']?.toString() : null,
      orgType: org is Map ? org['type']?.toString() : null,
      role: json['role']?.toString(),
    );
  }
}

class JobApplicationDto {
  final String applicationId;
  final JobCardDto job;
  final String status;
  final String? appliedAt;
  final double? aiMatchScore;

  const JobApplicationDto({
    required this.applicationId,
    required this.job,
    required this.status,
    this.appliedAt,
    this.aiMatchScore,
  });

  factory JobApplicationDto.fromJson(Map<String, dynamic> json) {
    final jobJson = json['job'] is Map
        ? Map<String, dynamic>.from(json['job'] as Map)
        : <String, dynamic>{};
    return JobApplicationDto(
      applicationId: json['applicationId']?.toString() ?? '',
      job: JobCardDto.fromJson(jobJson),
      status: json['status']?.toString() ?? 'new',
      appliedAt: json['appliedAt']?.toString(),
      aiMatchScore: double.tryParse(json['aiMatchScore']?.toString() ?? ''),
    );
  }
}

class JobApplicantDto {
  final String applicationId;
  final String userId;
  final String name;
  final String? avatar;
  final String? specialty;
  final String? appliedAt;
  final String stage;
  final double? aiMatchScore;
  final String? cvUrl;
  final String? cvPreview;
  final List<MapEntry<String, String>> extraFieldEntries;

  const JobApplicantDto({
    required this.applicationId,
    required this.userId,
    required this.name,
    this.avatar,
    this.specialty,
    this.appliedAt,
    required this.stage,
    this.aiMatchScore,
    this.cvUrl,
    this.cvPreview,
    this.extraFieldEntries = const [],
  });

  factory JobApplicantDto.fromJson(Map<String, dynamic> json) {
    final entries = <MapEntry<String, String>>[];
    final raw = json['extraFieldEntries'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          final label = e['label']?.toString() ?? e['key']?.toString() ?? '';
          final formatted = formatExtraFieldValue(e['value']);
          if (label.trim().isEmpty && formatted.isEmpty) continue;
          entries.add(MapEntry(label, formatted));
        }
      }
    }
    final avatarRaw = json['avatar']?.toString();
    final avatarResolved = AppData.fullImageUrl(avatarRaw);
    final cvRaw = json['cvUrl']?.toString();
    final cvResolved = AppData.fullImageUrl(cvRaw);
    return JobApplicantDto(
      applicationId: json['applicationId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Applicant',
      avatar: avatarResolved.isEmpty ? null : avatarResolved,
      specialty: json['specialty']?.toString(),
      appliedAt: json['appliedAt']?.toString(),
      stage: json['stage']?.toString() ?? 'new',
      aiMatchScore: double.tryParse(json['aiMatchScore']?.toString() ?? ''),
      cvUrl: cvResolved.isEmpty ? null : cvResolved,
      cvPreview: json['cvPreview']?.toString(),
      extraFieldEntries: entries,
    );
  }

  /// Readable string for application answers (lists without `[...]` braces).
  static String formatExtraFieldValue(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num) return value.toString();
    if (value is List) {
      return value
          .map(formatExtraFieldValue)
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
    }
    if (value is Map) {
      if (value.containsKey('value')) {
        return formatExtraFieldValue(value['value']);
      }
      return value.entries
          .map((e) => '${e.key}: ${formatExtraFieldValue(e.value)}')
          .join(', ');
    }

    var text = value.toString().trim();
    if (text.startsWith('[') && text.endsWith(']')) {
      final inner = text.substring(1, text.length - 1).trim();
      if (inner.isEmpty) return '';
      if (!inner.contains('{') && !inner.contains('\n')) {
        return inner
            .split(',')
            .map((p) {
              var t = p.trim();
              if ((t.startsWith('"') && t.endsWith('"')) ||
                  (t.startsWith("'") && t.endsWith("'"))) {
                t = t.substring(1, t.length - 1);
              }
              return t;
            })
            .where((t) => t.isNotEmpty)
            .join(', ');
      }
    }
    return text;
  }
}

class JobApplicantsResult {
  final Map<String, List<JobApplicantDto>> stages;
  final JobStatsDto stats;
  final List<String> stageOrder;

  const JobApplicantsResult({
    required this.stages,
    this.stats = const JobStatsDto(),
    this.stageOrder = const [
      'new',
      'reviewed',
      'shortlisted',
      'interview',
      'offer',
      'accepted',
      'rejected',
    ],
  });

  factory JobApplicantsResult.fromJson(Map<String, dynamic> json) {
    final stages = <String, List<JobApplicantDto>>{};
    final raw = json['stages'];
    if (raw is Map) {
      raw.forEach((key, value) {
        final list = <JobApplicantDto>[];
        if (value is List) {
          for (final a in value) {
            if (a is Map) {
              list.add(JobApplicantDto.fromJson(Map<String, dynamic>.from(a)));
            }
          }
        }
        stages[key.toString()] = list;
      });
    }
    final order = <String>[];
    final rawOrder = json['stageOrder'];
    if (rawOrder is List) {
      for (final s in rawOrder) {
        order.add(s.toString());
      }
    }
    return JobApplicantsResult(
      stages: stages,
      stats: JobStatsDto.fromJson(
        json['stats'] is Map ? Map<String, dynamic>.from(json['stats'] as Map) : null,
      ),
      stageOrder: order.isEmpty
          ? const [
              'new',
              'reviewed',
              'shortlisted',
              'interview',
              'offer',
              'accepted',
              'rejected',
            ]
          : order,
    );
  }
}

class MyPostedJobsResult {
  final List<JobCardDto> items;
  final MyPostedJobsSummaryDto summary;

  const MyPostedJobsResult({required this.items, required this.summary});
}

class MyPostedJobsSummaryDto {
  final int totalJobsPosted;
  final int activeJobs;
  final int expiredJobs;
  final int totalApplicants;
  final int newApplicantsThisWeek;
  final int listingViews;

  const MyPostedJobsSummaryDto({
    this.totalJobsPosted = 0,
    this.activeJobs = 0,
    this.expiredJobs = 0,
    this.totalApplicants = 0,
    this.newApplicantsThisWeek = 0,
    this.listingViews = 0,
  });

  factory MyPostedJobsSummaryDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MyPostedJobsSummaryDto();
    int n(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    return MyPostedJobsSummaryDto(
      totalJobsPosted: n(json['totalJobsPosted']),
      activeJobs: n(json['activeJobs']),
      expiredJobs: n(json['expiredJobs']),
      totalApplicants: n(json['totalApplicants']),
      newApplicantsThisWeek: n(json['newApplicantsThisWeek']),
      listingViews: n(json['listingViews']),
    );
  }
}

/// AI-generated candidate-facing brief for a promoted job (Standard/Premium tier).
class JobAiBriefDto {
  final String shortDescription;
  final List<String> highlights;
  final List<String> suggestedQuestions;
  final String nextStep;
  final List<String> scopeBadges;

  const JobAiBriefDto({
    this.shortDescription = '',
    this.highlights = const [],
    this.suggestedQuestions = const [],
    this.nextStep = '',
    this.scopeBadges = const [],
  });

  factory JobAiBriefDto.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic raw) => raw is List
        ? raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : const [];
    return JobAiBriefDto(
      shortDescription: json['shortDescription']?.toString() ?? '',
      highlights: strList(json['highlights']),
      suggestedQuestions: strList(json['suggestedQuestions']),
      nextStep: json['nextStep']?.toString() ?? '',
      scopeBadges: strList(json['scopeBadges']),
    );
  }
}

/// AI candidate-fit preview ("Analyze My Fit" before applying).
class JobAiMatchDto {
  final int? matchScore;
  final String? matchLabel;
  final String? summary;
  final List<String> strengths;
  final List<String> gaps;
  final List<String> candidateActions;
  final String? cvLabel;

  const JobAiMatchDto({
    this.matchScore,
    this.matchLabel,
    this.summary,
    this.strengths = const [],
    this.gaps = const [],
    this.candidateActions = const [],
    this.cvLabel,
  });

  factory JobAiMatchDto.fromJson(Map<String, dynamic> json) {
    List<String> strList(dynamic raw) => raw is List
        ? raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : const [];
    return JobAiMatchDto(
      matchScore: int.tryParse(json['matchScore']?.toString() ?? ''),
      matchLabel: json['matchLabel']?.toString(),
      summary: json['summary']?.toString(),
      strengths: strList(json['strengths']),
      gaps: strList(json['gaps']),
      candidateActions: strList(json['candidateActions']),
      cvLabel: json['cvLabel']?.toString(),
    );
  }
}

/// A single AI-ranked applicant result (recruiter Premium feature).
class ApplicantAnalysisResultDto {
  final String applicationId;
  final int overallScore;
  final int skillMatchScore;
  final int experienceMatchScore;
  final int educationMatchScore;
  final int locationMatchScore;
  final String fitLabel;
  final List<String> strengths;
  final List<String> gaps;
  final String summary;
  final int rank;

  const ApplicantAnalysisResultDto({
    required this.applicationId,
    this.overallScore = 0,
    this.skillMatchScore = 0,
    this.experienceMatchScore = 0,
    this.educationMatchScore = 0,
    this.locationMatchScore = 0,
    this.fitLabel = 'Partial Fit',
    this.strengths = const [],
    this.gaps = const [],
    this.summary = '',
    this.rank = 0,
  });

  factory ApplicantAnalysisResultDto.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    List<String> strList(dynamic raw) => raw is List
        ? raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        : const [];
    return ApplicantAnalysisResultDto(
      applicationId: json['applicationId']?.toString() ?? '',
      overallScore: n(json['overallScore']),
      skillMatchScore: n(json['skillMatchScore']),
      experienceMatchScore: n(json['experienceMatchScore']),
      educationMatchScore: n(json['educationMatchScore']),
      locationMatchScore: n(json['locationMatchScore']),
      fitLabel: json['fitLabel']?.toString() ?? 'Partial Fit',
      strengths: strList(json['strengths']),
      gaps: strList(json['gaps']),
      summary: json['summary']?.toString() ?? '',
      rank: n(json['rank']),
    );
  }
}

/// Plan gate/policy info for AI applicant analysis.
class ApplicantAnalysisPolicyDto {
  final String currentPlan;
  final bool canAnalyze;
  final bool canRerun;
  final bool canViewDetailedBreakdown;
  final int? monthlyLimit;
  final int monthlyUsed;
  final int? monthlyRemaining;
  final String upgradeUrl;

  const ApplicantAnalysisPolicyDto({
    this.currentPlan = 'free',
    this.canAnalyze = false,
    this.canRerun = false,
    this.canViewDetailedBreakdown = false,
    this.monthlyLimit,
    this.monthlyUsed = 0,
    this.monthlyRemaining,
    this.upgradeUrl = '/pricing',
  });

  factory ApplicantAnalysisPolicyDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ApplicantAnalysisPolicyDto();
    return ApplicantAnalysisPolicyDto(
      currentPlan: json['currentPlan']?.toString() ?? 'free',
      canAnalyze: json['canAnalyze'] == true,
      canRerun: json['canRerun'] == true,
      canViewDetailedBreakdown: json['canViewDetailedBreakdown'] == true,
      monthlyLimit: int.tryParse(json['monthlyLimit']?.toString() ?? ''),
      monthlyUsed: int.tryParse(json['monthlyUsed']?.toString() ?? '') ?? 0,
      monthlyRemaining: int.tryParse(json['monthlyRemaining']?.toString() ?? ''),
      upgradeUrl: json['upgradeUrl']?.toString() ?? '/pricing',
    );
  }
}

/// Current AI applicant-ranking state for a job (results + plan policy).
class ApplicantAnalysisStateDto {
  final String? lastAnalyzedAt;
  final ApplicantAnalysisPolicyDto policy;
  final List<ApplicantAnalysisResultDto> results;

  const ApplicantAnalysisStateDto({
    this.lastAnalyzedAt,
    this.policy = const ApplicantAnalysisPolicyDto(),
    this.results = const [],
  });

  factory ApplicantAnalysisStateDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final results = <ApplicantAnalysisResultDto>[];
    if (rawResults is List) {
      for (final r in rawResults) {
        if (r is Map) {
          results.add(ApplicantAnalysisResultDto.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }
    return ApplicantAnalysisStateDto(
      lastAnalyzedAt: json['lastAnalyzedAt']?.toString(),
      policy: ApplicantAnalysisPolicyDto.fromJson(
        json['policy'] is Map ? Map<String, dynamic>.from(json['policy'] as Map) : null,
      ),
      results: results,
    );
  }
}

/// Recruiter job analytics (requires a paid promotion tier).
class JobAnalyticsFunnelDto {
  final int impressions;
  final int uniqueVisitors;
  final int applyClicks;
  final int applications;
  final int shortlisted;
  final int rejected;
  final int hired;
  final double completionRate;

  const JobAnalyticsFunnelDto({
    this.impressions = 0,
    this.uniqueVisitors = 0,
    this.applyClicks = 0,
    this.applications = 0,
    this.shortlisted = 0,
    this.rejected = 0,
    this.hired = 0,
    this.completionRate = 0,
  });

  factory JobAnalyticsFunnelDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const JobAnalyticsFunnelDto();
    int n(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    return JobAnalyticsFunnelDto(
      impressions: n(json['impressions']),
      uniqueVisitors: n(json['uniqueVisitors']),
      applyClicks: n(json['applyClicks']),
      applications: n(json['applications']),
      shortlisted: n(json['shortlisted']),
      rejected: n(json['rejected']),
      hired: n(json['hired']),
      completionRate: double.tryParse(json['completionRate']?.toString() ?? '') ?? 0,
    );
  }
}

class JobAnalyticsSeriesPointDto {
  final String date;
  final int views;
  final int clicks;
  final int applications;

  const JobAnalyticsSeriesPointDto({
    required this.date,
    this.views = 0,
    this.clicks = 0,
    this.applications = 0,
  });

  factory JobAnalyticsSeriesPointDto.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    return JobAnalyticsSeriesPointDto(
      date: json['date']?.toString() ?? '',
      views: n(json['views']),
      clicks: n(json['clicks']),
      applications: n(json['applications']),
    );
  }
}

class JobAnalyticsDto {
  final JobAnalyticsFunnelDto funnel;
  final JobStatsDto stats;
  final List<JobAnalyticsSeriesPointDto> timeSeries;

  const JobAnalyticsDto({
    this.funnel = const JobAnalyticsFunnelDto(),
    this.stats = const JobStatsDto(),
    this.timeSeries = const [],
  });

  factory JobAnalyticsDto.fromJson(Map<String, dynamic> json) {
    final series = <JobAnalyticsSeriesPointDto>[];
    final raw = json['timeSeries'];
    if (raw is List) {
      for (final p in raw) {
        if (p is Map) {
          series.add(JobAnalyticsSeriesPointDto.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }
    return JobAnalyticsDto(
      funnel: JobAnalyticsFunnelDto.fromJson(
        json['funnel'] is Map ? Map<String, dynamic>.from(json['funnel'] as Map) : null,
      ),
      stats: JobStatsDto.fromJson(
        json['stats'] is Map ? Map<String, dynamic>.from(json['stats'] as Map) : null,
      ),
      timeSeries: series,
    );
  }
}

/// Canonical stage labels for mobile stage tabs.
class JobStageLabels {
  static const List<String> order = [
    'new',
    'reviewed',
    'shortlisted',
    'interview',
    'offer',
    'accepted',
    'rejected',
  ];

  /// Active pipeline (excludes rejected) — used for progress dots.
  static const List<String> pipeline = [
    'new',
    'reviewed',
    'shortlisted',
    'interview',
    'offer',
    'accepted',
  ];

  static const Map<String, String> labels = {
    'new': 'New',
    'reviewed': 'Reviewed',
    'shortlisted': 'Shortlisted',
    'interview': 'Interview',
    'offer': 'Offer',
    'accepted': 'Hired',
    'rejected': 'Rejected',
  };

  static const Map<String, String> shortLabels = {
    'new': 'New',
    'reviewed': 'Review',
    'shortlisted': 'Short',
    'interview': 'Interview',
    'offer': 'Offer',
    'accepted': 'Hired',
    'rejected': 'Rejected',
  };

  static String label(String stage) => labels[stage] ?? stage;

  static String shortLabel(String stage) => shortLabels[stage] ?? stage;

  static int indexOf(String stage) {
    final i = order.indexOf(stage);
    return i < 0 ? 0 : i;
  }
}
