import 'dart:async';

import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/notification_navigation.dart';
import 'package:doctak_app/core/utils/incoming_share_service.dart';
import 'package:doctak_app/presentation/organization_profile/organization_profile_screen.dart';
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
import 'package:doctak_app/core/utils/session_manager.dart';

class SVDashboardScreen extends StatefulWidget {
  const SVDashboardScreen({super.key});

  @override
  State<SVDashboardScreen> createState() => _SVDashboardScreenState();
}

class _SVDashboardScreenState extends State<SVDashboardScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const double _kNavIconSize = 25;
  static const double _kNavIconBandHeight = 28;
  static const double _kNavLabelSpacing = 4;
  static const double _kNavLabelRowHeight = 14;
  static const double _kNavItemContentHeight =
      _kNavIconBandHeight + _kNavLabelSpacing + _kNavLabelRowHeight;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  final HomeBloc homeBloc = HomeBloc();
  final AddPostBloc addPostBloc = AddPostBloc();
  late final SVHomeFragment _homeFragment;
  final GlobalKey<SVHomeFragmentState> _homeFragmentKey =
      GlobalKey<SVHomeFragmentState>();
  Widget? _networkFragment;
  Widget? _profileFragment;
  late final AnimationController _animationController;

  /// Organization the profile tab was built for ('' → personal profile).
  String _profileFragmentOrgId = '';

  /// Tabs are built on first visit so Network/Profile API work does not run
  /// on home startup (IndexedStack used to mount every tab immediately).
  void _ensureTabBuilt(int index) {
    switch (index) {
      case 1:
        _networkFragment ??= NetworkTabFragment(
          openDrawer: () => scaffoldKey.currentState?.openDrawer(),
        );
      case 3:
        // Profile tab follows the acting workspace: personal profile
        // normally, the business page profile when switched (like web).
        final org = ActingContextService.instance.organization;
        final wantedOrgId = org?.id ?? '';
        if (_profileFragment == null || _profileFragmentOrgId != wantedOrgId) {
          _profileFragmentOrgId = wantedOrgId;
          _profileFragment = org != null
              ? OrganizationProfileScreen(
                  key: ValueKey('org-profile-${org.id}'),
                  identifier: org.id,
                  showBackButton: false,
                )
              : const SVProfileFragment();
        }
    }
  }

  void _onActingChanged() {
    if (!mounted) return;
    setState(() {
      if (_profileFragment != null) {
        // Rebuild the profile tab for the new workspace on next visit.
        _profileFragment = null;
        _profileFragmentOrgId = '';
        if (selectedIndex == 3) _ensureTabBuilt(3);
      }
    });
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
      // Kick off if Connected Devices revoked this session while backgrounded.
      SessionManager.validateActiveSession();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      FeedVideoAutoplayRegistry.instance.pauseAll();
    }
  }

  @override
  void dispose() {
    ActingContextService.instance.removeListener(_onActingChanged);
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
      key: _homeFragmentKey,
      homeBloc: homeBloc,
      openDrawer: () => scaffoldKey.currentState?.openDrawer(),
    );
    ActingContextService.instance.addListener(_onActingChanged);
    // Ensure workspace is restored after fresh login / if splash skipped it.
    unawaited(ActingContextService.instance.initialize());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationNavigation.consumePendingTap());
      unawaited(
        IncomingShareService.instance.start().then(
          (_) => IncomingShareService.instance.consumePending(),
        ),
      );
    });
    super.initState();
  }

  void _selectTab(int index) {
    if (selectedIndex == index) {
      if (index == 0) {
        _homeFragmentKey.currentState?.scrollToTop(refreshIfAlreadyAtTop: true);
      }
      return;
    }
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
          crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _navIconBand(Widget child) {
    return SizedBox(
      height: _kNavIconBandHeight,
      width: double.infinity,
      child: Center(child: child),
    );
  }

  Widget _navLabelRow(
    OneUITheme theme, {
    required bool isSelected,
    String? label,
  }) {
    return SizedBox(
      height: _kNavLabelRowHeight,
      width: double.infinity,
      child: Center(
        child: label == null
            ? const SizedBox.shrink()
            : Text(
                label,
                style: _navLabelStyle(theme, isSelected: isSelected),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
      ),
    );
  }

  Widget _navItemColumn({
    required Widget icon,
    required OneUITheme theme,
    required bool isSelected,
    String? label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navIconBand(icon),
        const SizedBox(height: _kNavLabelSpacing),
        _navLabelRow(theme, isSelected: isSelected, label: label),
      ],
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
        child: _navItemColumn(
          theme: theme,
          isSelected: isSelected,
          label: label,
          icon: FeedIcon(
            asset: svgAsset,
            size: _kNavIconSize,
            color: isSelected ? theme.accentInk : theme.textTertiary,
          ),
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
        child: SizedBox(
          height: _kNavItemContentHeight,
          child: Center(
            child: Container(
              width: _kNavItemContentHeight,
              height: _kNavItemContentHeight,
              decoration: BoxDecoration(
                color: theme.accent,
                shape: BoxShape.circle,
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
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem() {
    final isSelected = selectedIndex == 3;
    final theme = OneUITheme.of(context);
    final org = ActingContextService.instance.organization;

    Widget avatarContent;
    if (org != null) {
      // Business workspace active — profile tab targets the business page.
      final logo = (org.logoUrl != null && org.logoUrl!.isNotEmpty)
          ? AppData.fullImageUrl(org.logoUrl!)
          : '';
      avatarContent = logo.isNotEmpty
          ? AppCachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => ColoredBox(
                color: theme.accentSoft,
                child: Icon(Icons.business_rounded,
                    size: 14, color: theme.primary),
              ),
            )
          : ColoredBox(
              color: theme.accentSoft,
              child:
                  Icon(Icons.business_rounded, size: 14, color: theme.primary),
            );
    } else {
      avatarContent = ValueListenableBuilder<String>(
        valueListenable: AppData.profilePicNotifier,
        builder: (_, picUrl, __) {
          final url = picUrl.isNotEmpty ? picUrl : AppData.profilePicUrl;
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
      );
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(3),
        child: _navItemColumn(
          theme: theme,
          isSelected: isSelected,
          label: translation(context).lbl_profile,
          icon: Container(
            width: _kNavIconSize,
            height: _kNavIconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? theme.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipOval(child: avatarContent),
          ),
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
        child: _navItemColumn(
          theme: theme,
          isSelected: false,
          label: translation(context).lbl_images,
          icon: Container(
            width: _kNavIconSize,
            height: _kNavIconSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0EA5E9), Color(0xFF0D9488)],
              ),
            ),
            child: Center(
              child: FeedIcon(
                asset: FeedIconAssets.navImages,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
