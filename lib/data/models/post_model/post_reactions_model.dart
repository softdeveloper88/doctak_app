import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';

class PostReactionsPage {
  final List<PostReactionUser> users;
  final Map<String, int> reactionCounts;
  final int currentPage;
  final int lastPage;
  final int total;

  const PostReactionsPage({
    required this.users,
    required this.reactionCounts,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PostReactionsPage.fromJson(Map<String, dynamic> json) {
    // Normalise the raw response into a (rows, meta) pair.
    // Handles multiple shapes returned by Laravel and Node:
    //   Shape A (Node paginated): { "likes": { "data": [...], "total": n, ... } }
    //   Shape B (Laravel flat):   { "likes": [...], "total": n }
    //   Shape C (root paginator): { "data": [...], "total": n }
    //   Shape D (root list):      [ ... ]

    List<dynamic> rows = const [];
    int currentPage = 1;
    int lastPage = 1;
    int total = 0;

    final likesRaw = json['likes'];

    if (likesRaw is Map) {
      // Shape A: Node paginator wrapped in "likes" key
      final inner = likesRaw['data'];
      rows = inner is List ? inner : const [];
      currentPage = (likesRaw['current_page'] as num?)?.toInt() ?? 1;
      lastPage = (likesRaw['last_page'] as num?)?.toInt() ?? 1;
      total = (likesRaw['total'] as num?)?.toInt() ?? rows.length;
    } else if (likesRaw is List) {
      // Shape B: Laravel returns flat list under "likes"
      rows = likesRaw;
      total = (json['total'] as num?)?.toInt() ?? rows.length;
      lastPage = (json['last_page'] as num?)?.toInt() ?? 1;
    } else {
      // Shape C / D: look for "data" at root, or treat root as list
      final dataRaw = json['data'];
      if (dataRaw is List) {
        rows = dataRaw;
        currentPage = (json['current_page'] as num?)?.toInt() ?? 1;
        lastPage = (json['last_page'] as num?)?.toInt() ?? 1;
        total = (json['total'] as num?)?.toInt() ?? rows.length;
      }
    }

    final countsRaw = json['reaction_counts'] ?? json['reactions'] ?? json['counts'];
    final counts = <String, int>{};
    if (countsRaw is Map) {
      countsRaw.forEach((key, value) {
        final type = key.toString().toLowerCase();
        final n = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
        if (type.isNotEmpty && n > 0) counts[type] = n;
      });
    }

    return PostReactionsPage(
      users: rows
          .whereType<Map>()
          .map((row) => PostReactionUser.fromJson(Map<String, dynamic>.from(row)))
          .toList(),
      reactionCounts: counts,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total > 0 ? total : rows.length,
    );
  }
}

class PostReactionUser {
  final String? userId;
  final String? name;
  final String? profilePic;
  final String? reactionType;
  final String? specialty;
  final String? location;
  final bool isVerified;
  final bool isPremium;
  final bool isFollowing;

  const PostReactionUser({
    this.userId,
    this.name,
    this.profilePic,
    this.reactionType,
    this.specialty,
    this.location,
    this.isVerified = false,
    this.isPremium = false,
    this.isFollowing = false,
  });

  factory PostReactionUser.fromJson(Map<String, dynamic> json) {
    // Laravel pivot rows often nest user data under a "user" key:
    // { "id": 5, "reaction_type": "like", "user": { "id": 1, "name": "...", ... } }
    final nested = json['user'];
    final u = nested is Map<String, dynamic>
        ? nested
        : (nested is Map ? Map<String, dynamic>.from(nested) : json);

    final rawName = (u['name'] ?? json['name'] ?? '').toString().trim();
    final firstLast = '${u['first_name'] ?? json['first_name'] ?? ''} ${u['last_name'] ?? json['last_name'] ?? ''}'.trim();
    // user_id may be in the outer row; id may be in the nested user object
    final userId = (json['user_id'] ?? u['id'] ?? json['id'])?.toString();
    final specialty = (u['specialty'] ?? json['specialty'] ?? '').toString().trim();
    final location = (u['location'] ?? json['location'] ?? '').toString().trim();
    final reactionType = (json['reaction_type'] ?? json['reaction'] ?? u['reaction_type'])?.toString();
    final pic = u['profile_pic'] ?? json['profile_pic'] ?? u['avatar'] ?? json['avatar'];

    return PostReactionUser(
      userId: userId,
      name: rawName.isNotEmpty ? rawName : (firstLast.isNotEmpty ? firstLast : 'Member'),
      profilePic: AppData.fullImageUrl(pic?.toString()),
      reactionType: reactionType,
      specialty: specialty.isEmpty ? null : specialty,
      location: location.isEmpty ? null : location,
      isVerified: (u['is_verified'] ?? json['is_verified']) == true ||
          (u['is_verified'] ?? json['is_verified']) == 1,
      isPremium: (u['is_premium'] ?? json['is_premium']) == true ||
          (u['is_premium'] ?? json['is_premium']) == 1,
      isFollowing: (u['is_following'] ?? json['is_following']) == true ||
          (u['is_following'] ?? json['is_following']) == 1,
    );
  }

  String get subtitle {
    final parts = <String>[];
    final spec = specialtyLabelOrNull(specialty);
    if (spec != null) parts.add(spec);
    if (location != null && location!.isNotEmpty) parts.add(location!);
    return parts.join(' · ');
  }
}
