import 'package:doctak_app/core/utils/specialty_display.dart';

class GroupMembershipModel {
  final String role;
  final String status;
  final String? joinedAt;
  final String? invitedAt;

  const GroupMembershipModel({
    required this.role,
    required this.status,
    this.joinedAt,
    this.invitedAt,
  });

  factory GroupMembershipModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const GroupMembershipModel(role: 'member', status: 'pending');
    }
    return GroupMembershipModel(
      role: json['role']?.toString() ?? 'member',
      status: json['status']?.toString() ?? 'pending',
      joinedAt: json['joinedAt']?.toString(),
      invitedAt: json['invitedAt']?.toString(),
    );
  }

  bool get isActiveMember =>
      status == 'active' || status == 'approved';

  bool get isPending => status == 'pending';
}

class GroupUserStubModel {
  final String id;
  final String name;
  final String? avatar;
  final String? specialty;
  final bool verified;

  const GroupUserStubModel({
    required this.id,
    required this.name,
    this.avatar,
    this.specialty,
    this.verified = false,
  });

  factory GroupUserStubModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const GroupUserStubModel(id: '', name: 'Unknown');
    }
    return GroupUserStubModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      avatar: json['avatar']?.toString(),
      specialty: json['specialty']?.toString(),
      verified: json['verified'] == true,
    );
  }

  /// Resolved specialty name — hides bare numeric IDs from the database.
  String? get specialtyLabel => specialtyLabelOrNull(specialty);
}

class GroupSummaryModel {
  final String id;
  final String? uuid;
  final String name;
  final String? description;
  final String privacy;
  final String groupType;
  final String? bannerImage;
  final String? logoImage;
  final String? primaryColor;
  final String? secondaryColor;
  final int? specialtyId;
  final String? specialty;
  final bool isVerified;
  final int membersCount;
  final int postsCount;
  final int pollsCount;
  final int articlesCount;
  final String? lastActivityAt;
  final String? createdAt;
  final GroupMembershipModel? membership;

  const GroupSummaryModel({
    required this.id,
    this.uuid,
    required this.name,
    this.description,
    required this.privacy,
    required this.groupType,
    this.bannerImage,
    this.logoImage,
    this.primaryColor,
    this.secondaryColor,
    this.specialtyId,
    this.specialty,
    this.isVerified = false,
    this.membersCount = 0,
    this.postsCount = 0,
    this.pollsCount = 0,
    this.articlesCount = 0,
    this.lastActivityAt,
    this.createdAt,
    this.membership,
  });

  /// Primary API/navigation identifier — numeric DB [id] is always unique.
  /// Prefer it over [uuid] so list cards and detail requests cannot diverge
  /// when legacy rows share or omit uuids.
  String get routeId {
    final dbId = id.trim();
    if (dbId.isNotEmpty) return dbId;
    final slug = uuid?.trim();
    return (slug != null && slug.isNotEmpty) ? slug : '';
  }

  /// Public share URL slug (uuid when available).
  String get publicSlug {
    final slug = uuid?.trim();
    if (slug != null && slug.isNotEmpty) return slug;
    return id.trim();
  }

  factory GroupSummaryModel.fromJson(Map<String, dynamic> json) {
    return GroupSummaryModel(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid']?.toString(),
      name: json['name']?.toString() ?? 'Group',
      description: json['description']?.toString(),
      privacy: json['privacy']?.toString() ?? 'public',
      groupType: json['groupType']?.toString() ?? 'general',
      bannerImage: json['bannerImage']?.toString(),
      logoImage: json['logoImage']?.toString(),
      primaryColor: json['primaryColor']?.toString(),
      secondaryColor: json['secondaryColor']?.toString(),
      specialtyId: json['specialtyId'] is num
          ? (json['specialtyId'] as num).toInt()
          : int.tryParse(json['specialtyId']?.toString() ?? ''),
      specialty: json['specialty']?.toString(),
      isVerified: json['isVerified'] == true,
      membersCount: _asInt(json['membersCount']),
      postsCount: _asInt(json['postsCount']),
      pollsCount: _asInt(json['pollsCount']),
      articlesCount: _asInt(json['articlesCount']),
      lastActivityAt: json['lastActivityAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      membership: json['membership'] == null
          ? null
          : GroupMembershipModel.fromJson(
              Map<String, dynamic>.from(json['membership'] as Map),
            ),
    );
  }
}

class GroupCapabilitiesModel {
  final bool canPost;
  final bool canManage;
  final bool canInvite;
  final bool canModerate;
  final bool canViewMembers;
  final bool isOwner;
  final bool canRemoveMembers;
  final bool requiresApproval;

  const GroupCapabilitiesModel({
    this.canPost = false,
    this.canManage = false,
    this.canInvite = false,
    this.canModerate = false,
    this.canViewMembers = false,
    this.isOwner = false,
    this.canRemoveMembers = false,
    this.requiresApproval = false,
  });

  factory GroupCapabilitiesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GroupCapabilitiesModel();
    return GroupCapabilitiesModel(
      canPost: json['canPost'] == true,
      canManage: json['canManage'] == true,
      canInvite: json['canInvite'] == true,
      canModerate: json['canModerate'] == true,
      canViewMembers: json['canViewMembers'] == true,
      isOwner: json['isOwner'] == true,
      canRemoveMembers: json['canRemoveMembers'] == true,
      requiresApproval: json['requiresApproval'] == true,
    );
  }
}

class GroupSettingsModel {
  final bool allowMemberPosts;
  final bool requirePostApproval;
  final bool enablePolls;
  final bool enableDiscussions;
  final bool enableDocumentLibrary;

  const GroupSettingsModel({
    this.allowMemberPosts = true,
    this.requirePostApproval = false,
    this.enablePolls = true,
    this.enableDiscussions = true,
    this.enableDocumentLibrary = true,
  });

  factory GroupSettingsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GroupSettingsModel();
    return GroupSettingsModel(
      allowMemberPosts: json['allowMemberPosts'] != false,
      requirePostApproval: json['requirePostApproval'] == true,
      enablePolls: json['enablePolls'] != false,
      enableDiscussions: json['enableDiscussions'] != false,
      enableDocumentLibrary: json['enableDocumentLibrary'] != false,
    );
  }
}

class GroupDetailModel extends GroupSummaryModel {
  final String? purposeDefinition;
  final String? communityGuidelines;
  final GroupSettingsModel settings;
  final GroupCapabilitiesModel capabilities;
  final GroupUserStubModel? creator;
  final List<GroupUserStubModel> admins;
  final List<GroupUserStubModel> moderators;

  const GroupDetailModel({
    required super.id,
    super.uuid,
    required super.name,
    super.description,
    required super.privacy,
    required super.groupType,
    super.bannerImage,
    super.logoImage,
    super.primaryColor,
    super.secondaryColor,
    super.specialtyId,
    super.specialty,
    super.isVerified,
    super.membersCount,
    super.postsCount,
    super.pollsCount,
    super.articlesCount,
    super.lastActivityAt,
    super.createdAt,
    super.membership,
    this.purposeDefinition,
    this.communityGuidelines,
    this.settings = const GroupSettingsModel(),
    this.capabilities = const GroupCapabilitiesModel(),
    this.creator,
    this.admins = const [],
    this.moderators = const [],
  });

  factory GroupDetailModel.fromJson(Map<String, dynamic> json) {
    final summary = GroupSummaryModel.fromJson(json);
    return GroupDetailModel(
      id: summary.id,
      uuid: summary.uuid,
      name: summary.name,
      description: summary.description,
      privacy: summary.privacy,
      groupType: summary.groupType,
      bannerImage: summary.bannerImage,
      logoImage: summary.logoImage,
      primaryColor: summary.primaryColor,
      secondaryColor: summary.secondaryColor,
      specialtyId: summary.specialtyId,
      specialty: summary.specialty,
      isVerified: summary.isVerified,
      membersCount: summary.membersCount,
      postsCount: summary.postsCount,
      pollsCount: summary.pollsCount,
      articlesCount: summary.articlesCount,
      lastActivityAt: summary.lastActivityAt,
      createdAt: summary.createdAt,
      membership: summary.membership,
      purposeDefinition: json['purposeDefinition']?.toString(),
      communityGuidelines: json['communityGuidelines']?.toString(),
      settings: GroupSettingsModel.fromJson(
        json['settings'] is Map
            ? Map<String, dynamic>.from(json['settings'] as Map)
            : null,
      ),
      capabilities: GroupCapabilitiesModel.fromJson(
        json['capabilities'] is Map
            ? Map<String, dynamic>.from(json['capabilities'] as Map)
            : null,
      ),
      creator: json['creator'] is Map
          ? GroupUserStubModel.fromJson(
              Map<String, dynamic>.from(json['creator'] as Map),
            )
          : null,
      admins: _userList(json['admins']),
      moderators: _userList(json['moderators']),
    );
  }
}

class GroupFacetsModel {
  final int total;
  final int mine;
  final int joined;
  final int pendingInvitations;

  const GroupFacetsModel({
    this.total = 0,
    this.mine = 0,
    this.joined = 0,
    this.pendingInvitations = 0,
  });

  factory GroupFacetsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const GroupFacetsModel();
    return GroupFacetsModel(
      total: _asInt(json['total']),
      mine: _asInt(json['mine']),
      joined: _asInt(json['joined']),
      pendingInvitations: _asInt(json['pendingInvitations']),
    );
  }
}

class GroupListResultModel {
  final List<GroupSummaryModel> items;
  final String? nextCursor;
  final int total;
  final GroupFacetsModel? facets;

  const GroupListResultModel({
    required this.items,
    this.nextCursor,
    this.total = 0,
    this.facets,
  });
}

class GroupInvitationModel {
  final String id;
  final String groupId;
  final String? groupName;
  final String? groupLogo;
  final GroupSummaryModel? group;
  final String status;
  final String? message;
  final String? createdAt;
  final GroupUserStubModel? inviter;

  const GroupInvitationModel({
    required this.id,
    required this.groupId,
    this.groupName,
    this.groupLogo,
    this.group,
    required this.status,
    this.message,
    this.createdAt,
    this.inviter,
  });

  factory GroupInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupInvitationModel(
      id: json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      groupName: json['groupName']?.toString(),
      groupLogo: json['groupLogo']?.toString(),
      group: json['group'] is Map
          ? GroupSummaryModel.fromJson(
              Map<String, dynamic>.from(json['group'] as Map),
            )
          : null,
      status: json['status']?.toString() ?? 'pending',
      message: json['message']?.toString(),
      createdAt: json['createdAt']?.toString(),
      inviter: json['inviter'] is Map
          ? GroupUserStubModel.fromJson(
              Map<String, dynamic>.from(json['inviter'] as Map),
            )
          : null,
    );
  }
}

class GroupFeedPostMediaModel {
  final String? mediaType;
  final String? mediaPath;
  final String? url;

  const GroupFeedPostMediaModel({this.mediaType, this.mediaPath, this.url});

  bool get isVisual {
    final type = (mediaType ?? 'image').toLowerCase();
    return type == 'image' || type == 'video';
  }

  factory GroupFeedPostMediaModel.fromJson(Map<String, dynamic> json) {
    return GroupFeedPostMediaModel(
      mediaType: json['mediaType']?.toString(),
      mediaPath: json['mediaPath']?.toString(),
      url: json['url']?.toString(),
    );
  }
}

class GroupFeedPostModel {
  final String id;
  final String postId;
  final String? title;
  final String? body;
  final String? caption;
  final String? postType;
  final bool isPinned;
  final bool isAnnouncement;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final String? createdAt;
  final GroupUserStubModel? author;
  final List<GroupFeedPostMediaModel> media;

  const GroupFeedPostModel({
    required this.id,
    required this.postId,
    this.title,
    this.body,
    this.caption,
    this.postType,
    this.isPinned = false,
    this.isAnnouncement = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
    this.createdAt,
    this.author,
    this.media = const [],
  });

  String get displayText =>
      (body?.trim().isNotEmpty == true ? body : caption)?.trim() ?? title ?? '';

  factory GroupFeedPostModel.fromJson(Map<String, dynamic> json) {
    return GroupFeedPostModel(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      caption: json['caption']?.toString(),
      postType: json['postType']?.toString(),
      isPinned: json['isPinned'] == true,
      isAnnouncement: json['isAnnouncement'] == true,
      likesCount: _asInt(json['likesCount']),
      commentsCount: _asInt(json['commentsCount']),
      likedByMe: json['likedByMe'] == true,
      createdAt: json['createdAt']?.toString(),
      author: json['author'] is Map
          ? GroupUserStubModel.fromJson(
              Map<String, dynamic>.from(json['author'] as Map),
            )
          : null,
      media: (json['media'] as List<dynamic>? ?? [])
          .map((e) => GroupFeedPostMediaModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

class GroupPollOptionModel {
  final String id;
  final String label;
  final int votes;

  const GroupPollOptionModel({
    required this.id,
    required this.label,
    this.votes = 0,
  });

  factory GroupPollOptionModel.fromJson(Map<String, dynamic> json) {
    return GroupPollOptionModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      votes: _asInt(json['votes']),
    );
  }
}

class GroupPollModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final int totalVotes;
  final String? createdAt;
  final List<GroupPollOptionModel> options;
  final GroupUserStubModel? author;
  final List<String>? myVote;
  final bool allowMultipleSelections;

  const GroupPollModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.totalVotes = 0,
    this.createdAt,
    this.options = const [],
    this.author,
    this.myVote,
    this.allowMultipleSelections = false,
  });

  bool get hasVoted => myVote != null && myVote!.isNotEmpty;

  bool get isClosed =>
      status == 'ended' || status == 'archived' || status == 'paused';

  factory GroupPollModel.fromJson(Map<String, dynamic> json) {
    final rawVote = json['myVote'];
    List<String>? myVote;
    if (rawVote is List) {
      myVote = rawVote.map((e) => e.toString()).toList();
    }
    return GroupPollModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Poll',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'active',
      totalVotes: _asInt(json['totalVotes']),
      createdAt: json['createdAt']?.toString(),
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => GroupPollOptionModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      author: json['author'] is Map
          ? GroupUserStubModel.fromJson(
              Map<String, dynamic>.from(json['author'] as Map),
            )
          : null,
      myVote: myVote,
      allowMultipleSelections: json['allowMultipleSelections'] == true,
    );
  }
}

class GroupFeedEntryModel {
  final String kind;
  final String createdAt;
  final GroupFeedPostModel? post;
  final GroupPollModel? poll;

  const GroupFeedEntryModel({
    required this.kind,
    required this.createdAt,
    this.post,
    this.poll,
  });

  factory GroupFeedEntryModel.fromJson(Map<String, dynamic> json) {
    final kind = json['kind']?.toString() ?? 'post';
    final item = json['item'] is Map
        ? Map<String, dynamic>.from(json['item'] as Map)
        : <String, dynamic>{};
    return GroupFeedEntryModel(
      kind: kind,
      createdAt: json['createdAt']?.toString() ?? '',
      post: kind == 'post' ? GroupFeedPostModel.fromJson(item) : null,
      poll: kind == 'poll' ? GroupPollModel.fromJson(item) : null,
    );
  }
}

class GroupFeedResultModel {
  final List<GroupFeedEntryModel> items;
  final String? nextCursor;
  final int total;

  const GroupFeedResultModel({
    required this.items,
    this.nextCursor,
    this.total = 0,
  });
}

class GroupMemberModel {
  final String memberId;
  final String id;
  final String name;
  final String? avatar;
  final String? specialty;
  final String role;
  final String status;
  final String? joinedAt;
  final int postsCount;

  const GroupMemberModel({
    required this.memberId,
    required this.id,
    required this.name,
    this.avatar,
    this.specialty,
    required this.role,
    required this.status,
    this.joinedAt,
    this.postsCount = 0,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      memberId: json['memberId']?.toString() ?? json['id']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Member',
      avatar: json['avatar']?.toString(),
      specialty: json['specialty']?.toString(),
      role: json['role']?.toString() ?? 'member',
      status: json['status']?.toString() ?? 'active',
      joinedAt: json['joinedAt']?.toString(),
      postsCount: _asInt(json['postsCount']),
    );
  }

  /// Resolved specialty name — hides bare numeric IDs from the database.
  String? get specialtyLabel => specialtyLabelOrNull(specialty);
}

class GroupMembersResultModel {
  final List<GroupMemberModel> items;
  final String? nextCursor;
  final int total;
  final Map<String, int> counts;

  const GroupMembersResultModel({
    required this.items,
    this.nextCursor,
    this.total = 0,
    this.counts = const {},
  });
}

class GroupPostsResultModel {
  final List<GroupFeedPostModel> items;
  final String? nextCursor;
  final int total;
  final Map<String, int>? counts;

  const GroupPostsResultModel({
    required this.items,
    this.nextCursor,
    this.total = 0,
    this.counts,
  });
}

class GroupPostMediaUpload {
  final String mediaType;
  final String mediaPath;
  final String originalFilename;
  final int fileSize;
  final String mimeType;

  const GroupPostMediaUpload({
    required this.mediaType,
    required this.mediaPath,
    required this.originalFilename,
    required this.fileSize,
    required this.mimeType,
  });

  Map<String, dynamic> toJson() => {
        'mediaType': mediaType,
        'mediaPath': mediaPath,
        'originalFilename': originalFilename,
        'fileSize': fileSize,
        'mimeType': mimeType,
      };

  factory GroupPostMediaUpload.fromJson(Map<String, dynamic> json) {
    return GroupPostMediaUpload(
      mediaType: json['mediaType']?.toString() ?? 'image',
      mediaPath: json['mediaPath']?.toString() ?? '',
      originalFilename: json['originalFilename']?.toString() ?? '',
      fileSize: _asInt(json['fileSize']),
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<GroupUserStubModel> _userList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => GroupUserStubModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ))
      .toList();
}

String formatGroupPrivacy(String privacy) {
  switch (privacy) {
    case 'private':
      return 'Private';
    case 'invitation_only':
      return 'Invite only';
    default:
      return 'Public';
  }
}

String formatGroupType(String groupType) {
  switch (groupType) {
    case 'medical_specialty':
      return 'Medical specialty';
    case 'research':
      return 'Research';
    case 'educational':
      return 'Educational';
    case 'clinical':
      return 'Clinical';
    default:
      return 'General';
  }
}

String formatGroupMetaLine(GroupSummaryModel group) {
  final parts = <String>[
    formatGroupPrivacy(group.privacy),
    formatGroupType(group.groupType),
  ];
  if (group.specialty?.trim().isNotEmpty == true) {
    parts.add(group.specialty!.trim());
  }
  return parts.join(' • ');
}

String formatGroupActivityLabel(String? iso) {
  if (iso == null || iso.isEmpty) return 'Recently active';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return 'Recently active';
  final diff = DateTime.now().difference(parsed);
  if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
  if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
  if (diff.inDays < 30) return 'Active ${(diff.inDays / 7).floor()}w ago';
  return 'Active ${(diff.inDays / 30).floor()}mo ago';
}
