import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/story_model/story_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/bloc/story_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/story_viewer_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/create_story_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Horizontal row of story bubbles at the top of the home feed
/// Shows "Your Story" button + stories from connected/following users
class StoryBubblesRow extends StatefulWidget {
  const StoryBubblesRow({super.key});

  @override
  State<StoryBubblesRow> createState() => _StoryBubblesRowState();
}

class _StoryBubblesRowState extends State<StoryBubblesRow> {
  late StoryBloc _storyBloc;

  @override
  void initState() {
    super.initState();
    _storyBloc = StoryBloc()..add(const LoadStoryFeedEvent());
  }

  @override
  void dispose() {
    _storyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocConsumer<StoryBloc, StoryState>(
      bloc: _storyBloc,
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

        return SizedBox(
          height: 106,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: (hasStories ? _storyBloc.storyGroups.length : 0) + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // "Your Story" / Add story button
                return _buildAddStoryBubble(context, theme);
              }

              final group = _storyBloc.storyGroups[index - 1];
              return _buildStoryBubble(context, theme, group, index - 1);
            },
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
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: myStoryGroup != null
                          ? theme.primary
                          : theme.divider,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: ValueListenableBuilder<String>(
                      valueListenable: AppData.profilePicNotifier,
                      builder: (context, picUrl, _) {
                        return picUrl.isNotEmpty
                            ? AppCachedNetworkImage(
                                imageUrl: picUrl,
                                height: 56,
                                width: 56,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: theme.surfaceVariant,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 28,
                                  color: theme.textSecondary,
                                ),
                              );
                      },
                    ),
                  ),
                ),
                // + badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackground,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                'Your Story',
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
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
            // Avatar with gradient ring if unviewed
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primary,
                          theme.primary.withValues(alpha: 0.6),
                          Colors.deepPurple,
                        ],
                      )
                    : null,
                border: hasUnviewed
                    ? null
                    : Border.all(color: theme.divider, width: 2),
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.scaffoldBackground,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: group.user.profilePicUrl.isNotEmpty
                      ? AppCachedNetworkImage(
                          imageUrl: group.user.profilePicUrl,
                          height: 52,
                          width: 52,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: theme.surfaceVariant,
                          child: Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: theme.textSecondary,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                group.user.fullName.split(' ').first,
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
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryViewerScreen(
            storyGroups: _storyBloc.storyGroups
                .where((g) => g.userId != AppData.logInUserId || showAddOption)
                .toList(),
            initialGroupIndex: showAddOption
                ? 0
                : _storyBloc.storyGroups
                    .where((g) => g.userId != AppData.logInUserId)
                    .toList()
                    .indexOf(group),
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

  void _openCreateStory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateStoryScreen(storyBloc: _storyBloc),
      ),
    );
  }
}
