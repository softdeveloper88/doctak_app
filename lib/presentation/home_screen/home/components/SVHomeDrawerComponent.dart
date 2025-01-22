import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/about_us/about_us_screen.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/ChatDetailScreen.dart';
import 'package:doctak_app/presentation/coming_soon_screen/coming_soon_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/app_setting_screen/app_setting_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/case_discussion_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drugs_list_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/guidelines_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/news_screen/news_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/suggestion_screen.dart';
import 'package:doctak_app/presentation/home_screen/models/SVCommonModels.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/web_screen/web_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../screens/case_discussion/add_case_discuss_screen.dart';

class SVHomeDrawerComponent extends StatefulWidget {
  @override
  State<SVHomeDrawerComponent> createState() => _SVHomeDrawerComponentState();
}

class _SVHomeDrawerComponentState extends State<SVHomeDrawerComponent> {
  int selectedIndex = -1;
  // @override
  // void dispose() {
  //   _bannerAd!.dispose();
  //   super.dispose();
  // }
  //
  // @override
  // void initState() {
  //   getBannerAds();
  //   super.initState();
  // }
  // bool isLoaded = false;
  // bool isActive = true;
  // BannerAd? _bannerAd;
  //
  // getBannerAds() {
  //   _bannerAd = BannerAd(
  //       size: AdSize.banner,
  //       adUnitId: AdmobSetting.bannerUnit,
  //       listener: BannerAdListener(onAdClosed: (Ad ad) {
  //         debugPrint("Ad Closed");
  //       }, onAdFailedToLoad: (Ad ad, LoadAdError error) {
  //         setState(() {
  //           isLoaded = false;
  //         });
  //       }, onAdLoaded: (Ad ad) {
  //         setState(() {
  //           isLoaded = true;
  //         });
  //         debugPrint('Ad Loaded');
  //       }, onAdOpened: (Ad ad) {
  //         debugPrint('Ad opened');
  //       }),
  //       request: const AdRequest());
  //
  //   _bannerAd!.load();
  // }
  // Widget bannerAdLoaded() {
  //   if (isLoaded == true) {
  //     return Padding(
  //       padding: const EdgeInsets.all(8.0),
  //       child: SizedBox(
  //         height: _bannerAd!.size.height.toDouble(),
  //         child: AdWidget(
  //           ad: _bannerAd!,
  //         ),
  //       ),
  //     );
  //   } else {
  //     return const SizedBox(
  //       height: 8,
  //     );
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    List<SVDrawerModel> options = getDrawerOptions(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: SVAppColorPrimary,
          width: 300,
          child: ListView(
            children: [
              // 10.height,
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     Padding(
              //       padding: const EdgeInsets.only(right: 8.0),
              //       child: Switch(
              //         onChanged: (val) {
              //           appStore.toggleDarkMode(value: val);
              //         },
              //         value: appStore.isDarkMode,
              //         activeColor: SVAppColorPrimary,
              //       ),
              //     ),
              //   ],
              // ),
              40.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CachedNetworkImage(
                      imageUrl: AppData.imageUrl + AppData.profile_pic,
                      height: 62,
                      width: 62,
                      fit: BoxFit.cover)
                      .cornerRadiusWithClipRRect(8),
                  16.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppData.userType == 'doctor'
                              ? "Dr. ${capitalizeWords(AppData.name)}"
                              : capitalizeWords(AppData.name), // User's name
                          style: boldTextStyle(size: 18, color: Colors.white,fontFamily: 'Poppins',),
                        ),
                        2.height,
                        Text(
                            textAlign: TextAlign.center,
                            AppData.userType == 'doctor'
                                ? AppData.specialty
                                : AppData.userType == 'student'
                                ? "${AppData.university}\n Student"
                                : AppData.specialty,
                            // User's specialty
                            style: secondaryTextStyle(color: Colors.white,fontFamily: 'Poppins',)),
                      ],
                    ),
                  ),
                  // IconButton(
                  //   icon: Image.asset('images/socialv/icons/ic_CloseSquare.png',
                  //       height: 16,
                  //       width: 16,
                  //       fit: BoxFit.cover,
                  //       color: context.iconColor),
                  //   onPressed: () {
                  //     finish(context);
                  //   },
                  // ),
                ],
              ).paddingOnly(left: 16, right: 8, bottom: 20, top: 0),
              20.height,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((e) {
                  int index = options.indexOf(e);
                  return SettingItemWidget(
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                    decoration: BoxDecoration(
                        color: selectedIndex == index
                            ? SVAppColorPrimary.withAlpha(30)
                            : SVAppColorPrimary),
                    title: e.title.validate(),
                    titleTextStyle:
                    boldTextStyle(size: 14, color: Colors.white,fontFamily: 'Poppins',),
                    leading: (e.title=="Post a poll"|| e.title=='Groups Formation'||e.title=='Privacy Policy')?Image.asset(e.image ?? "",
                        height: 22,
                        width: 22,
                        fit: BoxFit.contain,
                        color:Colors.white,
                        ):Image.asset(e.image ?? "",
                        height: 22,
                        width: 22,
                        fit: BoxFit.contain,

                        ),
                    onTap: () {
                      selectedIndex = index;
                      setState(() {});
                      if (selectedIndex == options.length - 1) {
                        finish(context);
                      }
                      if (selectedIndex == 0) {//about us
                        finish(context);
                         AboutUsScreen().launch(context);
                      } else if (selectedIndex == 1) {//AI
                        finish(context);
                        ChatDetailScreen(isFromMainScreen: true).launch(context);
                        print(selectedIndex);
                      } else if (selectedIndex == 2) {//jobs
                        finish(context);
                        const JobsScreen().launch(context);
                        print(selectedIndex);
                      }  else if (selectedIndex == 3) {//drugs list
                        finish(context);
                        const DrugsListScreen().launch(context);
                        print(selectedIndex);
                      } else if (selectedIndex == 4) {//case discussion
                        finish(context);
                        print(selectedIndex);
                        CaseDiscussionScreen().launch(context);
                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 5) { //docTak poll
                        finish(context);
                        print(selectedIndex);
                        ComingSoonScreen().launch(context);
                        // const GuidelinesScreen().launch(context);
                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 6) { //groups Formation
                        finish(context);
                        print(selectedIndex);
                        const ComingSoonScreen().launch(context);
                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 7) { // guidelines
                        finish(context);
                        print(selectedIndex);
                        const GuidelinesScreen().launch(context);

                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 8) {  // conferences
                        finish(context);
                        print(selectedIndex);
                        ConferencesScreen().launch(context);

                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 9) {  // moh updates
                        finish(context);
                        print(selectedIndex);
                        // MyGroupsScreen().launch(context);
                        ComingSoonScreen().launch(context);

                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 10) { //cme
                        finish(context);
                        print(selectedIndex);
                        ComingSoonScreen().launch(context);

                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 11) { // world news
                        finish(context);
                        print(selectedIndex);
                        NewsScreen().launch(context);

                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 12) {  // discount
                        finish(context);
                        print(selectedIndex);
                         ComingSoonScreen().launch(context);

                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 13) {  // suggestions
                        finish(context);
                        print(selectedIndex);
                        const SuggestionScreen().launch(context);

                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 14) { // app setting
                        finish(context);

                        const AppSettingScreen().launch(context);


                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 15) {  // privacy
                        finish(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => WebPageScreen(
                                    page_name: 'Privacy Policy',
                                    url: 'https://doctak.net/privacy-policy')));


                        // SVGroupProfileScreen().launch(context);
                      } else if (selectedIndex == 16) {  //logout
                        finish(context);
                        print(selectedIndex);
                        // ComingSoonScreen().launch(context);
                        logoutAccount(context);

                        // SVGroupProfileScreen().launch(context);
                      }
                      // else if (selectedIndex == 17) { // delete
                      //   print(selectedIndex);
                      //   deleteAccount(context);
                      //   // finish(context);
                      //   // SVGroupProfileScreen().launch(context);
                      // }
                      // else if (selectedIndex == 13) {
                      //
                      //   finish(context);
                      //   print(selectedIndex);
                      //
                      //   // SVGroupProfileScreen().launch(context);
                      // }else if (selectedIndex == 14) {
                      //   finish(context);
                      //   print(selectedIndex);
                      //
                      //   // SVGroupProfileScreen().launch(context);
                      // }
                    },
                  );
                }).toList(),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                color: Colors.white,
              ),
              Center(
                child: SnapHelperWidget<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  onSuccess: (data) => Text(data.version,
                      style: boldTextStyle(color: Colors.white,fontFamily: 'Poppins',)),
                ),
              ),
              20.height,
            ],
          ),
        ),
        Stack(children: [
          Container(
            color: SVAppColorPrimary,
            // decoration: const BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.only(topRight: Radius.circular(300),bottomRight: Radius.circular(300))
            // ),
            width: 20,
          ),
          InkWell(
            onTap: () {
              finish(context);
            },
            child: Container(
              decoration: const BoxDecoration(
                  color: SVAppColorPrimary,
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(300),
                      bottomRight: Radius.circular(300))),
              margin: const EdgeInsets.only(top: 50),
              width: 50,
              height: 100,
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ])
      ],
    );
  }

  logoutAccount(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning!'),
          content: const Text('Are sure want to logout account?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.red,fontFamily: 'Poppins',),
                // color: Colors.red,
              ),
              onPressed: () async {
                DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
                String deviceId='';
                String deviceType='';
                if(isAndroid){
                  AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
                  print('Running on ${androidInfo.model}');
                  deviceType="android";
                  deviceId=androidInfo.id;
                }else{
                  IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
                  print('Running on ${iosInfo.utsname.machine}');  // e.g. "iPod7,1"
                  deviceType="ios";
                  deviceId=iosInfo.identifierForVendor.toString();
                }
                SharedPreferences prefs = await SharedPreferences.getInstance();
                var result = await logoutUserAccount(deviceId);
                if (result) {
                  AppSharedPreferences().clearSharedPreferencesData(context);
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                          (route) => false);
                } else {}

                // Call the delete account function
              },
            ),
          ],
        );
      },
    );
  }

  deleteAccount(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete your Account?'),
          content: const Text(
              '''If you select Delete we will delete your account on our server.

Your app data will also be deleted and you won't be able to retrieve it.

Since this is a security-sensitive operation, you eventually are asked to login before your account can be deleted.'''),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red,fontFamily: 'Poppins',),
                // color: Colors.red,
              ),
              onPressed: () async {
                var result = await deleteUserAccount();
                if (result) {
                  AppSharedPreferences().clearSharedPreferencesData(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                } else {}

                // Call the delete account function
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> deleteUserAccount() async {
    final apiUrl = Uri.parse('${AppData.remoteUrl}/delete-account');
    try {
      final response = await http.get(
        apiUrl,
        headers: <String, String>{
          'Authorization': 'Bearer ${AppData.userToken!}',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        // Handle successful account deletion
        return true;
      } else {
        return false;
        throw Exception('Failed to delete account');
      }
    } catch (error) {
      return false;
      // throw Exception('Error: $error');
    }
    return false;
  }

  Future<bool> logoutUserAccount(deviceId) async {
    final apiUrl = Uri.parse('${AppData.remoteUrl}/logout');
    try {
      print(AppData.userToken);
      final response = await http.post(
        body: {'device_id':deviceId},
        apiUrl,
        headers: <String, String>{
          'Authorization': 'Bearer ${AppData.userToken!}',
          // 'Accept':'Application/json'
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        // Handle successful account deletion
        return true;
      } else {
        return false;
        throw Exception('Failed to delete account');
      }
    } catch (error) {
      return false;
      // throw Exception('Error: $error');
    }
  }
}