import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/notification_service.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/chat_gpt_with_image_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../core/utils/app/AppData.dart';
import '../../localization/app_localization.dart';
import 'fragments/add_post/SVAddPostFragment.dart';
import 'fragments/home_main_screen/SVHomeFragment.dart';
import 'fragments/home_main_screen/bloc/home_bloc.dart';
import 'fragments/profile_screen/SVProfileFragment.dart';
import 'fragments/search_people/SVSearchFragment.dart';
import 'home/components/SVHomeDrawerComponent.dart';

class SVDashboardScreen extends StatefulWidget {
  const SVDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SVDashboardScreen> createState() => _SVDashboardScreenState();
}

class _SVDashboardScreenState extends State<SVDashboardScreen> with WidgetsBindingObserver{
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  final HomeBloc homeBloc = HomeBloc();
  late final List<Widget> _fragments;

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
    // TODO: implement dispose
    super.dispose();
  }
  @override
  void initState() {
    setStatusBarColor(Colors.transparent);
    WidgetsBinding.instance.addObserver(this);
    _fragments = [
      SVHomeFragment(
        homeBloc: homeBloc,
        openDrawer: () => scaffoldKey.currentState?.openDrawer(),
      ),
      SearchScreen(
        backPress: () => setState(() => selectedIndex = 0),
      ),
      SVAddPostFragment(
        refresh: () {
          setState(() => selectedIndex = 0);
          homeBloc.add(PostLoadPageEvent(page: 1));

        },
      ),
      // SVSearchFragment(
      //   backPress: () => setState(() => selectedIndex = 0),
      // ),
      SVProfileFragment(),
      ChatGptWithImageScreen(isFromMainScreen: true,),
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
        body: IndexedStack(
          index: selectedIndex,
          children: _fragments,
        ),
        key: scaffoldKey,
        drawer: SVHomeDrawerComponent(),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: Directionality.of(context) == TextDirection.rtl ? [
            BottomNavigationBarItem(
              icon: _buildAIImageAvatar(),
              label: translation(context).lbl_ai,
              activeIcon: _buildAIImageAvatar(),
            ),
            BottomNavigationBarItem(
              icon: _buildProfileAvatar(),
              label: translation(context).lbl_profile,
              activeIcon: _buildProfileAvatar(),
            ),
            _buildBottomNavigationBarItem('ic_Plus', 'ic_PlusSelected', translation(context).lbl_add),
            _buildBottomNavigationBarItem('ic_Search', 'ic_SearchSelected', translation(context).lbl_search),
            _buildBottomNavigationBarItem('ic_Home', 'ic_HomeSelected', translation(context).lbl_home),
          ] : [
            _buildBottomNavigationBarItem('ic_Home', 'ic_HomeSelected', translation(context).lbl_home),
            _buildBottomNavigationBarItem('ic_Search', 'ic_SearchSelected', translation(context).lbl_search),
            _buildBottomNavigationBarItem('ic_Plus', 'ic_PlusSelected', translation(context).lbl_add),
            BottomNavigationBarItem(
              icon: _buildProfileAvatar(),
              label: translation(context).lbl_profile,
              activeIcon: _buildProfileAvatar(),
            ),
            BottomNavigationBarItem(
              icon: _buildAIImageAvatar(),
              label: translation(context).lbl_ai,
              activeIcon: _buildAIImageAvatar(),
            ),
          ],
          onTap: (val) {
            if (Directionality.of(context) == TextDirection.rtl) {
              // In RTL, the tabs are reversed
              final rtlIndex = 4 - val; // Convert from RTL index to LTR index
              if (rtlIndex == 2) {
                _fragments[rtlIndex].launch(context);
              } else if (rtlIndex == 4) {
                _fragments[rtlIndex].launch(context);
              } else {
                setState(() => selectedIndex = rtlIndex);
              }
            } else {
              // LTR normal order
              if (val == 2) {
                _fragments[val].launch(context);
              } else if (val == 4) {
                _fragments[val].launch(context);
              } else {
                setState(() => selectedIndex = val);
              }
            }
            FocusManager.instance.primaryFocus?.unfocus();
          },
          currentIndex: Directionality.of(context) == TextDirection.rtl ? 4 - selectedIndex : selectedIndex,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem(String icon, String activeIcon,String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Image.asset(
          'images/socialv/icons/$icon.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
          color: context.iconColor,
        ),
      ),
      label: label,
      activeIcon: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Image.asset(
          'images/socialv/icons/$activeIcon.png',
          height: 24,
          width: 24,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return SizedBox(
      height: 40.0,
      width: 40.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
            AppData.imageUrl + AppData.profile_pic,
          ),
        ),
      ),
    );
  }
  Widget _buildAIImageAvatar() {
    return SizedBox(
      height: 40.0,
      width: 40.0,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Image.asset(
          'assets/images/docktak_ai_light.png',
          width: 30,
          height: 30,
          fit: BoxFit.contain,
          // color: context.iconColor,
        // )
        // CircleAvatar(
        //   backgroundImage: CachedNetworkImageProvider(
        //     AppData.imageUrl + AppData.profile_pic,
        //   ),
        ),
      ),
    );
  }
}
