import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';

CmeEventsResponse cmeEventsResponseFromJson(String str) =>
    CmeEventsResponse.fromJson(json.decode(str));

class CmeEventsResponse {
  CmeEventsResponse({this.events});

  CmeEventsResponse.fromJson(dynamic json) {
    events = json['events'] != null
        ? CmePaginatedEvents.fromJson(json['events'])
        : null;
  }

  CmePaginatedEvents? events;
}

class CmePaginatedEvents {
  CmePaginatedEvents({
    this.currentPage,
    this.data,
    this.lastPage,
    this.nextPageUrl,
    this.perPage,
    this.total,
  });

  CmePaginatedEvents.fromJson(dynamic json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(CmeEventData.fromJson(v));
      });
    }
    lastPage = json['last_page'];
    nextPageUrl = json['next_page_url'];
    perPage = json['per_page'];
    total = json['total'];
  }

  int? currentPage;
  List<CmeEventData>? data;
  int? lastPage;
  dynamic nextPageUrl;
  int? perPage;
  int? total;
}

class CmeEventData {
  CmeEventData({
    this.id,
    this.uuid,
    this.title,
    this.description,
    this.shortDescription,
    this.type,
    this.format,
    this.status,
    this.startDate,
    this.endDate,
    this.timezone,
    this.location,
    this.venue,
    this.city,
    this.state,
    this.country,
    this.maxParticipants,
    this.currentParticipants,
    this.creditType,
    this.creditAmount,
    this.accreditationBody,
    this.accreditationNumber,
    this.specialties,
    this.targetAudience,
    this.thumbnail,
    this.bannerImage,
    this.registrationFee,
    this.earlyBirdFee,
    this.registrationDeadline,
    this.isFeatured,
    this.isPublished,
    this.meetingLink,
    this.agoraChannel,
    this.learningObjectives,
    this.organizer,
    this.speakers,
    this.modules,
    this.tags,
    this.registrationStatus,
    this.isRegistered,
    this.isAttending,
    this.isHost,
    this.canManage,
    this.myProgressPercent,
    this.myFeedbackSubmitted,
    this.myCertificateId,
    this.attendancePercentage,
    this.learnerProgress,
    this.capabilities,
    this.liveMeetingCode,
    this.segmentsCount,
    this.speakersCount,
    this.createdAt,
    this.updatedAt,
  });

  CmeEventData.fromJson(dynamic json) {
    id = json['id'];
    uuid = json['uuid'];
    title = json['title'];
    description = json['description'];
    shortDescription = json['short_description'];
    type = json['type'];
    format = json['format'];
    status = json['status'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    timezone = json['timezone'];
    location = json['location'];
    venue = json['venue'];
    city = json['city'];
    state = json['state'];
    country = json['country'];
    maxParticipants = json['max_participants'];
    currentParticipants = json['current_participants'];
    creditType = json['credit_type'];
    creditAmount = json['credit_amount'];
    accreditationBody = json['accreditation_body'];
    accreditationNumber = json['accreditation_number'];
    specialties = json['specialties'];
    targetAudience = json['target_audience'];
    thumbnail = _fixStorageUrl(json['thumbnail']);
    bannerImage = _fixStorageUrl(json['banner_image']);
    registrationFee = json['registration_fee'];
    earlyBirdFee = json['early_bird_fee'];
    registrationDeadline = json['registration_deadline'];
    isFeatured = json['is_featured'];
    isPublished = json['is_published'];
    meetingLink = json['meeting_link'];
    agoraChannel = json['agora_channel'];
    learningObjectives = json['learning_objectives'];
    if (json['organizer'] != null) {
      organizer = CmeOrganizer.fromJson(json['organizer']);
    }
    if (json['speakers'] != null) {
      speakers = [];
      json['speakers'].forEach((v) {
        speakers?.add(CmeSpeaker.fromJson(v));
      });
    }
    if (json['modules'] != null) {
      modules = [];
      json['modules'].forEach((v) {
        modules?.add(CmeModule.fromJson(v));
      });
    }
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        tags = List<String>.from(json['tags']);
      } else if (json['tags'] is String) {
        tags = [json['tags']];
      }
    }
    registrationStatus = json['registration_status'];
    isRegistered = json['is_registered'];
    isAttending = json['is_attending'];
    isHost = json['is_host'];
    myProgressPercent = json['user_progress'] ?? json['my_progress_percent'];
    attendancePercentage = _asNum(json['attendance_percentage']);
    createdAt = json['created_at'];
    updatedAt = json['updated_at'] ?? json['updatedAt'];
    _applyRegistrationFields(json);
  }

  void _applyRegistrationFields(dynamic json) {
    final status = registrationStatus?.toString();
    if (status != null && status.isNotEmpty) {
      isRegistered = status != 'cancelled' &&
          (status == 'registered' || status == 'attended' || status == 'waitlist');
      isAttending = status == 'attended';
    }
    myProgressPercent ??= attendancePercentage ?? json['user_progress'] ?? json['my_progress_percent'];
    if (myProgressPercent == null && attendancePercentage != null) {
      myProgressPercent = attendancePercentage;
    }
  }

  /// Node `/api/cme/events` DTO (camelCase) — web parity.
  factory CmeEventData.fromNodeJson(Map<String, dynamic> json) {
    final event = CmeEventData();
    event.id = json['id']?.toString();
    event.title = json['title'] as String?;
    event.description = json['description'] as String?;
    event.shortDescription = json['shortDescription'] as String?;
    event.type = json['eventType'] as String? ?? json['type'] as String?;
    event.format = json['format'] as String?;
    event.status = json['status'] as String?;
    event.startDate = json['startDate'] as String? ?? json['start_date'] as String?;
    event.endDate = json['endDate'] as String? ?? json['end_date'] as String?;
    event.timezone = json['timezone'] as String?;
    event.location = json['location'] as String?;
    event.venue = json['venueDetails'] as String? ?? json['venue'] as String?;
    event.maxParticipants = json['maxCapacity'] ?? json['max_participants'];
    event.currentParticipants = json['registrationsCount'] ?? json['current_participants'];
    event.creditAmount = json['credits'] ?? json['credit_amount'];
    event.creditType = json['creditType'] as String? ?? json['credit_type'] as String?;
    event.accreditationBody =
        json['accreditationBody'] as String? ?? json['accreditation_body'] as String?;
    final cover = json['coverImage'] ?? json['thumbnail'] ?? json['banner_image'];
    event.thumbnail = _fixStorageUrl(cover);
    event.bannerImage = event.thumbnail;
    event.meetingLink = json['meetingLink'] as String? ?? json['meeting_link'] as String?;
    event.registrationStatus = json['myRegistrationStatus'] as String? ?? json['registration_status'] as String?;
    event.isRegistered = event.registrationStatus == 'registered' || event.registrationStatus == 'attended';
    event.isAttending = event.registrationStatus == 'attended';
    event.isHost = json['canManage'] == true || json['is_host'] == true;
    event.canManage = json['canManage'] == true;
    event.myProgressPercent = json['myProgressPercent'] ?? json['my_progress_percent'];
    event.myFeedbackSubmitted = json['myFeedbackSubmitted'] == true;
    event.myCertificateId = json['myCertificateId'] as String?;
    event.attendancePercentage = _asNum(json['attendancePercentage'] ?? json['attendance_percentage']);
    if (event.myProgressPercent == null && event.attendancePercentage != null) {
      event.myProgressPercent = event.attendancePercentage;
    }
    event.segmentsCount = _asInt(json['segmentsCount']);
    event.speakersCount = _asInt(json['speakersCount']);
    event.liveMeetingCode = json['liveMeetingCode'] as String?;
    event.learningObjectives = json['learningObjectives'] as String? ?? event.learningObjectives;
    final progress = json['myLearnerProgress'] as Map<String, dynamic>?;
    if (progress != null) {
      event.learnerProgress = CmeLearnerProgress.fromJson(progress);
    }
    final caps = json['capabilities'] as Map<String, dynamic>?;
    if (caps != null) {
      event.capabilities = CmeEventCapabilities.fromJson(caps);
      event.canManage = event.canManage == true || event.capabilities!.canManage;
      event.isHost = event.isHost == true || event.capabilities!.canManage;
    }
    event.createdAt = json['createdAt'] as String? ?? json['created_at'] as String?;
    event.updatedAt = json['updatedAt'] as String? ?? json['updated_at'] as String?;
    final org = json['organization'] as Map<String, dynamic>?;
    if (org != null) {
      event.organizer = CmeOrganizer(
        id: org['id']?.toString(),
        name: org['name'] as String?,
        profilePic: _fixStorageUrl(org['logoUrl'] ?? org['logo']),
      );
    }
    final faculty = json['facultyPreview'] as List<dynamic>?;
    if (faculty != null && faculty.isNotEmpty) {
      event.speakers = faculty
          .map((u) => CmeSpeaker.fromJson(u is Map<String, dynamic> ? u : {'user': u}))
          .toList();
    }
    event._applyRegistrationFields(json);
    return event;
  }

  /// Full detail from Node `GET /api/cme/events/:id`.
  factory CmeEventData.fromNodeDetailJson(Map<String, dynamic> json) {
    return CmeEventData.fromNodeJson(json);
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static num? _asNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString());
  }

  /// Rewrites server-relative storage URLs to use the app's actual base URL.
  /// The API returns `asset('storage/...')` which uses APP_URL (often
  /// http://localhost), but the Flutter app connects to a different host
  /// (e.g. 10.0.2.2 for emulator or doctak.net for prod).
  static String? _fixStorageUrl(dynamic url) {
    if (url == null || url.toString().isEmpty) return null;
    final str = url.toString().trim();
    if (str.startsWith('/profile-media/') ||
        str.startsWith('profile-media/') ||
        str.startsWith('/legacy-media/') ||
        str.startsWith('legacy-media/') ||
        str.startsWith('/r2-media/') ||
        str.startsWith('r2-media/')) {
      final resolved = AppData.fullImageUrl(str);
      return resolved.isEmpty ? null : resolved;
    }
    // Already a valid non-localhost URL — keep as-is
    if (str.startsWith('https://')) return str;
    if (str.startsWith('http://')) {
      final resolved = AppData.fullImageUrl(str);
      return resolved.isEmpty ? str : resolved;
    }
    // Extract path after '/storage/' and reconstruct with app base URL
    final storageIdx = str.indexOf('/storage/');
    if (storageIdx != -1) {
      final relativePath = str.substring(storageIdx + 1);
      return '${AppData.base}$relativePath';
    }
    // Relative path without /storage/ prefix — assume it's a storage path
    if (!str.startsWith('http')) {
      return '${AppData.base}storage/$str';
    }
    return str;
  }

  String? id;
  String? uuid;
  String? title;
  String? description;
  String? shortDescription;
  String? type;
  String? format;
  String? status;
  String? startDate;
  String? endDate;
  String? timezone;
  String? location;
  String? venue;
  String? city;
  String? state;
  String? country;
  int? maxParticipants;
  int? currentParticipants;
  String? creditType;
  dynamic creditAmount;
  String? accreditationBody;
  String? accreditationNumber;
  dynamic specialties;
  String? targetAudience;
  String? thumbnail;
  String? bannerImage;
  dynamic registrationFee;
  dynamic earlyBirdFee;
  String? registrationDeadline;
  dynamic isFeatured;
  dynamic isPublished;
  String? meetingLink;
  String? agoraChannel;
  String? learningObjectives;
  CmeOrganizer? organizer;
  List<CmeSpeaker>? speakers;
  List<CmeModule>? modules;
  List<String>? tags;
  String? registrationStatus;
  dynamic isRegistered;
  dynamic isAttending;
  dynamic isHost;
  bool? canManage;
  dynamic myProgressPercent;
  bool? myFeedbackSubmitted;
  String? myCertificateId;
  num? attendancePercentage;
  CmeLearnerProgress? learnerProgress;
  CmeEventCapabilities? capabilities;
  String? liveMeetingCode;
  int? segmentsCount;
  int? speakersCount;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['uuid'] = uuid;
    map['title'] = title;
    map['description'] = description;
    map['short_description'] = shortDescription;
    map['type'] = type;
    map['format'] = format;
    map['status'] = status;
    map['start_date'] = startDate;
    map['end_date'] = endDate;
    map['timezone'] = timezone;
    map['location'] = location;
    map['venue'] = venue;
    map['city'] = city;
    map['state'] = state;
    map['country'] = country;
    map['max_participants'] = maxParticipants;
    map['current_participants'] = currentParticipants;
    map['credit_type'] = creditType;
    map['credit_amount'] = creditAmount;
    map['accreditation_body'] = accreditationBody;
    map['accreditation_number'] = accreditationNumber;
    map['specialties'] = specialties;
    map['target_audience'] = targetAudience;
    map['thumbnail'] = thumbnail;
    map['banner_image'] = bannerImage;
    map['registration_fee'] = registrationFee;
    map['early_bird_fee'] = earlyBirdFee;
    map['registration_deadline'] = registrationDeadline;
    map['is_featured'] = isFeatured;
    map['is_published'] = isPublished;
    map['meeting_link'] = meetingLink;
    map['agora_channel'] = agoraChannel;
    map['learning_objectives'] = learningObjectives;
    if (organizer != null) {
      map['organizer'] = organizer?.toJson();
    }
    if (speakers != null) {
      map['speakers'] = speakers?.map((v) => v.toJson()).toList();
    }
    if (modules != null) {
      map['modules'] = modules?.map((v) => v.toJson()).toList();
    }
    map['tags'] = tags;
    map['registration_status'] = registrationStatus;
    map['is_registered'] = isRegistered;
    map['is_attending'] = isAttending;
    map['is_host'] = isHost;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }

  bool get isFull =>
      maxParticipants != null &&
      currentParticipants != null &&
      currentParticipants! >= maxParticipants!;

  /// Parse start/end dates for time-based checks (matching web behaviour).
  DateTime? get _parsedStart => startDate != null ? DateTime.tryParse(startDate!) : null;
  DateTime? get _parsedEnd => endDate != null ? DateTime.tryParse(endDate!) : null;

  /// True when the event is currently within its scheduled time window
  /// (start_date <= now <= end_date) AND is published/live.
  /// Matches the web's `$isSessionTime = now()->between(start, end)`.
  bool get isSessionTime {
    final start = _parsedStart;
    final end = _parsedEnd;
    if (start == null || end == null) return false;
    final now = DateTime.now().toUtc();
    return now.isAfter(start) && now.isBefore(end);
  }

  /// Whether the event is before its session time.
  bool get isBeforeSession {
    final start = _parsedStart;
    if (start == null) return false;
    return DateTime.now().toUtc().isBefore(start);
  }

  /// Whether the event is after its session time.
  bool get isAfterSession {
    final end = _parsedEnd;
    if (end == null) return false;
    return DateTime.now().toUtc().isAfter(end);
  }

  /// Whether this is a live/virtual/hybrid event (website uses event_type + format).
  bool get isVirtualType =>
      type == 'live' || type == 'virtual' || type == 'hybrid' ||
      format == 'virtual' || format == 'hybrid';

  /// UI status aligned with website time-window logic (not raw DB status alone).
  String? get displayStatus {
    if (isCancelled) return 'cancelled';
    if (isLive) return 'live';
    if (isCompleted) return 'completed';
    if (isBeforeSession) return 'upcoming';
    switch (status?.toLowerCase()) {
      case 'published':
      case 'upcoming':
        return 'upcoming';
      case 'completed':
      case 'ended':
        return 'completed';
      case 'live':
      case 'in_progress':
        return 'live';
      case 'cancelled':
        return 'cancelled';
      default:
        return status;
    }
  }

  bool get isUpcoming =>
      displayStatus == 'upcoming';

  /// True if event is live now — time-based check (web parity) OR status-based fallback.
  bool get isLive =>
      status == 'live' || status == 'in_progress' ||
      (isSessionTime && (status == 'published' || status == 'upcoming'));

  bool get isCompleted =>
      status == 'completed' || status == 'ended' ||
      (isAfterSession && status != 'cancelled');

  bool get isCancelled => status == 'cancelled';

  String get displayCredits {
    if (creditAmount == null) return '';
    return '${creditAmount} ${creditType ?? 'CME'} Credits';
  }

  bool get showLearnerProgress =>
      capabilities?.showLearnerProgress ??
      ((isRegistered == true || registrationStatus != null) && canManage != true);

  bool get hasLearnerQuiz => learnerProgress?.hasQuiz ?? false;

  ({String moduleId, String quizId, String? title})? get primaryQuizTarget {
    for (final module in modules ?? const <CmeModule>[]) {
      final quiz = module.quiz;
      if (module.id != null && quiz?.id != null) {
        return (moduleId: module.id!, quizId: quiz!.id!, title: quiz.title);
      }
    }
    return null;
  }
}

class CmeLearnerProgress {
  CmeLearnerProgress({
    this.hasQuiz = false,
    this.quizPassed = false,
    this.quizPendingReview = false,
    this.feedbackSubmitted = false,
    this.quizAttemptsUsed = 0,
    this.quizAttemptsMax = 0,
    this.certificateId,
  });

  factory CmeLearnerProgress.fromJson(Map<String, dynamic> json) {
    return CmeLearnerProgress(
      hasQuiz: json['hasQuiz'] == true,
      quizPassed: json['quizPassed'] == true,
      quizPendingReview: json['quizPendingReview'] == true,
      feedbackSubmitted: json['feedbackSubmitted'] == true,
      quizAttemptsUsed: CmeEventData._asInt(json['quizAttemptsUsed']) ?? 0,
      quizAttemptsMax: CmeEventData._asInt(json['quizAttemptsMax']) ?? 0,
      certificateId: json['certificateId']?.toString(),
    );
  }

  final bool hasQuiz;
  final bool quizPassed;
  final bool quizPendingReview;
  final bool feedbackSubmitted;
  final int quizAttemptsUsed;
  final int quizAttemptsMax;
  final String? certificateId;
}

class CmeEventCapabilities {
  CmeEventCapabilities({
    this.canManage = false,
    this.canPresent = false,
    this.canRegister = false,
    this.registrationFull = false,
    this.canJoinLive = false,
    this.canStartLive = false,
    this.canEndLiveSession = false,
    this.liveSessionEnded = false,
    this.canSubmitQuiz = false,
    this.canLeaveFeedback = false,
    this.canViewCertificate = false,
    this.showLearnerProgress = false,
  });

  factory CmeEventCapabilities.fromJson(Map<String, dynamic> json) {
    return CmeEventCapabilities(
      canManage: json['canManage'] == true,
      canPresent: json['canPresent'] == true,
      canRegister: json['canRegister'] == true,
      registrationFull: json['registrationFull'] == true,
      canJoinLive: json['canJoinLive'] == true,
      canStartLive: json['canStartLive'] == true,
      canEndLiveSession: json['canEndLiveSession'] == true,
      liveSessionEnded: json['liveSessionEnded'] == true,
      canSubmitQuiz: json['canSubmitQuiz'] == true,
      canLeaveFeedback: json['canLeaveFeedback'] == true,
      canViewCertificate: json['canViewCertificate'] == true,
      showLearnerProgress: json['showLearnerProgress'] == true,
    );
  }

  final bool canManage;
  final bool canPresent;
  final bool canRegister;
  final bool registrationFull;
  final bool canJoinLive;
  final bool canStartLive;
  final bool canEndLiveSession;
  final bool liveSessionEnded;
  final bool canSubmitQuiz;
  final bool canLeaveFeedback;
  final bool canViewCertificate;
  final bool showLearnerProgress;
}

class CmeSegment {
  CmeSegment({
    this.id,
    this.title,
    this.description,
    this.sequenceOrder,
    this.durationMinutes,
    this.moduleType,
    this.hasQuiz,
  });

  factory CmeSegment.fromJson(Map<String, dynamic> json) {
    return CmeSegment(
      id: json['id']?.toString(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      sequenceOrder: CmeEventData._asInt(json['sequenceOrder']),
      durationMinutes: CmeEventData._asInt(json['durationMinutes']),
      moduleType: json['moduleType'] as String?,
      hasQuiz: json['hasQuiz'] == true,
    );
  }

  final String? id;
  final String? title;
  final String? description;
  final int? sequenceOrder;
  final int? durationMinutes;
  final String? moduleType;
  final bool? hasQuiz;
}

class CmeOrganizer {
  CmeOrganizer({this.id, this.name, this.profilePic, this.specialty});

  CmeOrganizer.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    final pic = json['profile_pic'] ?? json['avatar'] ?? json['logoUrl'] ?? json['logo'];
    profilePic = CmeEventData._fixStorageUrl(pic);
    specialty = json['specialty']?.toString();
  }

  String? id;
  String? name;
  String? profilePic;
  String? specialty;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    map['specialty'] = specialty;
    return map;
  }
}

class CmeSpeaker {
  CmeSpeaker({
    this.id,
    this.name,
    this.title,
    this.bio,
    this.profilePic,
    this.specialty,
  });

  CmeSpeaker.fromJson(dynamic json) {
    final user = json['user'] as Map<String, dynamic>?;
    id = json['id'] ?? user?['id'];
    name = json['name'] ?? user?['name'];
    title = json['title'] ?? json['speaker_role'];
    bio = json['bio'] ?? json['speaker_bio'];
    final pic = json['profile_pic'] ??
        json['avatar'] ??
        user?['avatar'] ??
        user?['profile_pic'];
    profilePic = CmeEventData._fixStorageUrl(pic);
    specialty = json['specialty']?.toString() ?? user?['specialty']?.toString();
  }

  String? id;
  String? name;
  String? title;
  String? bio;
  String? profilePic;
  String? specialty;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['title'] = title;
    map['bio'] = bio;
    map['profile_pic'] = profilePic;
    map['specialty'] = specialty;
    return map;
  }
}

class CmeModule {
  CmeModule({
    this.id,
    this.title,
    this.description,
    this.type,
    this.duration,
    this.sortOrder,
    this.isRequired,
    this.isActive,
    this.quiz,
    this.materials,
  });

  CmeModule.fromJson(dynamic json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    type = json['type'];
    duration = json['duration'];
    sortOrder = json['sort_order'];
    isRequired = json['is_required'];
    isActive = json['is_active'];
    if (json['quiz'] != null) {
      quiz = CmeQuizSummary.fromJson(json['quiz']);
    }
    if (json['materials'] != null) {
      materials = [];
      json['materials'].forEach((v) {
        materials?.add(CmeMaterial.fromJson(v));
      });
    }
  }

  String? id;
  String? title;
  String? description;
  String? type;
  int? duration;
  int? sortOrder;
  dynamic isRequired;
  bool? isActive;
  CmeQuizSummary? quiz;
  List<CmeMaterial>? materials;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['title'] = title;
    map['description'] = description;
    map['type'] = type;
    map['duration'] = duration;
    map['sort_order'] = sortOrder;
    map['is_required'] = isRequired;
    map['is_active'] = isActive;
    if (quiz != null) map['quiz'] = quiz?.toJson();
    if (materials != null) {
      map['materials'] = materials?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class CmeQuizSummary {
  CmeQuizSummary({
    this.id,
    this.title,
    this.totalQuestions,
    this.passingScore,
    this.timeLimit,
    this.maxAttempts,
  });

  CmeQuizSummary.fromJson(dynamic json) {
    id = json['id'];
    title = json['title'];
    totalQuestions = json['total_questions'];
    passingScore = json['passing_score'];
    timeLimit = json['time_limit'];
    maxAttempts = json['max_attempts'];
  }

  String? id;
  String? title;
  int? totalQuestions;
  int? passingScore;
  int? timeLimit;
  int? maxAttempts;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['title'] = title;
    map['total_questions'] = totalQuestions;
    map['passing_score'] = passingScore;
    map['time_limit'] = timeLimit;
    map['max_attempts'] = maxAttempts;
    return map;
  }
}

class CmeMaterial {
  CmeMaterial({this.id, this.title, this.type, this.url, this.size});

  CmeMaterial.fromJson(dynamic json) {
    id = json['id'];
    title = json['title'];
    type = json['type'];
    url = json['url'];
    size = json['size'];
  }

  String? id;
  String? title;
  String? type;
  String? url;
  dynamic size;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['title'] = title;
    map['type'] = type;
    map['url'] = url;
    map['size'] = size;
    return map;
  }
}
