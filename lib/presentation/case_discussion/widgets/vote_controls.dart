import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

enum VoteLayout { column, row }

/// Like / dislike control with separate counts (one choice per user).
class VoteControls extends StatelessWidget {
  final int likes;
  final int dislikes;
  final bool isUpvoted;
  final bool isDownvoted;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final VoteLayout layout;
  final double iconSize;

  const VoteControls({
    super.key,
    required this.likes,
    required this.dislikes,
    required this.isUpvoted,
    required this.isDownvoted,
    required this.onUpvote,
    required this.onDownvote,
    this.layout = VoteLayout.column,
    this.iconSize = 16,
  });

  static const _likeColor = Color(0xFF16A34A);
  static const _dislikeColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    final likeBtn = _VoteButton(
      icon: isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
      active: isUpvoted,
      activeColor: _likeColor,
      inactiveColor: theme.textTertiary,
      size: iconSize,
      onTap: onUpvote,
    );
    final dislikeBtn = _VoteButton(
      icon: isDownvoted ? Icons.thumb_down : Icons.thumb_down_outlined,
      active: isDownvoted,
      activeColor: _dislikeColor,
      inactiveColor: theme.textTertiary,
      size: iconSize,
      onTap: onDownvote,
    );

    final likeCount = _VoteCount(
      value: likes,
      active: isUpvoted,
      activeColor: _likeColor,
      defaultColor: theme.textPrimary,
      fontSize: layout == VoteLayout.column ? 14 : 13,
    );
    final dislikeCount = _VoteCount(
      value: dislikes,
      active: isDownvoted,
      activeColor: _dislikeColor,
      defaultColor: theme.textPrimary,
      fontSize: layout == VoteLayout.column ? 14 : 13,
    );

    if (layout == VoteLayout.row) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            likeBtn,
            likeCount,
            Container(
              width: 1,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: theme.divider,
            ),
            dislikeBtn,
            dislikeCount,
          ],
        ),
      );
    }

    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        border: Border(right: BorderSide(color: theme.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [likeBtn, likeCount, const SizedBox(height: 4), dislikeBtn, dislikeCount],
      ),
    );
  }
}

class _VoteCount extends StatelessWidget {
  final int value;
  final bool active;
  final Color activeColor;
  final Color defaultColor;
  final double fontSize;

  const _VoteCount({
    required this.value,
    required this.active,
    required this.activeColor,
    required this.defaultColor,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: active ? activeColor : defaultColor,
        fontFamily: 'Poppins',
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            icon,
            size: size,
            color: active ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }
}
