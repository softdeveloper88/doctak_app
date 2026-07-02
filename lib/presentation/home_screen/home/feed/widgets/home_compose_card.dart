import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/compose_content_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_icons.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

/// Top "create" card matching the DocTak Mobile reference composer.
/// Pass [groupTarget] to post/poll/blog as a group (same screen as home feed).
class HomeComposeCard extends StatelessWidget {
  final VoidCallback onComposed;
  final ComposeGroupTarget? groupTarget;

  const HomeComposeCard({
    super.key,
    required this.onComposed,
    this.groupTarget,
  });

  Future<void> _openComposer(BuildContext context, ComposeTab tab) async {
    if (groupTarget != null && tab == ComposeTab.poll && !groupTarget!.enablePolls) {
      return;
    }
    await AppNavigator.push(
      context,
      ComposeContentScreen(
        initialTab: tab,
        groupTarget: groupTarget,
        onPosted: onComposed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isGroup = groupTarget != null;
    final pollDisabled = isGroup && !groupTarget!.enablePolls;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        kFeedHorizontalGutter,
        10,
        kFeedHorizontalGutter,
        10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: theme.feedCardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              if (isGroup) _groupAvatar(theme) else _avatar(theme),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openComposer(context, ComposeTab.update),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: theme.border),
                    ),
                    child: Text(
                      isGroup
                          ? 'Post to ${groupTarget!.groupName}…'
                          : 'Share a case, update, or question…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySecondary.copyWith(fontSize: 14.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Divider(height: 1, color: theme.divider),
          ),
          Row(
            children: [
              _action(
                theme,
                asset: FeedIconAssets.composePost,
                label: 'Post',
                color: theme.composePostColor,
                onTap: () => _openComposer(context, ComposeTab.update),
              ),
              _action(
                theme,
                asset: FeedIconAssets.composePoll,
                label: 'Poll',
                color: theme.composePollColor,
                disabled: pollDisabled,
                onTap: pollDisabled
                    ? null
                    : () => _openComposer(context, ComposeTab.poll),
              ),
              _action(
                theme,
                asset: FeedIconAssets.composeBlog,
                label: 'Blog',
                color: theme.composeBlogColor,
                onTap: () => _openComposer(context, ComposeTab.blog),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupAvatar(OneUITheme theme) {
    final logoUrl = AppData.fullImageUrl(groupTarget!.groupLogo);
    return FeedOverlapAvatar(
      primaryName: AppData.name.isNotEmpty ? AppData.name : 'You',
      primaryAvatarUrl:
          AppData.profilePicUrl.isEmpty ? null : AppData.profilePicUrl,
      secondaryName: groupTarget!.groupName,
      secondaryAvatarUrl: logoUrl.isEmpty ? null : logoUrl,
      size: 42,
    );
  }

  Widget _avatar(OneUITheme theme) {
    final initials = AppData.name.isNotEmpty
        ? AppData.name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join()
        : 'AK';
    return ValueListenableBuilder<String>(
      valueListenable: AppData.profilePicNotifier,
      builder: (_, picUrl, __) {
        final url = picUrl.isNotEmpty ? picUrl : AppData.profilePicUrl;
        final fallback = Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B46C1), Color(0xFF4C1D95)],
            ),
          ),
          child: Text(
            initials.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              fontFamily: 'Poppins',
            ),
          ),
        );
        if (url.isEmpty) return fallback;
        return ClipOval(
          child: AppCachedNetworkImage(
            imageUrl: url,
            width: 42,
            height: 42,
            fit: BoxFit.cover,
            memCacheWidth: 84,
            memCacheHeight: 84,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          ),
        );
      },
    );
  }

  Widget _action(
    OneUITheme theme, {
    required String asset,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    final icon = feedMaterialIconForAsset(asset);
    final resolvedColor = disabled ? theme.textTertiary : color;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon ?? Icons.add, size: 21, color: resolvedColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.bodySecondary.copyWith(
                    fontWeight: FontWeight.w600,
                    color: disabled ? theme.textTertiary : theme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
