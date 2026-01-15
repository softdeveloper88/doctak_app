import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/chat_gpt_with_image_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../core/utils/app/AppData.dart';
import '../../localization/app_localization.dart';
import 'fragments/add_post/SVAddPostFragment.dart';
import 'fragments/add_post/bloc/add_post_bloc.dart';
import 'fragments/home_main_screen/SVHomeFragment.dart';
import 'fragments/home_main_screen/bloc/home_bloc.dart';
import 'fragments/profile_screen/SVProfileFragment.dart';
import 'home/components/SVHomeDrawerComponent.dart';

class SVDashboardScreen extends StatefulWidget {
  const SVDashboardScreen({super.key});

  @override
  State<SVDashboardScreen> createState() => _SVDashboardScreenState();
}

class _SVDashboardScreenState extends State<SVDashboardScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  final HomeBloc homeBloc = HomeBloc();
  final AddPostBloc addPostBloc = AddPostBloc();
  late final List<Widget> _fragments;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state change ');
    if (state == AppLifecycleState.resumed) {
      // NotificationService.clearBadgeCount(); // Clears badge when app resumes

      //TODO: set status to online here in firestore
    } else {
      // NotificationService.clearBadgeCount(); // Clears badge when app resumes
      //TODO: set status to offline here in firestore
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    addPostBloc.close();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void initState() {
    setStatusBarColor(Colors.transparent);
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _fragments = [
      SVHomeFragment(homeBloc: homeBloc, openDrawer: () => scaffoldKey.currentState?.openDrawer()),
      SearchScreen(backPress: () => setState(() => selectedIndex = 0)),
      SVAddPostFragment(
        refresh: () {
          setState(() => selectedIndex = 0);
          homeBloc.add(PostLoadPageEvent(page: 1));
        },
        addPostBloc: addPostBloc,
      ),
      // SVSearchFragment(
      //   backPress: () => setState(() => selectedIndex = 0),
      // ),
      const SVProfileFragment(),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedIndex != 0) {
          setState(() => selectedIndex = 0);
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: svGetScaffoldColor(),
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: IndexedStack(index: selectedIndex, children: _fragments),
        key: scaffoldKey,
        drawer: SVHomeDrawerComponent(),
        bottomNavigationBar: _buildModernBottomNavigationBar(),
      ),
    );
  }

  Widget _buildModernBottomNavigationBar() {
    final theme = OneUITheme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // One UI 8.5 styled bottom navigation
    return Container(
      decoration: theme.navBarDecoration,
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.center, children: isRTL ? _buildRTLNavigationItems() : _buildLTRNavigationItems()),
        ),
      ),
    );
  }

  List<Widget> _buildLTRNavigationItems() {
    return [
      _buildNavItem(0, CupertinoIcons.house_fill, CupertinoIcons.house, translation(context).lbl_home),
      _buildNavItem(1, CupertinoIcons.search_circle_fill, CupertinoIcons.search, translation(context).lbl_search),
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
      _buildNavItem(1, CupertinoIcons.search_circle_fill, CupertinoIcons.search, translation(context).lbl_search),
      _buildNavItem(0, CupertinoIcons.house_fill, CupertinoIcons.house, translation(context).lbl_home),
    ];
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = selectedIndex == index;
    final theme = OneUITheme.of(context);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selectedIndex != index) {
            setState(() => selectedIndex = index);
            _animationController.forward().then((_) => _animationController.reverse());
          }
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // One UI 8.5 styled icon with pill indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 6),
              decoration: BoxDecoration(color: isSelected ? theme.primary.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
              child: Icon(isSelected ? activeIcon : inactiveIcon, size: 24, color: isSelected ? theme.primary : theme.iconInactive),
            ),
            const SizedBox(height: 4),
            // One UI 8.5 label
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? theme.primary : theme.iconInactive, letterSpacing: 0.1),
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
        onTap: () {
          _fragments[2].launch(context);
          _animationController.forward().then((_) => _animationController.reverse());
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // One UI 8.5 styled add button
            Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primary, theme.primary.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 0, offset: const Offset(0, 2))],
              ),
              child: const Icon(CupertinoIcons.plus, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 4),
            // Empty space to align with other items
            const SizedBox(height: 13),
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
        onTap: () {
          if (selectedIndex != 3) {
            setState(() => selectedIndex = 3);
            _animationController.forward().then((_) => _animationController.reverse());
          }
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // One UI 8.5 styled profile with pill indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 8, vertical: 4),
              decoration: BoxDecoration(color: isSelected ? theme.primary.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? theme.primary : theme.iconInactive, width: 2),
                ),
                child: ClipOval(
                  child: (AppData.profile_pic.trim().isNotEmpty && AppData.profile_pic.toLowerCase() != 'null')
                      ? AppCachedNetworkImage(imageUrl: AppData.imageUrl + AppData.profile_pic, fit: BoxFit.cover)
                      : Image.asset('assets/images/person.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // One UI 8.5 label
            Text(
              translation(context).lbl_profile,
              style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? theme.primary : theme.iconInactive, letterSpacing: 0.1),
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
          ChatGptWithImageScreen(isFromMainScreen: true).launch(context);
          _animationController.forward().then((_) => _animationController.reverse());
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // One UI 8.5 styled AI icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Image.asset(theme.isDark ? 'assets/images/docktak_ai_light.png' : 'assets/images/docktak_ai_light.png', width: 24, height: 24, fit: BoxFit.contain),
            ),
            const SizedBox(height: 4),
            // One UI 8.5 label
            Text(
              translation(context).lbl_ai,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.iconInactive, letterSpacing: 0.1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
