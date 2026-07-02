import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

bool feedItemIsArticle(FeedItem item) {
  final type = item.str('postType')?.toLowerCase();
  return type == 'article' || type == 'blog';
}

/// Article card copy — mirrors web `articleIntro` / `ArticlePreviewBlock` fields.
class FeedArticleDisplay {
  final String title;
  final String? intro;
  final String? coverUrl;

  const FeedArticleDisplay({
    required this.title,
    this.intro,
    this.coverUrl,
  });
}

FeedArticleDisplay resolveFeedArticleDisplay(
  FeedItem item, {
  String? Function(String raw)? resolveMediaUrl,
}) {
  final resolve = resolveMediaUrl ?? (raw) => raw;
  final title = item.str('title')?.trim();
  final excerpt = item.str('excerpt')?.trim();
  final body = item.str('body')?.trim() ?? item.str('content')?.trim();
  final coverRaw = item.str('coverImage') ?? item.str('image');
  final coverUrl = coverRaw != null && coverRaw.isNotEmpty
      ? resolve(coverRaw)
      : null;

  return FeedArticleDisplay(
    title: (title != null && title.isNotEmpty) ? title : 'Article',
    intro: (excerpt != null && excerpt.isNotEmpty)
        ? excerpt
        : (body != null && body.isNotEmpty ? body : null),
    coverUrl: coverUrl,
  );
}

/// Tap-to-read article preview row (shared by blog + group article cards).
class FeedArticlePreview extends StatelessWidget {
  final String title;
  final String? coverUrl;
  final VoidCallback onTap;

  const FeedArticlePreview({
    super.key,
    required this.title,
    this.coverUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border, width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: coverUrl != null && coverUrl!.isNotEmpty
                  ? AppCachedNetworkImage(
                      imageUrl: coverUrl!,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _coverFallback(theme),
                    )
                  : _coverFallback(theme),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Article · tap to read',
                      style: theme.caption.copyWith(color: theme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _coverFallback(OneUITheme theme) => Container(
        width: 92,
        height: 92,
        color: theme.surfaceVariant,
        child: Icon(Icons.article_outlined, color: theme.textTertiary),
      );
}

/// Intro excerpt + article preview block.
class FeedArticleContent extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onOpen;
  final String? Function(String raw)? resolveMediaUrl;

  const FeedArticleContent({
    super.key,
    required this.item,
    required this.onOpen,
    this.resolveMediaUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final display = resolveFeedArticleDisplay(
      item,
      resolveMediaUrl: resolveMediaUrl,
    );
    final intro = display.intro?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (intro != null && intro.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              intro,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.bodyMedium,
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: intro != null && intro.isNotEmpty ? 10 : 0),
          child: FeedArticlePreview(
            title: display.title,
            coverUrl: display.coverUrl,
            onTap: onOpen,
          ),
        ),
      ],
    );
  }
}
