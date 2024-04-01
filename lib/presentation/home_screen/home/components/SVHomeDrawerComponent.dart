import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/coming_soon_screen/coming_soon_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/app_setting_screen/app_setting_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drugs_list_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/guidelines_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/news_screen/news_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/suggestion_screen.dart';
import 'package:doctak_app/presentation/home_screen/models/SVCommonModels.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_mobx/flutter_mobx.dart';

class SVHomeDrawerComponent extends StatefulWidget {
  @override
  State<SVHomeDrawerComponent> createState() => _SVHomeDrawerComponentState();
}

class _SVHomeDrawerComponentState extends State<SVHomeDrawerComponent> {

  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    List<SVDrawerModel> options = getDrawerOptions(context);

    return Observer(
        builder: (_) =>ListView(
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
            CachedNetworkImage(imageUrl:AppData.imageUrl + AppData.profile_pic, height: 62, width: 62, fit: BoxFit.cover).cornerRadiusWithClipRRect(8),
            16.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppData.userType == 'doctor'
                        ? "Dr. ${capitalizeWords(AppData.name)}"
                        : capitalizeWords(AppData.name), // User's name
                      style: boldTextStyle(size: 18),
                  ),
                  8.height,
                  Text(
                    textAlign: TextAlign.center,
                    AppData.userType == 'doctor'
                        ? AppData.specialty
                        : "${AppData.university}\n Student",
                    // User's specialty
                      style: secondaryTextStyle(color: svGetBodyColor())
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Image.asset('images/socialv/icons/ic_CloseSquare.png', height: 16, width: 16, fit: BoxFit.cover, color: context.iconColor),
              onPressed: () {
                finish(context);
              },
            ),

          ],
        ).paddingOnly(left: 16, right: 8, bottom: 20, top: 0),
        20.height,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((e) {
            int index = options.indexOf(e);
            return SettingItemWidget(
              decoration: BoxDecoration(color: selectedIndex == index ? SVAppColorPrimary.withAlpha(30) : context.cardColor),
              title: e.title.validate(),
              titleTextStyle: boldTextStyle(size: 14),
              leading: Image.asset(e.image.validate(), height: 22, width: 22, fit: BoxFit.cover, color: SVAppColorPrimary),
              onTap: () {
                selectedIndex = index;
                setState(() {});
                if (selectedIndex == options.length - 1) {
                  finish(context);

                }if (selectedIndex == 0) {
                  finish(context);
                  const JobsScreen().launch(context);
                }
                else if (selectedIndex == 1) {
                  finish(context);
                  const DrugsListScreen().launch(context);
                  print(selectedIndex);
                } else if (selectedIndex == 2) {
                  finish(context);
                  print(selectedIndex);

                  ConferencesScreen().launch(context);
                  // SVGroupProfileScreen().launch(context);
                } else if (selectedIndex == 3) {
                  finish(context);
                  print(selectedIndex);
                  const GuidelinesScreen().launch(context);
                  // SVGroupProfileScreen().launch(context);
                } else if (selectedIndex == 4) {
                  finish(context);
                  print(selectedIndex);
                  ComingSoonScreen().launch(context);

                  // SVGroupProfileScreen().launch(context);
                } else if (selectedIndex == 5) {
                  finish(context);
                  print(selectedIndex);

                  // SVGroupProfileScreen().launch(context);
                }else if (selectedIndex == 6) {
                  finish(context);
                  print(selectedIndex);
                  ComingSoonScreen().launch(context);

                  // SVGroupProfileScreen().launch(context);
                }else if (selectedIndex == 7) {
                  finish(context);
                  print(selectedIndex);
                  NewsScreen().launch(context);

                  // SVGroupProfileScreen().launch(context);
                }else if (selectedIndex == 8) {
                  finish(context);
                  print(selectedIndex);
                  ComingSoonScreen().launch(context);

                  // SVGroupProfileScreen().launch(context);
                }else if (selectedIndex == 9) {
                  finish(context);
                  print(selectedIndex);
                  const SuggestionScreen().launch(context);


                  // SVGroupProfileScreen().launch(context);
                }else if (selectedIndex == 10) {
                  finish(context);
                  print(selectedIndex);
                  AppSettingScreen().launch(context);

                  // SVGroupProfileScreen().launch(context);
                }else if (selectedIndex == 11) {
                  finish(context);
                  print(selectedIndex);
                  ComingSoonScreen().launch(context);

                  // SVGroupProfileScreen().launch(context);
                }else if (selectedIndex == 12) {
                  print(selectedIndex);
                  logoutAccount(context);
                  // finish(context);
                  // SVGroupProfileScreen().launch(context);
                }else if (selectedIndex == 13) {
                  finish(context);
                  print(selectedIndex);

                  // SVGroupProfileScreen().launch(context);
                }else if (selectedIndex == 14) {
                  finish(context);
                  print(selectedIndex);

                  // SVGroupProfileScreen().launch(context);
                }
              },
            );
          }).toList(),
        ),
        const Divider(indent: 16, endIndent: 16),
        Center(
          child: SnapHelperWidget<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            onSuccess: (data) => Text(data.version, style: boldTextStyle(color: svGetBodyColor())),
          ),
        ),
        20.height,
      ],
    ));
  }
  logoutAccount(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning!'),
          content: const Text(
              'Are sure want to logout account?'),
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
                style: TextStyle(color: Colors.red),
                // color: Colors.red,
              ),
              onPressed: () async {
                var result = await logoutUserAccount();
                if (result) {
                  AppSharedPreferences().clearSharedPreferencesData(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  LoginScreen(),), (route) => false
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
  Future<bool> logoutUserAccount() async {
    final apiUrl = Uri.parse('${AppData.remoteUrl}/logout');
    try {
      final response = await http.post(
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

  }

}
