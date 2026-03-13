class CmeGamificationData {
  final int? totalPoints;
  final int? level;
  final String? levelName;
  final int? nextLevelPoints;
  final int? currentStreak;
  final int? longestStreak;
  final int? rank;
  final int? totalUsers;
  final List<CmeBadgeData>? badges;
  final List<CmeLeaderboardEntry>? leaderboard;

  CmeGamificationData({
    this.totalPoints,
    this.level,
    this.levelName,
    this.nextLevelPoints,
    this.currentStreak,
    this.longestStreak,
    this.rank,
    this.totalUsers,
    this.badges,
    this.leaderboard,
  });

  factory CmeGamificationData.fromJson(Map<String, dynamic> json) {
    return CmeGamificationData(
      totalPoints: json['total_points'],
      level: json['level'],
      levelName: json['level_name'],
      nextLevelPoints: json['next_level_points'],
      currentStreak: json['current_streak'],
      longestStreak: json['longest_streak'],
      rank: json['rank'],
      totalUsers: json['total_users'],
      badges: json['badges'] != null
          ? (json['badges'] as List)
              .map((b) => CmeBadgeData.fromJson(b))
              .toList()
          : null,
      leaderboard: json['leaderboard'] != null
          ? (json['leaderboard'] as List)
              .map((l) => CmeLeaderboardEntry.fromJson(l))
              .toList()
          : null,
    );
  }

  double get levelProgress {
    if (nextLevelPoints == null || nextLevelPoints == 0) return 0.0;
    return ((totalPoints ?? 0) / nextLevelPoints!).clamp(0.0, 1.0);
  }
}

class CmeBadgeData {
  final String? id;
  final String? name;
  final String? description;
  final String? icon;
  final String? category; // event, quiz, streak, milestone, credit
  final String? tier; // bronze, silver, gold, platinum
  final bool? isEarned;
  final String? earnedAt;
  final int? pointsAwarded;
  final double? progress; // 0-100
  final String? requirement;

  CmeBadgeData({
    this.id,
    this.name,
    this.description,
    this.icon,
    this.category,
    this.tier,
    this.isEarned,
    this.earnedAt,
    this.pointsAwarded,
    this.progress,
    this.requirement,
  });

  factory CmeBadgeData.fromJson(Map<String, dynamic> json) {
    return CmeBadgeData(
      id: json['id'],
      name: json['name'] ?? json['title'],
      description: json['description'],
      icon: json['icon'],
      category: json['category'],
      tier: json['tier'] ?? json['badge_color'],
      isEarned: json['is_earned'],
      earnedAt: json['earned_at'],
      pointsAwarded: json['points_awarded'] ?? json['points'],
      progress: (json['progress'] as num?)?.toDouble(),
      requirement: json['requirement'],
    );
  }
}

class CmeLeaderboardEntry {
  final int? rank;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final String? specialty;
  final int? totalCredits;
  final int? totalPoints;
  final int? eventsCompleted;
  final int? badgesEarned;
  final bool? isCurrentUser;

  CmeLeaderboardEntry({
    this.rank,
    this.userId,
    this.userName,
    this.userAvatar,
    this.specialty,
    this.totalCredits,
    this.totalPoints,
    this.eventsCompleted,
    this.badgesEarned,
    this.isCurrentUser,
  });

  factory CmeLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return CmeLeaderboardEntry(
      rank: json['rank'],
      userId: json['user_id'],
      userName: json['user_name'] ?? json['name'],
      userAvatar: json['user_avatar'] ?? json['avatar'] ?? json['profile_pic'],
      specialty: json['specialty'],
      totalCredits: json['total_credits'],
      totalPoints: json['total_points'] ?? json['points'],
      eventsCompleted: json['events_completed'],
      badgesEarned: json['badges_earned'],
      isCurrentUser: json['is_current_user'],
    );
  }
}

class CmeShareableCertificate {
  final String? id;
  final String? certificateNumber;
  final String? eventTitle;
  final String? holderName;
  final String? creditType;
  final double? creditAmount;
  final String? issueDate;
  final String? expiryDate;
  final String? downloadUrl;
  final String? shareUrl;
  final String? verificationUrl;
  final String? qrCodeUrl;
  final bool? isValid;
  final String? accreditationBody;

  CmeShareableCertificate({
    this.id,
    this.certificateNumber,
    this.eventTitle,
    this.holderName,
    this.creditType,
    this.creditAmount,
    this.issueDate,
    this.expiryDate,
    this.downloadUrl,
    this.shareUrl,
    this.verificationUrl,
    this.qrCodeUrl,
    this.isValid,
    this.accreditationBody,
  });

  factory CmeShareableCertificate.fromJson(Map<String, dynamic> json) {
    return CmeShareableCertificate(
      id: json['id'],
      certificateNumber: json['certificate_number'],
      eventTitle: json['event_title'] ?? json['event']?['title'],
      holderName: json['holder_name'] ?? json['user']?['name'],
      creditType: json['credit_type'],
      creditAmount: (json['credit_amount'] as num?)?.toDouble(),
      issueDate: json['issue_date'] ?? json['issued_at'],
      expiryDate: json['expiry_date'] ?? json['expires_at'],
      downloadUrl: json['download_url'],
      shareUrl: json['share_url'],
      verificationUrl: json['verification_url'],
      qrCodeUrl: json['qr_code_url'],
      isValid: json['is_valid'],
      accreditationBody: json['accreditation_body'],
    );
  }
}

class CmeOnDemandModule {
  final String? id;
  final String? title;
  final String? description;
  final String? type; // video, article, interactive, quiz
  final String? thumbnailUrl;
  final String? contentUrl;
  final int? durationMinutes;
  final int? credits;
  final String? creditType;
  final String? difficulty;
  final String? specialty;
  final double? progressPercentage;
  final bool? isCompleted;
  final String? completedAt;
  final int? totalViews;
  final double? averageRating;
  final String? authorName;
  final String? authorAvatar;
  final List<CmeOnDemandSection>? sections;

  CmeOnDemandModule({
    this.id,
    this.title,
    this.description,
    this.type,
    this.thumbnailUrl,
    this.contentUrl,
    this.durationMinutes,
    this.credits,
    this.creditType,
    this.difficulty,
    this.specialty,
    this.progressPercentage,
    this.isCompleted,
    this.completedAt,
    this.totalViews,
    this.averageRating,
    this.authorName,
    this.authorAvatar,
    this.sections,
  });

  factory CmeOnDemandModule.fromJson(Map<String, dynamic> json) {
    return CmeOnDemandModule(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      thumbnailUrl: json['thumbnail_url'] ?? json['thumbnail'],
      contentUrl: json['content_url'] ?? json['url'],
      durationMinutes: json['duration_minutes'] ?? json['duration'],
      credits: json['credits'] ?? json['credit_amount'],
      creditType: json['credit_type'],
      difficulty: json['difficulty'],
      specialty: json['specialty'],
      progressPercentage:
          (json['progress_percentage'] ?? json['progress'] as num?)
              ?.toDouble(),
      isCompleted: json['is_completed'],
      completedAt: json['completed_at'],
      totalViews: json['total_views'] ?? json['views'],
      averageRating: (json['average_rating'] ?? json['rating'] as num?)
          ?.toDouble(),
      authorName: json['author_name'] ?? json['author']?['name'],
      authorAvatar: json['author_avatar'] ?? json['author']?['profile_pic'],
      sections: json['sections'] != null
          ? (json['sections'] as List)
              .map((s) => CmeOnDemandSection.fromJson(s))
              .toList()
          : null,
    );
  }
}

class CmeOnDemandSection {
  final String? id;
  final String? title;
  final String? type; // video, text, quiz
  final String? contentUrl;
  final String? htmlContent;
  final int? durationMinutes;
  final int? sortOrder;
  final bool? isCompleted;

  CmeOnDemandSection({
    this.id,
    this.title,
    this.type,
    this.contentUrl,
    this.htmlContent,
    this.durationMinutes,
    this.sortOrder,
    this.isCompleted,
  });

  factory CmeOnDemandSection.fromJson(Map<String, dynamic> json) {
    return CmeOnDemandSection(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      contentUrl: json['content_url'],
      htmlContent: json['html_content'] ?? json['content'],
      durationMinutes: json['duration_minutes'] ?? json['duration'],
      sortOrder: json['sort_order'] ?? json['order'],
      isCompleted: json['is_completed'],
    );
  }
}
