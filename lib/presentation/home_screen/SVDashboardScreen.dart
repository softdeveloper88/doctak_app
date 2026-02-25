import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/chat_gpt_with_image_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/network_tab_fragment.dart';
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
      NetworkTabFragment(openDrawer: () => scaffoldKey.currentState?.openDrawer()),
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

    // Minimalist bottom navigation matching the clean design
    return Container(
      decoration: BoxDecoration(
        color: theme.navBarBackground,
        border: Border(top: BorderSide(color: theme.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.center, children: isRTL ? _buildRTLNavigationItems() : _buildLTRNavigationItems()),
        ),
      ),
    );
  }

  List<Widget> _buildLTRNavigationItems() {
    return [
      _buildNavItem(0, CupertinoIcons.house_fill, CupertinoIcons.house, translation(context).lbl_home),
      _buildNavItem(1, CupertinoIcons.person_2_fill, CupertinoIcons.person_2, translation(context).lbl_my_network),
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
      _buildNavItem(1, CupertinoIcons.person_2_fill, CupertinoIcons.person_2, translation(context).lbl_my_network),
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
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 22,
              color: isSelected ? theme.primary : theme.iconInactive,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.primary : theme.iconInactive,
              ),
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
            Icon(CupertinoIcons.plus, size: 22, color: theme.iconInactive),
            const SizedBox(height: 4),
            Text(
              translation(context).lbl_post,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: theme.iconInactive,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.primary : theme.iconInactive,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: ValueListenableBuilder<String>(
                  valueListenable: AppData.profilePicNotifier,
                  builder: (_, picUrl, __) {
                    final url = picUrl.isNotEmpty ? picUrl : AppData.profilePicUrl;
                    return (url.isNotEmpty && url.toLowerCase() != 'null')
                        ? AppCachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                        : Image.asset('assets/images/person.png', fit: BoxFit.cover);
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              translation(context).lbl_profile,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.primary : theme.iconInactive,
              ),
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
            Image.asset(
              theme.isDark ? 'assets/images/docktak_ai_light.png' : 'assets/images/docktak_ai_light.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Text(
              translation(context).lbl_ai,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: theme.iconInactive,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
