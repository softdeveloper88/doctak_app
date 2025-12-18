import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/chat_gpt_with_image_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../core/utils/app/AppData.dart';
import '../../localization/app_localization.dart';
import '../../main.dart' show appStore;
import 'fragments/add_post/SVAddPostFragment.dart';
import 'fragments/add_post/bloc/add_post_bloc.dart';
import 'fragments/home_main_screen/SVHomeFragment.dart';
import 'fragments/home_main_screen/bloc/home_bloc.dart';
import 'fragments/profile_screen/SVProfileFragment.dart';
import 'home/components/SVHomeDrawerComponent.dart';

class SVDashboardScreen extends StatefulWidget {
  const SVDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SVDashboardScreen> createState() => _SVDashboardScreenState();
}

class _SVDashboardScreenState extends State<SVDashboardScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
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

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fragments = [
      SVHomeFragment(
        homeBloc: homeBloc,
        openDrawer: () => scaffoldKey.currentState?.openDrawer(),
      ),
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
    final isDark = appStore.isDarkMode;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // height: 120 + bottomPadding, // Adjust for safe area and improved text layout
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFAFAFA),
        boxShadow: [
          // Primary shadow for depth
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.black.withOpacity(0.12),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, -12),
          ),
          // Secondary shadow for subtle elevation
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, -6),
          ),
          // Inner light effect for glass morphism
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.02)
                : Colors.white.withOpacity(0.8),
            blurRadius: 8,
            spreadRadius: -8,
            offset: const Offset(0, -1),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        // Subtle gradient overlay for premium feel
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1C1C1E), const Color(0xFF1A1A1C)]
              : [const Color(0xFFFBFBFB), const Color(0xFFF8F8F8)],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: Container(
          padding: EdgeInsets.only(
            left: 4,
            right: 4,
            top: 8,
            bottom: bottomPadding > 0 ? bottomPadding : 8,
          ),
          decoration: BoxDecoration(
            // Glass morphism effect
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              width: 0.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: isRTL
                    ? _buildRTLNavigationItems()
                    : _buildLTRNavigationItems(),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLTRNavigationItems() {
    return [
      _buildNavItem(
        0,
        Icons.home_rounded,
        Icons.home_outlined,
        translation(context).lbl_home,
      ),
      _buildNavItem(
        1,
        CupertinoIcons.search,
        CupertinoIcons.search,
        translation(context).lbl_search,
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
        CupertinoIcons.search,
        CupertinoIcons.search,
        translation(context).lbl_search,
      ),
      _buildNavItem(
        0,
        Icons.home_rounded,
        Icons.home_outlined,
        translation(context).lbl_home,
      ),
    ];
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    final isDark = appStore.isDarkMode;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          if (selectedIndex != index) {
            setState(() => selectedIndex = index);
            _animationController.forward().then(
              (_) => _animationController.reverse(),
            );
          }
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 60,
            maxHeight: 70,
            minWidth: 50,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Enhanced icon container with sophisticated design
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                width: isSelected ? 42 : 38,
                height: isSelected ? 42 : 38,
                decoration: BoxDecoration(
                  // Sophisticated background with multiple layers
                  color: isSelected
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(isSelected ? 18 : 16),
                  border: isSelected
                      ? Border.all(
                          color: Colors.blue.withOpacity(0.25),
                          width: 1.5,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          // Primary glow effect
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                          // Inner light for premium feel
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 6,
                            spreadRadius: -2,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                  // Subtle gradient background for selected state
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withOpacity(0.18),
                            Colors.blue.withOpacity(0.12),
                            Colors.blue.withOpacity(0.08),
                          ],
                        )
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: RotationTransition(
                          turns: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Icon(
                      isSelected ? activeIcon : inactiveIcon,
                      key: ValueKey(isSelected),
                      size: isSelected ? 24 : 22,
                      color: isSelected
                          ? Colors.blue[700]
                          : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Enhanced label with proper text overflow handling
              Container(
                constraints: const BoxConstraints(maxWidth: 60),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  style: TextStyle(
                    fontSize: isSelected ? 10.5 : 9.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.blue[700]
                        : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    fontFamily: 'Poppins',
                    letterSpacing: isSelected ? 0.2 : 0.1,
                    height: 1.1,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Flexible(
      child: GestureDetector(
        onTap: () {
          _fragments[2].launch(context);
          _animationController.forward().then(
            (_) => _animationController.reverse(),
          );
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 60,
            maxHeight: 70,
            minWidth: 50,
          ),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Refined Add button container
                    Container(
                      width: 52,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[500]!, Colors.blue[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Simple text label with proper overflow handling
                    // Flexible(
                    //   child: Container(
                    //     constraints: const BoxConstraints(maxWidth: 60),
                    //     child: const Text(
                    //       'Create',
                    //       style: TextStyle(
                    //         color: Colors.blue,
                    //         fontSize: 9.0,
                    //         fontWeight: FontWeight.w700,
                    //         fontFamily: 'Poppins',
                    //         letterSpacing: 0.2,
                    //         height: 0.9,
                    //       ),
                    //       maxLines: 1,
                    //       overflow: TextOverflow.ellipsis,
                    //       textAlign: TextAlign.center,
                    //       softWrap: false,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileNavItem() {
    final isSelected = selectedIndex == 3;
    final isDark = appStore.isDarkMode;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          if (selectedIndex != 3) {
            setState(() => selectedIndex = 3);
            _animationController.forward().then(
              (_) => _animationController.reverse(),
            );
          }
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 60,
            maxHeight: 70,
            minWidth: 50,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Enhanced profile avatar container
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                width: isSelected ? 42 : 38,
                height: isSelected ? 42 : 38,
                padding: EdgeInsets.all(isSelected ? 3 : 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: isSelected
                      ? Border.all(
                          color: Colors.blue.withOpacity(0.25),
                          width: 1.5,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          // Primary glow effect
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                          // Inner light for premium feel
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 6,
                            spreadRadius: -2,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                  // Subtle gradient background for selected state
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withOpacity(0.18),
                            Colors.blue.withOpacity(0.12),
                            Colors.blue.withOpacity(0.08),
                          ],
                        )
                      : null,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.withOpacity(0.4)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: isSelected ? 18 : 16,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        (AppData.profile_pic.trim().isNotEmpty &&
                            AppData.profile_pic.toLowerCase() != 'null')
                        ? AppCachedNetworkImageProvider(
                            AppData.imageUrl + AppData.profile_pic,
                          )
                        : const AssetImage('assets/images/person.png')
                              as ImageProvider,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Enhanced label with proper text overflow handling
              Container(
                constraints: const BoxConstraints(maxWidth: 60),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  style: TextStyle(
                    fontSize: isSelected ? 10.5 : 9.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? Colors.blue[700]
                        : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    fontFamily: 'Poppins',
                    letterSpacing: isSelected ? 0.2 : 0.1,
                    height: 1.1,
                  ),
                  child: Text(
                    translation(context).lbl_profile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAINavItem() {
    final isDark = appStore.isDarkMode;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          ChatGptWithImageScreen(isFromMainScreen: true).launch(context);
          _animationController.forward().then(
            (_) => _animationController.reverse(),
          );
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 60,
            maxHeight: 70,
            minWidth: 50,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // AI icon container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/docktak_ai_light.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Label
              Container(
                constraints: const BoxConstraints(maxWidth: 60),
                child: Text(
                  translation(context).lbl_ai,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    fontFamily: 'Poppins',
                    letterSpacing: 0.1,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
