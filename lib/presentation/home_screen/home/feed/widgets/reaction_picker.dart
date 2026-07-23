import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_icons.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_motion.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// A single reaction definition, mirroring the doctak-node website set.
class FeedReaction {
  final String type;
  final String emoji;
  final String label;
  final Color color;
  const FeedReaction(this.type, this.emoji, this.label, this.color);
}

/// The 8 website reaction types (order matches the web picker, angry last).
const List<FeedReaction> kFeedReactions = [
  FeedReaction('like', '👍', 'Like', Color(0xFF0B6BCB)),
  FeedReaction('love', '❤️', 'Love', Color(0xFFE0245E)),
  FeedReaction('insightful', '💡', 'Insightful', Color(0xFFF5A623)),
  FeedReaction('care', '🤗', 'Care', Color(0xFFF59E0B)),
  FeedReaction('haha', '😄', 'Haha', Color(0xFFF7B125)),
  FeedReaction('wow', '😮', 'Wow', Color(0xFFF7B125)),
  FeedReaction('sad', '😢', 'Sad', Color(0xFF7C8DB5)),
  FeedReaction('angry', '😡', 'Angry', Color(0xFFE0511E)),
];

FeedReaction? reactionByType(String? type) {
  if (type == null || type.isEmpty) return null;
  for (final r in kFeedReactions) {
    if (r.type == type) return r;
  }
  return null;
}

/// Top reaction types from API summary (`getPostReactionSummary` / blog like GET).
/// Each type appears once, ordered by count descending, max [limit] faces.
List<FeedReaction> topReactionsFromSummary(List<dynamic>? raw, {int limit = 3}) {
  if (raw == null || raw.isEmpty) return const [];
  final entries = <Map<String, dynamic>>[];
  for (final entry in raw) {
    if (entry is Map) entries.add(Map<String, dynamic>.from(entry));
  }
  entries.sort((a, b) {
    int count(Map<String, dynamic> m) {
      final v = m['count'];
      return v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    }
    return count(b).compareTo(count(a));
  });
  final out = <FeedReaction>[];
  for (final entry in entries) {
    if (out.length >= limit) break;
    final type = entry['type']?.toString();
    if (type == null || type.isEmpty) continue;
    final r = reactionByType(type);
    if (r != null && out.every((x) => x.type != r.type)) out.add(r);
  }
  return out;
}

/// Parse `topReactions` bundled in `GET /api/feed` item payloads.
List<FeedReaction> topReactionsFromFeedItem(FeedItem item) {
  return topReactionsFromSummary(item.listVal('topReactions'), limit: 3);
}

/// Session cache — seeded from feed API, updated locally when user reacts.
final Map<String, List<FeedReaction>> feedTopReactionsCache = {};
final Set<String> feedTopReactionsLocallyModified = {};

String feedTopReactionsCacheKey(String contentType, String itemId) =>
    '$contentType:$itemId';

void resetFeedTopReactionsCache() {
  feedTopReactionsCache.clear();
  feedTopReactionsLocallyModified.clear();
}

/// Resolve emoji faces: feed payload first, then local session overrides.
List<FeedReaction> resolveFeedTopReactions({
  required FeedItem item,
  required String contentType,
  required int likeCount,
  required bool showFaces,
}) {
  if (!showFaces || likeCount <= 0) return const [];

  if (contentType == 'case') {
    return likeCount > 0 ? [kFeedReactions.first] : const [];
  }

  final key = feedTopReactionsCacheKey(contentType, item.id);

  if (feedTopReactionsLocallyModified.contains(key)) {
    return feedTopReactionsCache[key] ??
        (likeCount > 0 ? [kFeedReactions.first] : const []);
  }

  final fromFeed = topReactionsFromFeedItem(item);
  if (fromFeed.isNotEmpty) {
    feedTopReactionsCache[key] = fromFeed;
    return fromFeed;
  }

  final cached = feedTopReactionsCache[key];
  if (cached != null && cached.isNotEmpty) return cached;

  return likeCount > 0 ? [kFeedReactions.first] : const [];
}

/// Adjust cached emoji faces after a local react (no summary API call).
List<FeedReaction> applyLocalReactionFaces(
  List<FeedReaction> current, {
  required String? previousType,
  required String? newType,
  required int likeCount,
}) {
  if (likeCount <= 0) return const [];

  var types = current.map((r) => r.type).toList();

  if (previousType != null && previousType == newType) {
    types.remove(previousType);
  } else {
    if (previousType != null) types.remove(previousType);
    if (newType != null) {
      types.remove(newType);
      types.insert(0, newType);
    }
  }

  if (types.isEmpty && newType != null) {
    types = [newType];
  }

  return types
      .take(3)
      .map(reactionByType)
      .whereType<FeedReaction>()
      .toList();
}

void updateFeedTopReactionsCache({
  required String contentType,
  required String itemId,
  required String? previousType,
  required String? newType,
  required int likeCount,
}) {
  final key = feedTopReactionsCacheKey(contentType, itemId);
  if (likeCount <= 0) {
    feedTopReactionsCache.remove(key);
    feedTopReactionsLocallyModified.remove(key);
    return;
  }
  final current = feedTopReactionsCache[key] ?? const [];
  final next = applyLocalReactionFaces(
    current,
    previousType: previousType,
    newType: newType,
    likeCount: likeCount,
  );
  if (next.isEmpty) {
    feedTopReactionsCache.remove(key);
    feedTopReactionsLocallyModified.remove(key);
  } else {
    feedTopReactionsCache[key] = next;
    feedTopReactionsLocallyModified.add(key);
  }
}

/// Overlapping emoji cluster for the top reaction types on a post (website parity).
class ReactionFacesStack extends StatelessWidget {
  final List<FeedReaction> reactions;

  const ReactionFacesStack({super.key, required this.reactions});

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);
    const size = 18.0;
    const overlap = 12.0;

    return SizedBox(
      width: size + (reactions.length - 1) * overlap,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < reactions.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: reactions[i].color,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardBackground, width: 1.5),
                ),
                child: Text(
                  reactions[i].emoji,
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// LinkedIn/Facebook style reaction button.
///
/// - Tap: toggles Like (sets `like` if none, removes if any reaction is active).
/// - Long press: opens a floating reaction bar to pick a specific reaction.
/// [onChanged] receives the new reaction type, or `null` when the reaction is
/// removed.
class ReactionButton extends StatefulWidget {
  final String? currentReaction;
  final ValueChanged<String?> onChanged;

  /// When true (default), shows only the emoji/icon — no "Like" label.
  final bool iconOnly;

  const ReactionButton({
    super.key,
    required this.currentReaction,
    required this.onChanged,
    this.iconOnly = true,
  });

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  OverlayEntry? _overlay;
  final GlobalKey _anchorKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showPicker() {
    _removeOverlay();
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final theme = OneUITheme.of(context);
    final screen = MediaQuery.sizeOf(context);
    const edge = 12.0;
    const gap = 8.0;
    // ~36 px per emoji slot + horizontal container padding.
    final pickerWidth = kFeedReactions.length * 36.0 + 16.0;
    const pickerHeight = 44.0;

    final anchor = box.localToGlobal(Offset.zero);
    final anchorSize = box.size;

    // Anchor picker to the button's left edge and extend right so nothing
    // is clipped off the left side of the screen.
    double left = anchor.dx;
    if (left + pickerWidth > screen.width - edge) {
      left = screen.width - pickerWidth - edge;
    }
    if (left < edge) left = edge;

    double top = anchor.dy - pickerHeight - gap;
    if (top < edge) {
      top = anchor.dy + anchorSize.height + gap;
    }

    _overlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: theme.elevatedShadow,
                  border: Border.all(color: theme.border, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: kFeedReactions.map((r) {
                    return _ReactionEmoji(
                      reaction: r,
                      onTap: () {
                        _removeOverlay();
                        widget.onChanged(
                            r.type == widget.currentReaction ? null : r.type);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _onTap() {
    if (widget.currentReaction != null) {
      widget.onChanged(null);
    } else {
      widget.onChanged('like');
    }
  }

  Widget _reactionLeading(OneUITheme theme, FeedReaction? active, {required double size}) {
    if (active != null && active.type != 'like') {
      return Text(active.emoji, style: TextStyle(fontSize: size));
    }
    return FeedIcon(
      asset: FeedIconAssets.like,
      size: size,
      color: active?.color ?? theme.textSecondary,
    );
  }

  Widget _animatedLeading(OneUITheme theme, FeedReaction? active, double size) {
    final leading = _reactionLeading(theme, active, size: size);
    if (!FeedMotion.enabled(context)) return leading;

    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.currentReaction ?? 'none'),
      tween: Tween(begin: 0.88, end: 1.0),
      duration: FeedMotion.entrance,
      curve: FeedMotion.curve,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: leading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final active = reactionByType(widget.currentReaction);

    return Material(
      key: _anchorKey,
      color: Colors.transparent,
      child: FeedPressScale(
        onTap: _onTap,
        onLongPress: _showPicker,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: widget.iconOnly
              ? _animatedLeading(theme, active, 20)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _animatedLeading(theme, active, 18),
                    const SizedBox(height: 2),
                    Text(
                      active?.label ?? 'Like',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: active?.color ?? theme.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Standard reaction slot for feed action rows (post, poll, blog, case).
class FeedReactionAction extends StatelessWidget {
  final String? currentReaction;
  final ValueChanged<String?> onChanged;

  const FeedReactionAction({
    super.key,
    required this.currentReaction,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: ReactionButton(
          currentReaction: currentReaction,
          onChanged: onChanged,
          iconOnly: false,
        ),
      ),
    );
  }
}

class _ReactionEmoji extends StatefulWidget {
  final FeedReaction reaction;
  final VoidCallback onTap;
  const _ReactionEmoji({required this.reaction, required this.onTap});

  @override
  State<_ReactionEmoji> createState() => _ReactionEmojiState();
}

class _ReactionEmojiState extends State<_ReactionEmoji> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedScale(
          scale: _hover ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Tooltip(
            message: widget.reaction.label,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(widget.reaction.emoji,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
        ),
      ),
    );
  }
}
