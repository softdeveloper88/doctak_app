import 'dart:async';

import 'package:doctak_app/core/notification_navigation.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/chat_gpt_with_image_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/network_tab_fragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_icons.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../core/utils/app/AppData.dart';
import '../../localization/app_localization.dart';
import 'fragments/add_post/SVAddPostFragment.dart';
import 'fragments/add_post/bloc/add_post_bloc.dart';
import 'fragments/home_main_screen/SVHomeFragment.dart';
import 'fragments/home_main_screen/bloc/home_bloc.dart';
import 'fragments/profile_screen/SVProfileFragment.dart';
import 'fragments/home_main_screen/post_widget/feed_video_autoplay_registry.dart';
import 'fragments/home_main_screen/post_widget/feed_video_navigator_observer.dart';
import 'home/components/SVHomeDrawerComponent.dart';

class SVDashboardScreen extends StatefulWidget {
  const SVDashboardScreen({super.key});

  @override
  State<SVDashboardScreen> createState() => _SVDashboardScreenState();
}

class _SVDashboardScreenState extends State<SVDashboardScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  final HomeBloc homeBloc = HomeBloc();
  final AddPostBloc addPostBloc = AddPostBloc();
  late final SVHomeFragment _homeFragment;
  Widget? _networkFragment;
  Widget? _profileFragment;
  late final AnimationController _animationController;

  /// Tabs are built on first visit so Network/Profile API work does not run
  /// on home startup (IndexedStack used to mount every tab immediately).
  void _ensureTabBuilt(int index) {
    switch (index) {
      case 1:
        _networkFragment ??= NetworkTabFragment(
          openDrawer: () => scaffoldKey.currentState?.openDrawer(),
        );
      case 3:
        _profileFragment ??= const SVProfileFragment();
    }
  }

  List<Widget> get _stackChildren => [
        _homeFragment,
        _networkFragment ?? const SizedBox.shrink(),
        const SizedBox.shrink(),
        _profileFragment ?? const SizedBox.shrink(),
      ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FeedVideoAutoplayRegistry.instance.resume();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      FeedVideoAutoplayRegistry.instance.pauseAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    addPostBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    setStatusBarColor(Colors.transparent);
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _homeFragment = SVHomeFragment(
      homeBloc: homeBloc,
      openDrawer: () => scaffoldKey.currentState?.openDrawer(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationNavigation.consumePendingTap());
    });
    super.initState();
  }

  void _selectTab(int index) {
    if (selectedIndex == index) return;
    pauseFeedVideosForUiChange();
    _ensureTabBuilt(index);
    setState(() => selectedIndex = index);
    _animationController.forward().then((_) => _animationController.reverse());
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _openAddPost() {
    pauseFeedVideosForUiChange(resumeNextFrame: false);
    SVAddPostFragment(
      refresh: () {
        setState(() => selectedIndex = 0);
        homeBloc.add(PostLoadPageEvent(page: 1));
      },
      addPostBloc: addPostBloc,
    ).launch(context);
    _animationController.forward().then((_) => _animationController.reverse());
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selectedIndex != 0) {
          setState(() => selectedIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: svGetScaffoldColor(),
        key: scaffoldKey,
        drawer: SVHomeDrawerComponent(),
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: _stackChildren,
              ),
            ),
            _buildModernBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBottomNavigationBar() {
    final theme = OneUITheme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: theme.navBarBackground,
        border: Border(top: BorderSide(color: theme.divider)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          6,
          6,
          6,
          bottomInset > 0 ? bottomInset + 6 : 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: isRTL
              ? _buildRTLNavigationItems()
              : _buildLTRNavigationItems(),
        ),
      ),
    );
  }

  List<Widget> _buildLTRNavigationItems() {
    return [
      _buildNavItem(
        0,
        FeedIconAssets.navHome,
        translation(context).lbl_home,
      ),
      _buildNavItem(
        1,
        FeedIconAssets.navNetwork,
        translation(context).lbl_my_network,
      ),
      _buildAddButton(),
      _buildProfileNavItem(),
      _buildAINavItem(),
    ];
  }

  List<Widget> _buildRTLNavigationItems() {
    return [
      _buildAINavItem(),
      _buildProfileNavItem(),
      _buildAddButton(),
      _buildNavItem(
        1,
        FeedIconAssets.navNetwork,
        translation(context).lbl_my_network,
      ),
      _buildNavItem(
        0,
        FeedIconAssets.navHome,
        translation(context).lbl_home,
      ),
    ];
  }

  TextStyle _navLabelStyle(OneUITheme theme, {required bool isSelected}) {
    return TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: isSelected ? theme.accentInk : theme.textTertiary,
    );
  }

  Widget _buildNavItem(
    int index,
    String svgAsset,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    final theme = OneUITheme.of(context);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeedIcon(
              asset: svgAsset,
              size: 25,
              color: isSelected ? theme.accentInk : theme.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: _navLabelStyle(theme, isSelected: isSelected),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final theme = OneUITheme.of(context);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openAddPost,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.accent.withValues(alpha: 0.22),
                    blurRadius: 6,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: FeedIcon(
                  asset: FeedIconAssets.navPost,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Keeps the + aligned with other tab icons (label row below).
            Opacity(
              opacity: 0,
              child: Text(
                ' ',
                style: _navLabelStyle(theme, isSelected: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem() {
    final isSelected = selectedIndex == 3;
    final theme = OneUITheme.of(context);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: ValueListenableBuilder<String>(
                  valueListenable: AppData.profilePicNotifier,
                  builder: (_, picUrl, __) {
                    final url = picUrl.isNotEmpty
                        ? picUrl
                        : AppData.profilePicUrl;
                    return (url.isNotEmpty && url.toLowerCase() != 'null')
                        ? AppCachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Image.asset(
                              'assets/images/person.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/images/person.png',
                            fit: BoxFit.cover,
                          );
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              translation(context).lbl_profile,
              style: _navLabelStyle(theme, isSelected: isSelected),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAINavItem() {
    final theme = OneUITheme.of(context);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          pauseFeedVideosForUiChange(resumeNextFrame: false);
          ChatGptWithImageScreen(isFromMainScreen: true).launch(context);
          _animationController.forward().then(
            (_) => _animationController.reverse(),
          );
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), Color(0xFF0D9488)],
                ),
              ),
              child: Center(
                child: FeedIcon(
                  asset: FeedIconAssets.navImages,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              translation(context).lbl_images,
              style: _navLabelStyle(theme, isSelected: false),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
