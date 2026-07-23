/// Parsed like/dislike counts returned by the vote API (source of truth after persist).
class CaseVoteSnapshot {
  final int likes;
  final int dislikes;
  final bool isLiked;
  final bool isDisliked;

  const CaseVoteSnapshot({
    required this.likes,
    required this.dislikes,
    required this.isLiked,
    required this.isDisliked,
  });

  static CaseVoteSnapshot? fromApiResponse(Map<String, dynamic> response) {
    final nested = response['data'];
    final Map<String, dynamic> source =
        nested is Map ? Map<String, dynamic>.from(nested) : response;

    final likesRaw = source['likes'] ?? source['upvotes'] ?? source['like_count'];
    final dislikesRaw = source['dislikes'] ?? source['downvotes'];
    final userVoteRaw = source['user_vote'] ?? source['userVote'] ?? response['userVote'];

    if (likesRaw == null &&
        dislikesRaw == null &&
        userVoteRaw == null &&
        source['liked'] == null &&
        response['liked'] == null) {
      return null;
    }

    final userVote = userVoteRaw?.toString() ?? '';
    final isLiked = userVote == 'up' || userVote == 'like' || source['liked'] == true || response['liked'] == true;
    final isDisliked = userVote == 'down' || userVote == 'dislike';

    return CaseVoteSnapshot(
      likes: _parseVoteInt(likesRaw),
      dislikes: _parseVoteInt(dislikesRaw),
      isLiked: isLiked,
      isDisliked: isDisliked,
    );
  }
}

int _parseVoteInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
