/// Model for Social Profiles (maps to user_social_profiles / social_accounts table)
class SocialProfileModel {
  int? id;
  String? userId;
  String? platform;
  String? url;
  String? profileUrl;
  String? username;
  bool? isPublic;
  String? createdAt;
  String? updatedAt;

  SocialProfileModel({
    this.id,
    this.userId,
    this.platform,
    this.url,
    this.profileUrl,
    this.username,
    this.isPublic,
    this.createdAt,
    this.updatedAt,
  });

  factory SocialProfileModel.fromJson(Map<String, dynamic> json) {
    return SocialProfileModel(
      id: json['id'] as int?,
      userId: json['user_id']?.toString(),
      platform: json['platform'] as String?,
      url: json['url'] as String?,
      profileUrl: json['profile_url'] as String?,
      username: json['username'] as String?,
      isPublic: json['is_public'] is bool
          ? json['is_public']
          : (json['is_public'] == 1 || json['is_public'] == '1'),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'profile_url': effectiveUrl,
      'username': username,
      'is_public': isPublic == true ? 1 : 0,
    };
  }

  String get effectiveUrl => profileUrl ?? url ?? '';

  String get displayPlatform {
    switch (platform?.toLowerCase()) {
      case 'linkedin':
        return 'LinkedIn';
      case 'twitter':
        return 'Twitter / X';
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      case 'researchgate':
        return 'ResearchGate';
      case 'orcid':
        return 'ORCID';
      case 'pubmed':
        return 'PubMed';
      case 'google_scholar':
        return 'Google Scholar';
      case 'website':
        return 'Website';
      default:
        return platform ?? 'Other';
    }
  }

  static const List<String> availablePlatforms = [
    'linkedin',
    'twitter',
    'facebook',
    'instagram',
    'researchgate',
    'orcid',
    'pubmed',
    'google_scholar',
    'website',
    'other',
  ];
}
