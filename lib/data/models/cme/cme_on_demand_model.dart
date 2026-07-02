class CmeOnDemandModule {
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
      id: json['id']?.toString(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String? ?? json['thumbnail'] as String?,
      contentUrl: json['content_url'] as String? ?? json['url'] as String?,
      durationMinutes: json['duration_minutes'] ?? json['duration'],
      credits: json['credits'] ?? json['credit_amount'],
      creditType: json['credit_type'] as String?,
      difficulty: json['difficulty'] as String?,
      specialty: json['specialty'] as String?,
      progressPercentage:
          (json['progress_percentage'] ?? json['progress'] as num?)?.toDouble(),
      isCompleted: json['is_completed'] as bool?,
      completedAt: json['completed_at'] as String?,
      totalViews: json['total_views'] ?? json['views'],
      averageRating:
          (json['average_rating'] ?? json['rating'] as num?)?.toDouble(),
      authorName: json['author_name'] as String? ?? json['author']?['name'] as String?,
      authorAvatar:
          json['author_avatar'] as String? ?? json['author']?['profile_pic'] as String?,
      sections: json['sections'] != null
          ? (json['sections'] as List)
              .map((s) => CmeOnDemandSection.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  final String? id;
  final String? title;
  final String? description;
  final String? type;
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
}

class CmeOnDemandSection {
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
      id: json['id']?.toString(),
      title: json['title'] as String?,
      type: json['type'] as String?,
      contentUrl: json['content_url'] as String?,
      htmlContent: json['html_content'] as String? ?? json['content'] as String?,
      durationMinutes: json['duration_minutes'] ?? json['duration'],
      sortOrder: json['sort_order'] ?? json['order'],
      isCompleted: json['is_completed'] as bool?,
    );
  }

  final String? id;
  final String? title;
  final String? type;
  final String? contentUrl;
  final String? htmlContent;
  final int? durationMinutes;
  final int? sortOrder;
  final bool? isCompleted;
}
