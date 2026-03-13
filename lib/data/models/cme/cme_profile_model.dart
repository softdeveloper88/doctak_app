class CmeProfileData {
  final int? totalCredits;
  final int? creditsThisYear;
  final int? creditsThisCycle;
  final int? requiredCredits;
  final int? eventsAttended;
  final int? certificatesEarned;
  final int? learningPathsCompleted;
  final String? cycleStartDate;
  final String? cycleEndDate;
  final List<CmeProfileCredit>? creditHistory;

  CmeProfileData({
    this.totalCredits,
    this.creditsThisYear,
    this.creditsThisCycle,
    this.requiredCredits,
    this.eventsAttended,
    this.certificatesEarned,
    this.learningPathsCompleted,
    this.cycleStartDate,
    this.cycleEndDate,
    this.creditHistory,
  });

  factory CmeProfileData.fromJson(Map<String, dynamic> json) {
    return CmeProfileData(
      totalCredits: json['total_credits'],
      creditsThisYear: json['credits_this_year'],
      creditsThisCycle: json['credits_this_cycle'],
      requiredCredits: json['required_credits'],
      eventsAttended: json['events_attended'],
      certificatesEarned: json['certificates_earned'],
      learningPathsCompleted: json['learning_paths_completed'],
      cycleStartDate: json['cycle_start_date'],
      cycleEndDate: json['cycle_end_date'],
      creditHistory: json['credit_history'] != null
          ? (json['credit_history'] as List)
              .map((c) => CmeProfileCredit.fromJson(c))
              .toList()
          : null,
    );
  }

  double get cycleProgress {
    if (requiredCredits == null || requiredCredits == 0) return 0;
    return ((creditsThisCycle ?? 0) / requiredCredits!).clamp(0.0, 1.0);
  }
}

class CmeProfileCredit {
  final String? id;
  final String? eventTitle;
  final String? creditType;
  final int? credits;
  final String? earnedDate;
  final String? accreditationBody;
  final String? status;

  CmeProfileCredit({
    this.id,
    this.eventTitle,
    this.creditType,
    this.credits,
    this.earnedDate,
    this.accreditationBody,
    this.status,
  });

  factory CmeProfileCredit.fromJson(Map<String, dynamic> json) {
    return CmeProfileCredit(
      id: json['id'],
      eventTitle: json['event_title'],
      creditType: json['credit_type'],
      credits: json['credits'],
      earnedDate: json['earned_date'],
      accreditationBody: json['accreditation_body'],
      status: json['status'],
    );
  }

  bool get isApproved => status == 'approved' || status == null;
  String get displayStatus {
    if (status == null) return 'Approved';
    return status![0].toUpperCase() + status!.substring(1);
  }
}

class CmeTranscriptData {
  final String? userName;
  final String? specialty;
  final String? licenseNumber;
  final int? totalCredits;
  final String? cycleStart;
  final String? cycleEnd;
  final List<CmeTranscriptEntry>? entries;
  final String? downloadUrl;

  CmeTranscriptData({
    this.userName,
    this.specialty,
    this.licenseNumber,
    this.totalCredits,
    this.cycleStart,
    this.cycleEnd,
    this.entries,
    this.downloadUrl,
  });

  factory CmeTranscriptData.fromJson(Map<String, dynamic> json) {
    return CmeTranscriptData(
      userName: json['user_name'],
      specialty: json['specialty'],
      licenseNumber: json['license_number'],
      totalCredits: json['total_credits'],
      cycleStart: json['cycle_start'],
      cycleEnd: json['cycle_end'],
      entries: json['entries'] != null
          ? (json['entries'] as List)
              .map((e) => CmeTranscriptEntry.fromJson(e))
              .toList()
          : null,
      downloadUrl: json['download_url'],
    );
  }
}

class CmeTranscriptEntry {
  final String? eventTitle;
  final String? eventType;
  final String? creditType;
  final int? credits;
  final String? completedDate;
  final String? accreditationBody;
  final String? certificateNumber;

  CmeTranscriptEntry({
    this.eventTitle,
    this.eventType,
    this.creditType,
    this.credits,
    this.completedDate,
    this.accreditationBody,
    this.certificateNumber,
  });

  factory CmeTranscriptEntry.fromJson(Map<String, dynamic> json) {
    return CmeTranscriptEntry(
      eventTitle: json['event_title'],
      eventType: json['event_type'],
      creditType: json['credit_type'],
      credits: json['credits'],
      completedDate: json['completed_date'],
      accreditationBody: json['accreditation_body'],
      certificateNumber: json['certificate_number'],
    );
  }
}

class CmeAchievementData {
  final String? id;
  final String? title;
  final String? description;
  final String? icon;
  final String? badge;
  final String? badgeColor;
  final bool? isEarned;
  final String? earnedAt;
  final double? progress;
  final String? category;

  CmeAchievementData({
    this.id,
    this.title,
    this.description,
    this.icon,
    this.badge,
    this.badgeColor,
    this.isEarned,
    this.earnedAt,
    this.progress,
    this.category,
  });

  factory CmeAchievementData.fromJson(Map<String, dynamic> json) {
    return CmeAchievementData(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      badge: json['badge'],
      badgeColor: json['badge_color'],
      isEarned: json['is_earned'],
      earnedAt: json['earned_at'],
      progress: (json['progress'] as num?)?.toDouble(),
      category: json['category'],
    );
  }
}
