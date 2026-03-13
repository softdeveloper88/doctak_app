import 'dart:convert';

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
    this.organizer,
    this.speakers,
    this.modules,
    this.tags,
    this.registrationStatus,
    this.isRegistered,
    this.isAttending,
    this.isHost,
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
    thumbnail = json['thumbnail'];
    bannerImage = json['banner_image'];
    registrationFee = json['registration_fee'];
    earlyBirdFee = json['early_bird_fee'];
    registrationDeadline = json['registration_deadline'];
    isFeatured = json['is_featured'];
    isPublished = json['is_published'];
    meetingLink = json['meeting_link'];
    agoraChannel = json['agora_channel'];
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
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
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
  CmeOrganizer? organizer;
  List<CmeSpeaker>? speakers;
  List<CmeModule>? modules;
  List<String>? tags;
  String? registrationStatus;
  dynamic isRegistered;
  dynamic isAttending;
  dynamic isHost;
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

  bool get isUpcoming => status == 'upcoming' || status == 'published';
  bool get isLive => status == 'live' || status == 'in_progress';
  bool get isCompleted => status == 'completed' || status == 'ended';
  bool get isCancelled => status == 'cancelled';

  String get displayCredits {
    if (creditAmount == null) return '';
    return '${creditAmount} ${creditType ?? 'CME'} Credits';
  }
}

class CmeOrganizer {
  CmeOrganizer({this.id, this.name, this.profilePic, this.specialty});

  CmeOrganizer.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    profilePic = json['profile_pic'];
    specialty = json['specialty'];
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
    id = json['id'];
    name = json['name'];
    title = json['title'];
    bio = json['bio'];
    profilePic = json['profile_pic'];
    specialty = json['specialty'];
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
