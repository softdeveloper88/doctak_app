import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/doctak_palette.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Design tokens matching the DocTak mobile comments reference
/// (`dt-comments` / `dt-modal__comments` in _home-feed.scss).
class CommentSheetTokens {
  CommentSheetTokens._();

  static const double horizontalPadding = 16;
  static const double bubbleRadius = 12;
  /// Cream fill — matches web comment bubbles / `--dt-surface-soft` tone.
  static const Color bubbleBackground = DoctakPalette.inputFill;
  static const Color bubbleBorder = DoctakPalette.border;
  static const Color metaText = DoctakPalette.textSoft;
  static const Color threadLine = DoctakPalette.border;

  static BoxDecoration bubbleDecoration({required bool isDark}) {
    if (isDark) {
      return BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(bubbleRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      );
    }
    return BoxDecoration(
      color: bubbleBackground,
      borderRadius: BorderRadius.circular(bubbleRadius),
      border: Border.all(color: bubbleBorder, width: 1),
    );
  }

  static BoxDecoration inputDecoration({required bool isDark}) {
    if (isDark) {
      return BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      );
    }
    return BoxDecoration(
      color: bubbleBackground,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: bubbleBorder, width: 1),
    );
  }

  // Typography
  static const double titleSize = 16;
  static const double countBadgeSize = 11;
  static const double authorSize = 12;
  static const double bodySize = 13;
  static const double metaSize = 11;
  static const double actionSize = 12;
  static const double linkSize = 12;
  static const double inputSize = 13;

  // Avatars (dt-avatar sm / xs)
  static const double avatarMain = 32;
  static const double avatarReply = 26;
  static const double avatarComposer = 32;

  static const List<Color> avatarPalette = [
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFFEA580C),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFF059669),
  ];
}

/// Bottom inset so the composer clears the system home indicator / nav bar.
double commentComposerBottomPadding(BuildContext context) {
  final mq = MediaQuery.of(context);
  // Keyboard lift is handled by the modal sheet wrapper; keep composer padding small.
  if (mq.viewInsets.bottom > 0) {
    return 10;
  }
  final safeBottom = mq.viewPadding.bottom > mq.padding.bottom
      ? mq.viewPadding.bottom
      : mq.padding.bottom;
  return safeBottom + 12;
}

Color commentAvatarColor(String seed) {
  if (seed.trim().isEmpty) return CommentSheetTokens.avatarPalette.first;
  return CommentSheetTokens
      .avatarPalette[seed.hashCode.abs() % CommentSheetTokens.avatarPalette.length];
}

String commentShortRelativeTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return '';
  final diff = DateTime.now().difference(parsed);
  if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()}w';
  if (diff.inDays >= 1) return '${diff.inDays}d';
  if (diff.inHours >= 1) return '${diff.inHours}h';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
  return 'now';
}

String commentDisplayName({String? firstName, String? lastName, String? fallbackName}) {
  final combined = '${firstName ?? ''} ${lastName ?? ''}'.trim();
  if (combined.isNotEmpty) return combined;
  final fb = (fallbackName ?? '').trim();
  return fb.isNotEmpty ? fb : 'Member';
}

String commentProfileImageUrl(String? raw) {
  final resolved = AppData.fullImageUrl(raw);
  return resolved.trim();
}

bool commentHasProfileImage(String? raw) {
  final url = commentProfileImageUrl(raw);
  return url.isNotEmpty && url.toLowerCase() != 'null';
}

String commentInitials({String? firstName, String? lastName, String? fallbackName}) {
  final name = commentDisplayName(
    firstName: firstName,
    lastName: lastName,
    fallbackName: fallbackName,
  );
  final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'D';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

/// Grab handle at top of the comments sheet.
class CommentSheetDragHandle extends StatelessWidget {
  const CommentSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: CommentSheetTokens.threadLine,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Header row: Comments title, count badge, close button.
class CommentSheetHeader extends StatelessWidget {
  final int count;
  final VoidCallback? onClose;

  const CommentSheetHeader({
    super.key,
    required this.count,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CommentSheetTokens.horizontalPadding,
        4,
        CommentSheetTokens.horizontalPadding,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                translation(context).lbl_comments,
                style: theme.titleSmall.copyWith(
                  fontSize: CommentSheetTokens.titleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.16,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: CommentSheetTokens.bubbleBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: CommentSheetTokens.countBadgeSize,
                      fontWeight: FontWeight.w600,
                      color: CommentSheetTokens.metaText,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Material(
                color: CommentSheetTokens.bubbleBackground,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClose ?? () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF636366)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: CommentSheetTokens.threadLine),
        ],
      ),
    );
  }
}

/// Circular avatar — loads profile photo when available, initials fallback otherwise.
class CommentSheetAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;
  final bool isPremium;

  const CommentSheetAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = CommentSheetTokens.avatarMain,
    this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = commentAvatarColor(name);
    final initials = commentInitials(fallbackName: name);
    final fontSize = size * 0.34;
    final hasImage = commentHasProfileImage(imageUrl);
    final resolvedUrl = commentProfileImageUrl(imageUrl);

    Widget initialsFallback() => Center(
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              fontFamily: 'Poppins',
            ),
          ),
        );

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isPremium
            ? Border.all(color: const Color(0xFFE6B422), width: 2)
            : null,
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFFE6B422).withValues(alpha: 0.45),
                  blurRadius: 0,
                  spreadRadius: 1.5,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? AppCachedNetworkImage(
              imageUrl: resolvedUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => initialsFallback(),
              errorWidget: (_, __, ___) => initialsFallback(),
            )
          : initialsFallback(),
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}

/// Light-gray comment bubble with author row + body.
class CommentSheetBubble extends StatelessWidget {
  final String name;
  final String body;
  final String? specialty;
  final bool verified;
  final bool isPremium;
  final OneUITheme theme;

  const CommentSheetBubble({
    super.key,
    required this.name,
    required this.body,
    this.specialty,
    this.verified = false,
    this.isPremium = false,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: CommentSheetTokens.bubbleDecoration(isDark: theme.isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: CommentSheetTokens.authorSize,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 4),
                      theme.buildVerifiedBadge(size: 12, isPremium: isPremium),
                    ],
                  ],
                ),
              ),
              if (specialty != null && specialty!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    specialty!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: CommentSheetTokens.metaSize,
                      fontWeight: FontWeight.w400,
                      color: CommentSheetTokens.metaText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: CommentSheetTokens.bodySize,
              fontWeight: FontWeight.w400,
              color: theme.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Meta row below bubble: time · like · reply · menu.
class CommentSheetActionRow extends StatelessWidget {
  final String timeLabel;
  final bool liked;
  final int likeCount;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final Widget? trailingMenu;
  final OneUITheme theme;

  const CommentSheetActionRow({
    super.key,
    required this.timeLabel,
    required this.liked,
    required this.likeCount,
    this.onLike,
    this.onReply,
    this.trailingMenu,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final likeColor = liked ? const Color(0xFFFF3B30) : CommentSheetTokens.metaText;

    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 6),
      child: Row(
        children: [
          Text(
            timeLabel,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: CommentSheetTokens.metaSize,
              fontWeight: FontWeight.w400,
              color: CommentSheetTokens.metaText,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onLike,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 14,
                  color: likeColor,
                ),
                if (likeCount > 0) ...[
                  const SizedBox(width: 3),
                  Text(
                    '$likeCount',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: CommentSheetTokens.actionSize,
                      fontWeight: FontWeight.w600,
                      color: likeColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (onReply != null)
            GestureDetector(
              onTap: onReply,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.reply_rounded,
                    size: 14,
                    color: CommentSheetTokens.metaText,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Reply',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: CommentSheetTokens.actionSize,
                      fontWeight: FontWeight.w600,
                      color: CommentSheetTokens.metaText,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          if (trailingMenu != null) trailingMenu!,
        ],
      ),
    );
  }
}

/// Orange "View N more replies" affordance.
class CommentViewRepliesLink extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final bool hide;

  const CommentViewRepliesLink({
    super.key,
    required this.count,
    required this.onTap,
    this.hide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final label = hide
        ? 'Hide replies'
        : (count == 1 ? 'View 1 more reply' : 'View $count more replies');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 1,
              color: CommentSheetTokens.threadLine,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: CommentSheetTokens.linkSize,
                fontWeight: FontWeight.w500,
                color: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical thread connector for nested replies.
class CommentThreadLine extends StatelessWidget {
  final double height;

  const CommentThreadLine({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: height,
      margin: const EdgeInsets.only(left: 19, top: 4),
      decoration: BoxDecoration(
        color: CommentSheetTokens.threadLine,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// Bottom composer: avatar + pill input + orange send.
class CommentSheetComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;
  final String? hint;
  final bool showAvatar;

  const CommentSheetComposer({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onSend,
    this.hint,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottom = commentComposerBottomPadding(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(
          top: BorderSide(
            color: theme.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : CommentSheetTokens.threadLine,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        CommentSheetTokens.horizontalPadding,
        10,
        CommentSheetTokens.horizontalPadding,
        bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar) ...[
            Builder(
              builder: (context) {
                // When acting as a business page, comments are attributed to
                // the page — show its logo instead of the personal avatar.
                final org = ActingContextService.instance.organization;
                if (org != null) {
                  final logo = (org.logoUrl != null && org.logoUrl!.isNotEmpty)
                      ? AppData.fullImageUrl(org.logoUrl!)
                      : '';
                  return CommentSheetAvatar(
                    name: org.name,
                    imageUrl: logo.isNotEmpty ? logo : null,
                    size: CommentSheetTokens.avatarComposer,
                  );
                }
                return ValueListenableBuilder<String>(
                  valueListenable: AppData.profilePicNotifier,
                  builder: (_, picUrl, __) {
                    final url =
                        picUrl.isNotEmpty ? picUrl : AppData.profilePicUrl;
                    return CommentSheetAvatar(
                      name: AppData.name.isNotEmpty ? AppData.name : 'You',
                      imageUrl: url.isNotEmpty ? url : null,
                      size: CommentSheetTokens.avatarComposer,
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 36, maxHeight: 96),
              padding: const EdgeInsets.only(left: 14, right: 4),
              decoration: CommentSheetTokens.inputDecoration(isDark: theme.isDark),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: hint ?? 'Add a comment…',
                        hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: CommentSheetTokens.inputSize,
                          fontWeight: FontWeight.w400,
                          color: CommentSheetTokens.metaText,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: CommentSheetTokens.inputSize,
                        color: theme.textPrimary,
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 4),
                    child: Material(
                      color: theme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onSend,
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
