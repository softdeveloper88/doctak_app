import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/case_discussion_models.dart';

/// Full case header for the detail screen.
/// Displays author info, full title, description, attachments gallery,
/// metadata (specialty, country, complexity, teaching value, patient demographics),
/// and action buttons (like/bookmark/follow/share).
class DiscussionHeader extends StatelessWidget {
  final CaseDiscussion discussion;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onFollow;
  final VoidCallback onShare;
  final VoidCallback? onEdit;

  const DiscussionHeader({
    super.key,
    required this.discussion,
    required this.onLike,
    required this.onBookmark,
    required this.onFollow,
    required this.onShare,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final tags = discussion.parsedTags;
    final imageAttachments = discussion.attachments
        .where((a) => a.type == 'image')
        .toList();
    final fileAttachments = discussion.attachments
        .where((a) => a.type != 'image')
        .toList();

    return Container(
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author Info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
            child: Row(
              children: [
                _AuthorAvatar(
                  author: discussion.author,
                  theme: theme,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discussion.author.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildAuthorSubtitle(),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: theme.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (discussion.isOwner && onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 20, color: theme.textSecondary),
                    onPressed: onEdit,
                    tooltip: 'Edit case',
                  ),
              ],
            ),
          ),

          // ── Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              discussion.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: theme.textPrimary,
                height: 1.35,
              ),
            ),
          ),

          // ── Tags ──
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        color: theme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Description ──
          if (discussion.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SelectableText(
                discussion.description,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
                  height: 1.6,
                ),
              ),
            ),

          // ── Image Gallery ──
          if (imageAttachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _ImageGallery(
                images: imageAttachments,
                theme: theme,
              ),
            ),

          // ── File Attachments ──
          if (fileAttachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: fileAttachments.map((file) {
                  return _FileAttachment(file: file, theme: theme);
                }).toList(),
              ),
            ),

          // ── Metadata Row ──
          if (_hasMetadata())
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _MetadataSection(
                discussion: discussion,
                theme: theme,
              ),
            ),

          const SizedBox(height: 14),

          // ── Stats Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _StatsRow(discussion: discussion, theme: theme),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: theme.divider),

          // ── Action Buttons Row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                _ActionButton(
                  icon: discussion.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: 'Like',
                  color: discussion.isLiked
                      ? theme.likeColor
                      : theme.textSecondary,
                  onTap: onLike,
                ),
                _ActionButton(
                  icon: discussion.isBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  label: 'Save',
                  color: discussion.isBookmarked
                      ? theme.primary
                      : theme.textSecondary,
                  onTap: onBookmark,
                ),
                _ActionButton(
                  icon: discussion.isFollowing
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  label: discussion.isFollowing ? 'Following' : 'Follow',
                  color: discussion.isFollowing
                      ? theme.primary
                      : theme.textSecondary,
                  onTap: onFollow,
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: theme.textSecondary,
                  onTap: onShare,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: theme.divider),
        ],
      ),
    );
  }

  String _buildAuthorSubtitle() {
    final parts = <String>[];
    if (discussion.author.specialty.isNotEmpty) {
      parts.add(discussion.author.specialty);
    }
    parts.add(timeago.format(discussion.createdAt));
    return parts.join(' · ');
  }

  bool _hasMetadata() {
    return discussion.specialty != null ||
        discussion.countryName != null ||
        discussion.metadata != null;
  }
}

// ── Author Avatar ──

class _AuthorAvatar extends StatelessWidget {
  final CaseAuthor author;
  final OneUITheme theme;
  final double size;

  const _AuthorAvatar({
    required this.author,
    required this.theme,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        author.profilePic != null && author.profilePic!.isNotEmpty;
    final initials = author.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.avatarBackground,
        border: Border.all(color: theme.avatarBorder, width: 1),
      ),
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: author.profilePic!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.35,
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
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w600,
                  color: theme.avatarText,
                ),
              ),
            ),
    );
  }
}

// ── Image Gallery ──

class _ImageGallery extends StatelessWidget {
  final List<CaseAttachment> images;
  final OneUITheme theme;

  const _ImageGallery({required this.images, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _showFullImage(context, images.first.url),
          child: CachedNetworkImage(
            imageUrl: images.first.url,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 220,
              color: theme.surfaceVariant,
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: theme.primary),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 220,
              color: theme.surfaceVariant,
              child:
                  Icon(Icons.image_not_supported, color: theme.textTertiary),
            ),
          ),
        ),
      );
    }

    // Grid for multiple images
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.4,
      ),
      itemCount: images.length > 4 ? 4 : images.length,
      itemBuilder: (context, index) {
        final isLast = index == 3 && images.length > 4;
        return GestureDetector(
          onTap: () => _showFullImage(context, images[index].url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: images[index].url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: theme.surfaceVariant),
                  errorWidget: (_, __, ___) => Container(
                    color: theme.surfaceVariant,
                    child: Icon(Icons.broken_image,
                        color: theme.textTertiary, size: 20),
                  ),
                ),
                if (isLast)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Text(
                        '+${images.length - 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _FullImageViewer(url: url),
    ));
  }
}

class _FullImageViewer extends StatelessWidget {
  final String url;
  const _FullImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.error, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}

// ── File Attachment ──

class _FileAttachment extends StatelessWidget {
  final CaseAttachment file;
  final OneUITheme theme;

  const _FileAttachment({required this.file, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(_getFileIcon(), size: 22, color: theme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.description.isNotEmpty ? file.description : 'Attachment',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.download_outlined,
              size: 20, color: theme.textSecondary),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    final ext = file.description.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.attach_file;
    }
  }
}

// ── Metadata Section ──

class _MetadataSection extends StatelessWidget {
  final CaseDiscussion discussion;
  final OneUITheme theme;

  const _MetadataSection({
    required this.discussion,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_MetadataItem>[];

    if (discussion.specialty != null) {
      items.add(_MetadataItem(
        icon: Icons.medical_services_outlined,
        label: 'Specialty',
        value: discussion.specialty!,
      ));
    }
    if (discussion.countryName != null) {
      items.add(_MetadataItem(
        icon: Icons.public,
        label: 'Country',
        value: discussion.countryName!,
      ));
    }
    if (discussion.metadata != null) {
      final meta = discussion.metadata!;
      final demographics = meta.parsedDemographics;
      if (demographics != null) {
        if (demographics['age'] != null) {
          items.add(_MetadataItem(
            icon: Icons.person_outline,
            label: 'Patient',
            value:
                '${demographics['age']} yr, ${demographics['gender'] ?? ''}',
          ));
        }
      }
      if (meta.clinicalComplexity != null) {
        items.add(_MetadataItem(
          icon: Icons.signal_cellular_alt,
          label: 'Complexity',
          value: meta.clinicalComplexity!,
        ));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 15, color: theme.textTertiary),
            const SizedBox(width: 4),
            Text(
              '${item.label}: ',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: theme.textTertiary,
              ),
            ),
            Flexible(
              child: Text(
                item.value,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _MetadataItem {
  final IconData icon;
  final String label;
  final String value;
  const _MetadataItem(
      {required this.icon, required this.label, required this.value});
}

// ── Stats Row ──

class _StatsRow extends StatelessWidget {
  final CaseDiscussion discussion;
  final OneUITheme theme;

  const _StatsRow({required this.discussion, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (discussion.likes > 0) ...[
          Text(
            '${discussion.likes} ${discussion.likes == 1 ? 'like' : 'likes'}',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: theme.textTertiary,
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (discussion.commentsCount > 0) ...[
          Text(
            '${discussion.commentsCount} ${discussion.commentsCount == 1 ? 'comment' : 'comments'}',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: theme.textTertiary,
            ),
          ),
          const SizedBox(width: 16),
        ],
        Text(
          '${discussion.views} ${discussion.views == 1 ? 'view' : 'views'}',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: theme.textTertiary,
          ),
        ),
        const Spacer(),
        if (discussion.followersCount > 0)
          Text(
            '${discussion.followersCount} followers',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: theme.textTertiary,
            ),
          ),
      ],
    );
  }
}

// ── Action Button ──

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 5),
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
