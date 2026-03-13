import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/case_discussion_models.dart';

/// Card widget for each case in the discussion list.
/// Shows author, title, tags, description preview, images, stats, and actions.
class DiscussionCard extends StatelessWidget {
  final CaseDiscussionListItem item;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback? onDelete;

  const DiscussionCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLike,
    required this.onBookmark,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final tags = item.parsedTags;
    final images = item.imageUrls;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: theme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Author Row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(
                children: [
                  _AuthorAvatar(
                    name: item.name,
                    imageUrl: item.profilePic,
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: theme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.promoted) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified,
                                  size: 14, color: theme.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _buildSubtitle(),
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            color: theme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (item.isOwner && onDelete != null)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          size: 20, color: theme.iconColor),
                      onSelected: (value) {
                        if (value == 'delete') onDelete!();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // ── Title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Tags ──
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tags.take(4).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: theme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // ── Description Preview ──
            if (item.description != null && item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  item.description!,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    color: theme.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ── Image Grid ──
            if (images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _ImageGrid(images: images, theme: theme),
              ),

            const SizedBox(height: 10),

            // ── Divider ──
            Divider(height: 1, color: theme.divider),

            // ── Action Row ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Like
                  _ActionButton(
                    icon: item.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: item.likes > 0 ? '${item.likes}' : 'Like',
                    color: item.isLiked
                        ? theme.likeColor
                        : theme.textSecondary,
                    onTap: onLike,
                  ),
                  // Comments
                  _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: item.commentsCount > 0
                        ? '${item.commentsCount}'
                        : 'Comment',
                    color: theme.textSecondary,
                    onTap: onTap,
                  ),
                  // Views
                  _ActionButton(
                    icon: Icons.visibility_outlined,
                    label: '${item.views}',
                    color: theme.textSecondary,
                    onTap: null,
                  ),
                  // Bookmark
                  _ActionButton(
                    icon: item.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: 'Save',
                    color: item.isBookmarked
                        ? theme.primary
                        : theme.textSecondary,
                    onTap: onBookmark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (item.specialty != null && item.specialty!.isNotEmpty) {
      parts.add(item.specialty!);
    }
    parts.add(timeago.format(item.createdAt));
    return parts.join(' · ');
  }
}

// ── Private Widgets ──

class _AuthorAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final OneUITheme theme;

  const _AuthorAvatar({
    required this.name,
    required this.imageUrl,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initials = name.isNotEmpty
        ? name
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.avatarBackground,
        border: Border.all(color: theme.avatarBorder, width: 1),
      ),
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.avatarText,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.avatarText,
                ),
              ),
            ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> images;
  final OneUITheme theme;

  const _ImageGrid({required this.images, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: images.first,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 180,
            color: theme.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primary,
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 180,
            color: theme.surfaceVariant,
            child: Icon(Icons.image_not_supported,
                color: theme.textTertiary),
          ),
        ),
      );
    }

    // Multiple images: show up to 3 in a row
    final displayImages = images.take(3).toList();
    final remaining = images.length - 3;

    return SizedBox(
      height: 120,
      child: Row(
        children: displayImages.asMap().entries.map((entry) {
          final isLast = entry.key == displayImages.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: isLast ? 0 : 4),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: entry.value,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: theme.surfaceVariant),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.surfaceVariant,
                        child: Icon(Icons.broken_image,
                            color: theme.textTertiary, size: 20),
                      ),
                    ),
                  ),
                  if (isLast && remaining > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            '+$remaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
