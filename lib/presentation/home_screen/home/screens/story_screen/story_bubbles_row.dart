import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/data/models/story_model/story_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/bloc/story_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_icons.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/story_viewer_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/create_story_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Horizontal row of story bubbles at the top of the home feed
/// Shows "Your Story" button + stories from connected/following users
class StoryBubblesRow extends StatefulWidget {
  final Listenable? refreshListenable;

  const StoryBubblesRow({super.key, this.refreshListenable});

  @override
  State<StoryBubblesRow> createState() => _StoryBubblesRowState();
}

class _StoryBubblesRowState extends State<StoryBubblesRow> {
  late StoryBloc _storyBloc;

  @override
  void initState() {
    super.initState();
    _storyBloc = StoryBloc()..add(const LoadStoryFeedEvent());
    widget.refreshListenable?.addListener(_reloadStories);
  }

  @override
  void didUpdateWidget(StoryBubblesRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable?.removeListener(_reloadStories);
      widget.refreshListenable?.addListener(_reloadStories);
    }
  }

  void _reloadStories() {
    if (mounted) _storyBloc.add(const LoadStoryFeedEvent());
  }

  @override
  void dispose() {
    widget.refreshListenable?.removeListener(_reloadStories);
    _storyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocConsumer<StoryBloc, StoryState>(
      bloc: _storyBloc,
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          (previous is StoryFeedLoadedState &&
              current is StoryFeedLoadedState &&
              previous.storyGroups.length != current.storyGroups.length),
      listener: (context, state) {
        if (state is StoryCreatedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.primary,
            ),
          );
        }
      },
      builder: (context, state) {
        final hasStories = _storyBloc.storyGroups.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            border: Border(bottom: BorderSide(color: theme.divider)),
          ),
          child: SizedBox(
            height: 118,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              primary: false,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              cacheExtent: 200,
              addRepaintBoundaries: true,
              itemCount: (hasStories ? _storyBloc.storyGroups.length : 0) + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAddStoryBubble(context, theme);
                }

                final adjustedIndex = index - 1;
                if (adjustedIndex >= _storyBloc.storyGroups.length) {
                  return const SizedBox.shrink();
                }

                final group = _storyBloc.storyGroups[adjustedIndex];
                return _buildStoryBubble(context, theme, group, adjustedIndex);
              },
            ),
          ),
        );
      },
    );
  }

  /// "Your Story" bubble with + icon
  Widget _buildAddStoryBubble(BuildContext context, OneUITheme theme) {
    // Check if current user has active stories
    StoryGroupModel? myStoryGroup;
    for (final group in _storyBloc.storyGroups) {
      if (group.userId == AppData.logInUserId) {
        myStoryGroup = group;
        break;
      }
    }

    return GestureDetector(
      onTap: () {
        if (myStoryGroup != null && myStoryGroup.stories.isNotEmpty) {
          _showMyStoryOptions(context, myStoryGroup);
        } else {
          _openCreateStory(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile pic with + badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.accentSoft,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                    color: theme.surfaceVariant,
                  ),
                  child: Center(
                    child: FeedIcon(
                      asset: FeedIconAssets.storyPhoto,
                      size: 26,
                      color: theme.primary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.cardBackground, width: 2.5),
                    ),
                    child: Center(
                      child: FeedIcon(
                        asset: FeedIconAssets.storyPlus,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 66,
              child: Text(
                'Your Story',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Story bubble for a specific user
  Widget _buildStoryBubble(
    BuildContext context,
    OneUITheme theme,
    StoryGroupModel group,
    int groupIndex,
  ) {
    // Skip own stories (we show them in "Your Story")
    if (group.userId == AppData.logInUserId) {
      return const SizedBox.shrink();
    }

    final bool hasUnviewed = group.hasUnviewed;

    return GestureDetector(
      onTap: () => _openStoryViewer(context, group),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with accent ring if unviewed (avoid SweepGradient — costly while scrolling)
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasUnviewed ? theme.primary : theme.divider,
                  width: hasUnviewed ? 2.5 : 2,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.cardBackground,
                ),
                padding: const EdgeInsets.all(2.5),
                child: ClipOval(
                  child: group.user.profilePicUrl.isNotEmpty
                      ? AppCachedNetworkImage(
                          imageUrl: group.user.profilePicUrl,
                          height: 52,
                          width: 52,
                          fit: BoxFit.cover,
                          memCacheWidth: 104,
                          memCacheHeight: 104,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          filterQuality: FilterQuality.low,
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: theme.surfaceVariant,
                          alignment: Alignment.center,
                          child: Text(
                            group.user.fullName.isNotEmpty
                                ? group.user.fullName[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 66,
              child: Text(
                group.user.fullName.isNotEmpty
                    ? group.user.fullName.split(' ').first
                    : 'User',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: hasUnviewed ? FontWeight.w600 : FontWeight.w500,
                  color: hasUnviewed ? theme.textPrimary : theme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyStoryOptions(BuildContext context, StoryGroupModel myGroup) {
    final theme = OneUITheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.visibility, color: theme.primary),
                  title: Text(
                    'View My Stories (${myGroup.storyCount})',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: theme.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openStoryViewer(context, myGroup, showAddOption: true);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.add_circle_outline, color: theme.primary),
                  title: Text(
                    'Add New Story',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: theme.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openCreateStory(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openStoryViewer(
    BuildContext context,
    StoryGroupModel group, {
    bool showAddOption = false,
  }) {
    final viewableGroups = _storyBloc.storyGroups
        .where(
          (storyGroup) =>
              (storyGroup.userId != AppData.logInUserId || showAddOption) &&
              storyGroup.stories.isNotEmpty,
        )
        .toList();

    if (viewableGroups.isEmpty) {
      return;
    }

    final initialGroupIndex = viewableGroups.indexWhere(
      (storyGroup) => storyGroup.userId == group.userId,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewerScreen(
            storyGroups: viewableGroups,
            initialGroupIndex: initialGroupIndex >= 0 ? initialGroupIndex : 0,
            storyBloc: _storyBloc,
            currentGroup: group,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _openCreateStory(BuildContext context) async {
    await AppNavigator.push(
      context,
      CreateStoryScreen(storyBloc: _storyBloc),
    );
    // Refresh the feed after returning from story creation
    if (mounted) {
      _storyBloc.add(const LoadStoryFeedEvent());
    }
  }
}
