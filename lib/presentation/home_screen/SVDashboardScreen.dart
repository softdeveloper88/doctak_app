import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../core/utils/app/AppData.dart';
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

class _SVDashboardScreenState extends State<SVDashboardScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  final HomeBloc homeBloc = HomeBloc();

  late final List<Widget> _fragments;

  @override
  void initState() {
    setStatusBarColor(Colors.transparent);
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
      SVSearchFragment(
        backPress: () => setState(() => selectedIndex = 0),
      ),
      SVProfileFragment(),
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
          showSelectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            _buildBottomNavigationBarItem('ic_Home', 'ic_HomeSelected'),
            _buildBottomNavigationBarItem('ic_Search', 'ic_SearchSelected'),
            _buildBottomNavigationBarItem('ic_Plus', 'ic_PlusSelected'),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.group_outlined,
                size: 28,
                color: context.iconColor,
              ).paddingTop(12),
              label: '',
              activeIcon: Icon(
                Icons.group_outlined,
                size: 28,
              ).paddingTop(12),
            ),
            BottomNavigationBarItem(
              icon: _buildProfileAvatar(),
              label: '',
              activeIcon: _buildProfileAvatar(),
            ),
          ],
          onTap: (val) {
            if (val == 2) {
              _fragments[val].launch(context);
            } else {
              setState(() => selectedIndex = val);
            }
          },
          currentIndex: selectedIndex,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem(String icon, String activeIcon) {
    return BottomNavigationBarItem(
      icon: Image.asset(
        'images/socialv/icons/$icon.png',
        height: 24,
        width: 24,
        fit: BoxFit.cover,
        color: context.iconColor,
      ).paddingTop(12),
      label: '',
      activeIcon: Image.asset(
        'images/socialv/icons/$activeIcon.png',
        height: 24,
        width: 24,
        fit: BoxFit.cover,
      ).paddingTop(12),
    );
  }

  Widget _buildProfileAvatar() {
    return SizedBox(
      height: 40.0,
      width: 40.0,
      child: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(
          AppData.imageUrl + AppData.profile_pic,
        ),
      ).paddingTop(12),
    );
  }
}
