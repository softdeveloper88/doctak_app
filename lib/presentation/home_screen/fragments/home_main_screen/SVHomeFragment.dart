import 'dart:async';

import 'package:doctak_app/core/notification_counter_service.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/feed_video_autoplay_registry.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/components/incomplete_profile_card.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/bloc/feed_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_entries_sliver.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_realtime_service.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_new_posts_pill.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_scroll_activity.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/home_compose_card.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/story_bubbles_row.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_bloc.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_event.dart';
import 'package:doctak_app/presentation/notification_screen/notification_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_icons.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';

import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/user_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';

import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import '../../../../localization/app_localization.dart';
import '../../../notification_screen/bloc/notification_state.dart';
import 'bloc/home_bloc.dart';

class SVHomeFragment extends StatefulWidget {
  const SVHomeFragment({
    required this.homeBloc,
    required this.openDrawer,
    super.key,
  });
  final Function openDrawer;
  final HomeBloc homeBloc;

  @override
  State<SVHomeFragment> createState() => SVHomeFragmentState();
}

class SVHomeFragmentState extends State<SVHomeFragment>
    with WidgetsBindingObserver {
  var scaffoldKey = GlobalKey<ScaffoldState>();

  // HomeBloc widget.homeBloc = HomeBloc();
  final ScrollController _mainScrollController = ScrollController();
  final FeedBloc _feedBloc = FeedBloc();
  // Use static notification bloc to prevent multiple instances
  static NotificationBloc? _notificationBloc;
  NotificationBloc get notificationBloc {
    _notificationBloc ??= NotificationBloc();
    return _notificationBloc!;
  }

  // Debounce timer to prevent too many scroll events
  Timer? _scrollDebounce;
  bool _isLoadingTriggered = false;
  StreamSubscription<FeedState>? _feedStateSub;
  final ValueNotifier<int> _storyRefresh = ValueNotifier(0);
  VoidCallback? _pendingPostsListener;
  static const double _scrollAwayThreshold = 80;

  bool get _isScrolledAwayFromTop {
    if (!_mainScrollController.hasClients) return false;
    return _mainScrollController.position.pixels > _scrollAwayThreshold;
  }

  bool get _showNewPostsPill =>
      FeedRealtimeService.instance.hasPending && _isScrolledAwayFromTop;

  /// Scroll home feed to top; optionally refresh when already at top (home re-tap).
  Future<void> scrollToTop({bool refreshIfAlreadyAtTop = false}) async {
    if (FeedRealtimeService.instance.hasPending) {
      await _loadPendingNewPosts();
      return;
    }

    final atTop = !_isScrolledAwayFromTop;
    if (atTop) {
      if (refreshIfAlreadyAtTop) {
        await _refresh();
      }
      return;
    }

    if (!_mainScrollController.hasClients) return;
    await _mainScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadPendingNewPosts() async {
    if (!mounted) return;
    FeedRealtimeService.instance.clearPending();

    if (_mainScrollController.hasClients && _isScrolledAwayFromTop) {
      await _mainScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    _feedBloc.add(const FeedLoadRequested(refresh: true));
    await _feedBloc.stream.firstWhere(
      (state) => state is FeedLoaded || state is FeedEmpty || state is FeedError,
    );
    FeedRealtimeService.instance.markFeedRefreshed();
  }

  void _onPendingPostsChanged() {
    if (!mounted) return;
    if (FeedRealtimeService.instance.hasPending && !_isScrolledAwayFromTop) {
      FeedRealtimeService.instance.clearPending();
      _feedBloc.add(const FeedLoadRequested(refresh: true));
      FeedRealtimeService.instance.markFeedRefreshed();
      return;
    }
    setState(() {});
  }

  /// Handle scroll to trigger pagination when near bottom
  void _onScroll() {
    if (_isLoadingTriggered) return;
    if (!_mainScrollController.hasClients) return;

    final position = _mainScrollController.position;
    if (!position.hasContentDimensions) return;

    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;
    const threshold = 300.0;

    if (maxScroll - currentScroll <= threshold) {
      if (_feedBloc.canLoadMore) {
        _isLoadingTriggered = true;
        _scrollDebounce?.cancel();
        _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          _feedBloc.add(const FeedLoadMoreRequested());
        });
      }
    } else if (currentScroll < maxScroll - threshold - 100) {
      // Scrolled away from bottom — allow the next pagination trigger.
      _isLoadingTriggered = false;
    }

    if (FeedRealtimeService.instance.hasPending && mounted) {
      setState(() {});
    }
  }

  String? emailVerified = '';
  bool isInCompleteProfile = false;
  final ValueNotifier<bool> _showIncompleteBanner = ValueNotifier(false);

  Future<void> getSharedPreferences() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    emailVerified = await prefs.getString('email_verified_at') ?? '';
    await SpecialtyDisplay.instance.ensureLoaded();
    final rawSpecialty = await prefs.getString('specialty') ?? '';
    final specialty = SpecialtyDisplay.instance.resolve(rawSpecialty).isNotEmpty
        ? SpecialtyDisplay.instance.resolve(rawSpecialty)
        : rawSpecialty;
    String? countryName = await prefs.getString('country') ?? '';
    String? city = await prefs.getString('city') ?? '';
    isInCompleteProfile = specialty == '' || countryName == '' || city == '';
    _showIncompleteBanner.value =
        emailVerified == '' || isInCompleteProfile;
  }

  @override
  void initState() {
    super.initState();

    // Register lifecycle observer for app resume
    WidgetsBinding.instance.addObserver(this);

    // Add scroll listener for pagination
    _mainScrollController.addListener(_onScroll);
    _feedStateSub = _feedBloc.stream.listen((state) {
      if (state is FeedLoaded && !state.isPaginating) {
        _isLoadingTriggered = false;
      }
    });

    // Load the typed home feed (doctak-node /api/feed)
    _feedBloc.add(const FeedLoadRequested());

    FeedRealtimeService.instance.start();
    FeedRealtimeService.instance.onPostUpdated = (event) {
      if (!mounted) return;
      _feedBloc.add(FeedPostUpdatedEvent(
        postId: event.postId,
        body: event.body,
        title: event.title,
        preview: event.preview,
      ));
    };
    FeedRealtimeService.instance.onPostDeleted = (event) {
      if (!mounted) return;
      _feedBloc.add(FeedPostDeletedEvent(event.postId));
    };
    _pendingPostsListener = _onPendingPostsChanged;
    FeedRealtimeService.instance.pendingCount.addListener(_pendingPostsListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheFeedSvgAssets();
    });

    // Initialize real-time notification counter (UserChannel WebSocket + FCM)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        NotificationCounterService().initialize();
        notificationBloc.add(NotificationCounter());
        getSharedPreferences();
      }
    });

    // Defer ads loading to reduce initial load
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.homeBloc.add(AdsSettingEvent());
      }
    });
  }

  /// Refresh notification count when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      NotificationCounterService().refreshFromServer();
      FeedVideoAutoplayRegistry.instance.resume();
      FeedRealtimeService.instance.pollNow();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      FeedVideoAutoplayRegistry.instance.pauseAll();
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    // Cancel debounce timer
    _scrollDebounce?.cancel();
    _feedStateSub?.cancel();
    if (_pendingPostsListener != null) {
      FeedRealtimeService.instance.pendingCount
          .removeListener(_pendingPostsListener!);
      _pendingPostsListener = null;
    }
    FeedRealtimeService.instance.stop();
    _showIncompleteBanner.dispose();
    _storyRefresh.dispose();
    // Remove scroll listener
    _mainScrollController.removeListener(_onScroll);
    _mainScrollController.dispose();
    _feedBloc.close();
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    FeedRealtimeService.instance.markFeedRefreshed();
    _storyRefresh.value++;
    unawaited(getSharedPreferences());
    _feedBloc.add(const FeedLoadRequested(refresh: true));
    widget.homeBloc.add(AdsSettingEvent());
    notificationBloc.add(NotificationCounter());
    await _feedBloc.stream.firstWhere(
      (state) => state is FeedLoaded || state is FeedEmpty || state is FeedError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      // resizeToAvoidBottomInset: false,
      key: scaffoldKey,
      backgroundColor: theme.scaffoldBackground,
      appBar: _buildModernAppBar(context),
      body: BlocListener<HomeBloc, HomeState>(
        bloc: widget.homeBloc,
        listener: (context, state) {
          if (state is PostDataError) {
            if (state.errorMessage.contains('Session expired')) {
              AppSharedPreferences().clearSharedPreferencesData(context);
              const LoginScreen().launch(context, isNewTask: true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage.replaceAll('An error occurred: ', ''),
                    style: const TextStyle(color: Colors.white),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                  margin: const EdgeInsets.only(
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                ),
              );
            }
          }
        },
        child: Stack(
          children: [
            GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: theme.primary,
            backgroundColor: theme.surfaceVariant,
            strokeWidth: 2.5,
            displacement: 40,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification ||
                    notification is ScrollStartNotification) {
                  FeedScrollActivity.instance.notifyScrollActivity();
                }
                return false;
              },
              child: CustomScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              cacheExtent: 600,
              slivers: [
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: StoryBubblesRow(refreshListenable: _storyRefresh),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _showIncompleteBanner,
                  builder: (_, showIncompleteProfile, __) {
                    if (!showIncompleteProfile) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: IncompleteProfileCard(
                        emailVerified == '',
                        isInCompleteProfile,
                      ),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: HomeComposeCard(
                      onComposed: () =>
                          _feedBloc.add(const FeedLoadRequested(refresh: true)),
                    ),
                  ),
                ),
                FeedEntriesSliver(bloc: _feedBloc, homeBloc: widget.homeBloc),
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 16),
                ),
              ],
            ),
            ),
          ),
        ),
            if (_showNewPostsPill)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: FeedNewPostsPill(onTap: _loadPendingNewPosts),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final theme = OneUITheme.of(context);

    return DoctakAppBar(
      title: translation(context).lbl_home,
      showBackButton: false,
      automaticallyImplyLeading: true,
      titleColor: theme.textPrimary,
      titleFontSize: 21,
      titleFontWeight: FontWeight.w600,
      centerTitle: false,
      customLeading: IconButton(
        icon: FeedIcon(asset: FeedIconAssets.menu, size: 24, color: theme.textPrimary),
        onPressed: () {
          widget.openDrawer();
          FocusManager.instance.primaryFocus?.unfocus();
        },
      ),
      actions: [
        IconButton(
          icon: FeedIcon(asset: FeedIconAssets.search, size: 23, color: theme.textPrimary),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            AppNavigator.push(
              context,
              SearchScreen(backPress: () => Navigator.of(context).pop()),
            );
          },
        ),
        _buildNotificationButton(context, theme),
        _buildChatButton(context, theme),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context, OneUITheme theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: FeedIcon(asset: FeedIconAssets.bell, size: 23, color: theme.textPrimary),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            AppNavigator.push(
              context,
              NotificationScreen(notificationBloc),
            );
          },
        ),
        StreamBuilder<int>(
          stream: NotificationCounterService().countStream,
          initialData: NotificationCounterService().unreadCount,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            if (count <= 0) return const SizedBox.shrink();
            return Positioned(
              right: 4,
              top: 4,
              child: theme.buildBadge(count, color: theme.accent),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChatButton(BuildContext context, OneUITheme theme) {
    return IconButton(
      icon: FeedIcon(asset: FeedIconAssets.chat, size: 23, color: theme.textPrimary),
      onPressed: () {
        FocusManager.instance.primaryFocus?.unfocus();
        UserChatScreen().launch(context);
      },
    );
  }
}
