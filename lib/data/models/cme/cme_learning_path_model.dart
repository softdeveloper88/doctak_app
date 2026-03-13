class CmeLearningPathData {
  final String? id;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? difficulty; // beginner, intermediate, advanced
  final String? specialty;
  final String? category;
  final int? totalCredits;
  final String? creditType;
  final int? totalEvents;
  final int? estimatedHours;
  final int? enrolledCount;
  final String? status; // active, draft, archived
  final String? createdAt;
  final String? updatedAt;
  final CmeLearningPathEnrollment? enrollment;
  final List<CmePathEventItem>? events;
  final String? creatorName;
  final String? creatorAvatar;

  CmeLearningPathData({
    this.id,
    this.title,
    this.description,
    this.imageUrl,
    this.difficulty,
    this.specialty,
    this.category,
    this.totalCredits,
    this.creditType,
    this.totalEvents,
    this.estimatedHours,
    this.enrolledCount,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.enrollment,
    this.events,
    this.creatorName,
    this.creatorAvatar,
  });

  factory CmeLearningPathData.fromJson(Map<String, dynamic> json) {
    return CmeLearningPathData(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'] ?? json['image'],
      difficulty: json['difficulty'] ?? json['level'],
      specialty: json['specialty'],
      category: json['category'],
      totalCredits: json['total_credits'],
      creditType: json['credit_type'],
      totalEvents: json['total_events'] ?? json['events_count'],
      estimatedHours: json['estimated_hours'],
      enrolledCount: json['enrolled_count'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      enrollment: json['enrollment'] != null
          ? CmeLearningPathEnrollment.fromJson(json['enrollment'])
          : null,
      events: json['events'] != null
          ? (json['events'] as List)
              .map((e) => CmePathEventItem.fromJson(e))
              .toList()
          : null,
      creatorName: json['creator_name'] ?? json['creator']?['name'],
      creatorAvatar:
          json['creator_avatar'] ?? json['creator']?['profile_pic'],
    );
  }

  bool get isEnrolled => enrollment != null;
  double get progressPercentage =>
      enrollment?.progressPercentage ?? 0.0;
  String get displayDifficulty =>
      (difficulty ?? 'intermediate')
          .replaceFirst(difficulty![0], difficulty![0].toUpperCase());
}

class CmeLearningPathEnrollment {
  final String? id;
  final String? pathId;
  final String? status; // active, paused, completed
  final double? progressPercentage;
  final int? completedEvents;
  final int? earnedCredits;
  final String? enrolledAt;
  final String? completedAt;

  CmeLearningPathEnrollment({
    this.id,
    this.pathId,
    this.status,
    this.progressPercentage,
    this.completedEvents,
    this.earnedCredits,
    this.enrolledAt,
    this.completedAt,
  });

  factory CmeLearningPathEnrollment.fromJson(Map<String, dynamic> json) {
    return CmeLearningPathEnrollment(
      id: json['id'],
      pathId: json['learning_path_id'] ?? json['path_id'],
      status: json['status'],
      progressPercentage:
          (json['progress_percentage'] ?? json['progress'] as num?)
              ?.toDouble(),
      completedEvents: json['completed_events'],
      earnedCredits: json['earned_credits'],
      enrolledAt: json['enrolled_at'],
      completedAt: json['completed_at'],
    );
  }

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';
}

class CmePathEventItem {
  final String? id;
  final String? eventId;
  final String? title;
  final String? type;
  final int? credits;
  final int? orderIndex;
  final bool? isRequired;
  final bool? isCompleted;
  final String? status;

  CmePathEventItem({
    this.id,
    this.eventId,
    this.title,
    this.type,
    this.credits,
    this.orderIndex,
    this.isRequired,
    this.isCompleted,
    this.status,
  });

  factory CmePathEventItem.fromJson(Map<String, dynamic> json) {
    return CmePathEventItem(
      id: json['id'],
      eventId: json['event_id'],
      title: json['title'] ?? json['event']?['title'],
      type: json['type'] ?? json['event']?['event_type'],
      credits: json['credits'] ?? json['event']?['credits'],
      orderIndex: json['order_index'] ?? json['order'],
      isRequired: json['is_required'],
      isCompleted: json['is_completed'],
      status: json['status'],
    );
  }
}
