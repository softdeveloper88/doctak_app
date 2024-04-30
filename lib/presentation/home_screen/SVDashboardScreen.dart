import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/search_screen/search_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../core/utils/app/AppData.dart';
import 'fragments/add_post/SVAddPostFragment.dart';
import 'fragments/home_main_screen/SVHomeFragment.dart';
import 'fragments/profile_screen/SVProfileFragment.dart';
import 'fragments/search_people/SVSearchFragment.dart';
import 'home/components/SVHomeDrawerComponent.dart';

class SVDashboardScreen extends StatefulWidget {
  const SVDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SVDashboardScreen> createState() => _SVDashboardScreenState();
}
var scaffoldKey = GlobalKey<ScaffoldState>();

class _SVDashboardScreenState extends State<SVDashboardScreen> {
  int selectedIndex = 0;

  Widget getFragment() {
    if (selectedIndex == 0) {
      return SVHomeFragment(openDrawer: (){

        scaffoldKey.currentState?.openDrawer();

      },);
    } else if (selectedIndex == 1) {
      return  SearchScreen(backPress: (){
        setState(() {
          selectedIndex=0;
        });
      });
    } else if (selectedIndex == 2) {
      return const SVAddPostFragment();
    } else if (selectedIndex == 3) {
      return SVSearchFragment();
    } else if (selectedIndex == 4) {
      return SVProfileFragment();
    }
    return SVHomeFragment(openDrawer: (){
      scaffoldKey.currentState?.openDrawer();
    });
  }

  @override
  void initState() {
    setStatusBarColor(Colors.transparent);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: (){
        if(selectedIndex !=0) {
          setState(() {


          selectedIndex = 0;
          });
          return Future(() => false);
        }else{
          return Future(() => true);

        }
      },
      child: Scaffold(
        backgroundColor: svGetScaffoldColor(),
        body: getFragment(),
        key: scaffoldKey,
        drawer: SVHomeDrawerComponent(),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset('images/socialv/icons/ic_Home.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover,
                      color: context.iconColor)
                  .paddingTop(12),
              label: '',
              activeIcon: Image.asset('images/socialv/icons/ic_HomeSelected.png',
                      height: 24, width: 24, fit: BoxFit.cover)
                  .paddingTop(12),
            ),
            BottomNavigationBarItem(
              icon: Image.asset('images/socialv/icons/ic_Search.png',
                  height: 24,
                  width: 24,
                  fit: BoxFit.cover,
                  color: context.iconColor)
                  .paddingTop(12),
              label: '',
              activeIcon: Image.asset(
                  'images/socialv/icons/ic_SearchSelected.png',
                  height: 24,
                  width: 24,
                  fit: BoxFit.cover)
                  .paddingTop(12),
            ),
            BottomNavigationBarItem(
              icon: Image.asset('images/socialv/icons/ic_Plus.png',
                      height: 24,
                      width: 24,
                      fit: BoxFit.cover,
                      color: context.iconColor)
                  .paddingTop(12),
              label: '',
              activeIcon: Image.asset('images/socialv/icons/ic_PlusSelected.png',
                      height: 24, width: 24, fit: BoxFit.cover)
                  .paddingTop(12),
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.group,size: 24,color:context.iconColor,).paddingTop(12),
                // Image.asset('images/socialv/icons/ic_Search.png',
                //         height: 24,
                //         width: 24,
                //         fit: BoxFit.cover,
                //         color: context.iconColor)
                //     .paddingTop(12),
                label: '',
                activeIcon:const Icon(Icons.group,size: 24,).paddingTop(12)
              // Image.asset(
              //         'images/socialv/icons/ic_SearchSelected.png',
              //         height: 24,
              //         width: 24,
              //         fit: BoxFit.cover)
              //     .paddingTop(12),
            ),

            BottomNavigationBarItem(
              icon: SizedBox(
                height: 40.0,
                width: 40.0,
                child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                  AppData.imageUrl + AppData.profile_pic,
                )).paddingTop(12),
              ),
              label: '',
              activeIcon: SizedBox(
                height: 40.0,
                width: 40.0,
                child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                  AppData.imageUrl + AppData.profile_pic,
                )).paddingTop(12),
              ),

              // child:Image.network(AppData.imageUrl + AppData.profile_pic, height: 24, width: 24, fit: BoxFit.cover)).paddingTop(12),
            ),
          ],
          onTap: (val) {
            selectedIndex = val;
            setState(() {});
            if (val == 2) {
              selectedIndex = 0;
              setState(() {});
              const SVAddPostFragment().launch(context);
            }
          },
          currentIndex: selectedIndex,
        ),
      ),
    );
  }
}
