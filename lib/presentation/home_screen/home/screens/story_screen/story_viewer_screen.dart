import 'package:doctak_app/data/models/story_model/story_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/bloc/story_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/create_story_screen.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

/// Full-screen story viewer with progress bars, swipe gestures, tap navigation
class StoryViewerScreen extends StatefulWidget {
  final List<StoryGroupModel> storyGroups;
  final int initialGroupIndex;
  final StoryBloc storyBloc;
  final StoryGroupModel currentGroup;

  const StoryViewerScreen({
    super.key,
    required this.storyGroups,
    required this.initialGroupIndex,
    required this.storyBloc,
    required this.currentGroup,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentGroupIndex;
  int _currentStoryIndex = 0;
  AnimationController? _progressController;
  VideoPlayerController? _videoController;
  bool _isPaused = false;

  /// Duration per story segment (5 seconds for images/text, video length for video)
  static const Duration _defaultDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex.clamp(
      0,
      widget.storyGroups.length - 1,
    );
    _pageController = PageController(initialPage: _currentGroupIndex);

    // Immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _loadStory();
  }

  @override
  void dispose() {
    _progressController?.dispose();
    _videoController?.dispose();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  StoryGroupModel get _currentGroup => widget.storyGroups[_currentGroupIndex];

  StoryItemModel get _currentStory =>
      _currentGroup.stories[_currentStoryIndex];

  void _loadStory() {
    _progressController?.dispose();
    _videoController?.dispose();
    _videoController = null;

    final story = _currentStory;

    // Mark as viewed
    if (!story.isOwn) {
      widget.storyBloc.add(MarkStoryViewedEvent(storyId: story.id));
    }

    if (story.type == 'video' && story.mediaUrl != null) {
      _loadVideoStory(story);
    } else {
      _startImageTimer();
    }
  }

  void _loadVideoStory(StoryItemModel story) {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(story.mediaUrl!),
    )..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController!.play();

        final duration = _videoController!.value.duration;
        _startProgress(duration);
      }).catchError((e) {
        print('🔴 Video load error: $e');
        // Fallback to default timer
        _startImageTimer();
      });
  }

  void _startImageTimer() {
    _startProgress(_defaultDuration);
  }

  void _startProgress(Duration duration) {
    _progressController = AnimationController(
      vsync: this,
      duration: duration,
    );

    _progressController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _progressController!.forward();
  }

  void _nextStory() {
    if (_currentStoryIndex < _currentGroup.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _loadStory();
    } else {
      _nextGroup();
    }
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _loadStory();
    } else {
      _prevGroup();
    }
  }

  void _nextGroup() {
    if (_currentGroupIndex < widget.storyGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory();
    } else {
      _close();
    }
  }

  void _prevGroup() {
    if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentStoryIndex = 0;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadStory();
    }
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isPaused) _pauseStory();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPaused) _resumeStory();
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 3) {
      _prevStory();
    } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
      _nextStory();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _pauseStory();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _resumeStory();
  }

  void _pauseStory() {
    _isPaused = true;
    _progressController?.stop();
    _videoController?.pause();
  }

  void _resumeStory() {
    _isPaused = false;
    _progressController?.forward();
    _videoController?.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        child: Stack(
          children: [
            // Story content
            _buildStoryContent(),

            // Progress bars at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: _buildProgressBars(),
            ),

            // User info header
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              left: 12,
              right: 12,
              child: _buildHeader(),
            ),

            // Bottom actions for own stories
            if (_currentStory.isOwn)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: _buildBottomActions(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent() {
    final story = _currentStory;

    switch (story.type) {
      case 'video':
        return _buildVideoContent(story);
      case 'image':
        return _buildImageContent(story);
      case 'text':
      default:
        return _buildTextContent(story);
    }
  }

  Widget _buildImageContent(StoryItemModel story) {
    if (story.mediaUrl == null || story.mediaUrl!.isEmpty) {
      return _buildTextContent(story);
    }

    return Center(
      child: AppCachedNetworkImage(
        imageUrl: story.mediaUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildVideoContent(StoryItemModel story) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildTextContent(StoryItemModel story) {
    Color bgColor;
    try {
      final hex = story.backgroundColor.replaceAll('#', '');
      bgColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      bgColor = Colors.blue;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            story.content ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              height: 1.5,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Row(
      children: List.generate(
        _currentGroup.stories.length,
        (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: index == _currentStoryIndex
                    ? AnimatedBuilder(
                        animation: _progressController ??
                            AlwaysStoppedAnimation(0.0),
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressController?.value ?? 0.0,
                            backgroundColor: Colors.white30,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          );
                        },
                      )
                    : LinearProgressIndicator(
                        value: index < _currentStoryIndex ? 1.0 : 0.0,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final user = _currentGroup.user;
    final story = _currentStory;

    return Row(
      children: [
        // Avatar
        ClipOval(
          child: user.profilePicUrl.isNotEmpty
              ? AppCachedNetworkImage(
                  imageUrl: user.profilePicUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 36,
                  height: 36,
                  color: Colors.grey[700],
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        // Name + time ago
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Text(
                story.timeAgo,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        // Close button
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: _close,
        ),
        // More options for own stories
        if (story.isOwn)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey[900],
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(story.id);
              } else if (value == 'viewers') {
                _showViewers(story.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'viewers',
                child: Row(
                  children: [
                    Icon(Icons.visibility, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text('View Seen By',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Delete Story',
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // View count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                '${_currentStory.viewCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        // Add new story button
        GestureDetector(
          onTap: () {
            _close();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateStoryScreen(storyBloc: widget.storyBloc),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Add Story',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(int storyId) {
    _pauseStory();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resumeStory();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.storyBloc.add(DeleteStoryEvent(storyId: storyId));
              _close();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showViewers(int storyId) {
    _pauseStory();
    widget.storyBloc.add(LoadStoryViewersEvent(storyId: storyId));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return BlocBuilder<StoryBloc, StoryState>(
          bloc: widget.storyBloc,
          builder: (context, state) {
            if (state is StoryViewersLoadedState) {
              return Container(
                padding: const EdgeInsets.all(16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Seen by ${state.totalViews}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: state.viewers.isEmpty
                          ? const Center(
                              child: Text(
                                'No one has seen this story yet',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: state.viewers.length,
                              itemBuilder: (context, index) {
                                final viewer = state.viewers[index];
                                return ListTile(
                                  leading: ClipOval(
                                    child: viewer.profilePic.isNotEmpty
                                        ? AppCachedNetworkImage(
                                            imageUrl: viewer.profilePic,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 40,
                                            height: 40,
                                            color: Colors.grey[700],
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    viewer.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  subtitle: Text(
                                    viewer.viewedAt,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _resumeStory();
    });
  }
}
