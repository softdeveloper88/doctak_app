/// Detail payload for a single blog/article (`GET /api/blogs/{id}`).
class BlogDetailModel {
  final String? title;
  final String? content;
  final String? excerpt;
  final String? coverImage;
  final String authorName;
  final String? authorAvatar;
  final String? authorSpecialty;
  final bool authorVerified;
  final String? createdAt;

  const BlogDetailModel({
    this.title,
    this.content,
    this.excerpt,
    this.coverImage,
    this.authorName = 'Doctor',
    this.authorAvatar,
    this.authorSpecialty,
    this.authorVerified = false,
    this.createdAt,
  });

  factory BlogDetailModel.fromJson(Map<String, dynamic> json) {
    String? str(String key) {
      final v = json[key];
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return BlogDetailModel(
      title: str('title'),
      content: str('content'),
      excerpt: str('excerpt'),
      coverImage: str('coverImage'),
      authorName: str('authorName') ?? 'Doctor',
      authorAvatar: str('authorAvatar'),
      authorSpecialty: str('authorSpecialty'),
      authorVerified: json['authorVerified'] == true ||
          json['authorVerified'] == 1 ||
          json['author_verified'] == true ||
          json['author_verified'] == 1,
      createdAt: str('createdAt'),
    );
  }
}

/// A single blog comment item.
class BlogComment {
  final int id;
  final String body;
  final String? createdAt;
  final String authorName;
  final String? authorAvatar;
  final int replyCount;

  const BlogComment({
    required this.id,
    required this.body,
    this.createdAt,
    this.authorName = 'Member',
    this.authorAvatar,
    this.replyCount = 0,
  });

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    final commenter = (json['commenter'] as Map?)?.cast<String, dynamic>() ?? {};
    return BlogComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      body: (json['body'] ?? json['comment'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
      authorName: (commenter['name'] ?? 'Member').toString(),
      authorAvatar: commenter['profile_pic']?.toString(),
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
    );
  }
}
