import 'package:cached_network_image/cached_network_image.dart';
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
  final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(-1);

  @override
  void dispose() {
    selectedIndexNotifier.dispose();
    super.dispose();
  }

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
              SizedBox(height: 40),
              buildProfileSection(),
              SizedBox(height: 20),
              buildDrawerOptions(options),
              Divider(indent: 16, endIndent: 16, color: Colors.white),
              buildAppVersionInfo(),
              SizedBox(height: 20),
            ],
          ),
        ),
        buildDrawerCloseButton(),
      ],
    );
  }

  Widget buildProfileSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CachedNetworkImage(
          imageUrl: '${AppData.imageUrl}${AppData.profile_pic}',
          height: 62,
          width: 62,
          fit: BoxFit.cover,
        ).cornerRadiusWithClipRRect(8),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppData.userType == 'doctor'
                    ? "Dr. ${capitalizeWords(AppData.name)}"
                    : capitalizeWords(AppData.name),
                style: boldTextStyle(size: 18, color: Colors.white),
              ),
              SizedBox(height: 2),
              Text(
                AppData.userType == 'doctor'
                    ? AppData.specialty
                    : AppData.userType == 'student'
                    ? "${AppData.university}\n Student"
                    : AppData.specialty,
                style: secondaryTextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ).paddingOnly(left: 16, right: 8, bottom: 20, top: 0);
  }

  Widget buildDrawerOptions(List<SVDrawerModel> options) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedIndexNotifier,
      builder: (context, selectedIndex, _) {
        return Column(
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
                    : SVAppColorPrimary,
              ),
              title: e.title.validate(),
              titleTextStyle: boldTextStyle(size: 14, color: Colors.white),
              leading: Image.asset(
                e.image ?? "",
                height: 22,
                width: 22,
                fit: BoxFit.cover,
                color: Colors.white,
              ),
              onTap: () => onDrawerOptionTap(index, options.length),
            );
          }).toList(),
        );
      },
    );
  }

  Widget buildAppVersionInfo() {
    return Center(
      child: SnapHelperWidget<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        onSuccess: (data) => Text(
          data.version,
          style: boldTextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget buildDrawerCloseButton() {
    return Stack(
      children: [
        Container(color: SVAppColorPrimary, width: 20),
        InkWell(
          onTap: () => finish(context),
          child: Container(
            decoration: BoxDecoration(
              color: SVAppColorPrimary,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(300),
                bottomRight: Radius.circular(300),
              ),
            ),
            margin: EdgeInsets.only(top: 50),
            width: 50,
            height: 100,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }

  void onDrawerOptionTap(int index, int optionsLength) {
    selectedIndexNotifier.value = index;
    if (index == optionsLength - 1) {
      finish(context);
    }
    Navigator.pop(context);
    switch (index) {
      case 0:
        AboutUsScreen().launch(context);
        break;
      case 1:
        ChatDetailScreen(isFromMainScreen: true).launch(context);
        break;
      case 2:
        JobsScreen().launch(context);
        break;
      case 3:
        DrugsListScreen().launch(context);
        break;
      case 4:
        CaseDiscussionScreen().launch(context);
        break;
      case 5:
        ComingSoonScreen().launch(context);
        break;
      case 6:
        ComingSoonScreen().launch(context);
        break;
      case 7:
        GuidelinesScreen().launch(context);
        break;
      case 8:
        ConferencesScreen().launch(context);
        break;
      case 9:
        ComingSoonScreen().launch(context);
        break;
      case 10:
        ComingSoonScreen().launch(context);
        break;
      case 11:
        NewsScreen().launch(context);
        break;
      case 12:
        ComingSoonScreen().launch(context);
        break;
      case 13:
        SuggestionScreen().launch(context);
        break;
      case 14:
        AppSettingScreen().launch(context);
        break;
      case 15:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebPageScreen(
              page_name: 'Privacy Policy',
              url: 'https://doctak.net/privacy-policy',
            ),
          ),
        );
        break;
      case 16:
        logoutAccount(context);
        break;
      case 17:
        deleteAccount(context);
        break;
    }
  }

  Future<void> logoutAccount(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warning!'),
        content: Text('Are sure want to logout account?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(
              'Yes',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              bool logoutResult = await logoutUserAccount(prefs.getString('device_token'));
              if (logoutResult) {
                AppSharedPreferences().clearSharedPreferencesData(context);
                LoginScreen().launch(context, isNewTask: true);
              }
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    if (result != null && result) {
      print('User logged out');
    }
  }

  Future<bool> logoutUserAccount(String? deviceToken) async {
    String logoutUrl = 'https://doctak.net/api/logout';
    var response = await http.post(
      Uri.parse(logoutUrl),
      body: {'device_token': deviceToken},
    );
    return response.statusCode == 200;
  }

  Future<void> deleteAccount(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warning!'),
        content: Text('Are sure want to delete account?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(
              'Yes',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              bool deleteResult = await deleteUserAccount(prefs.getString('device_token'));
              if (deleteResult) {
                AppSharedPreferences().clearSharedPreferencesData(context);
                LoginScreen().launch(context, isNewTask: true);
              }
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
    if (result != null && result) {
      print('User account deleted');
    }
  }

  Future<bool> deleteUserAccount(String? deviceToken) async {
    String deleteUrl = 'https://doctak.net/api/delete_account';
    var response = await http.post(
      Uri.parse(deleteUrl),
      body: {'device_token': deviceToken},
    );
    return response.statusCode == 200;
  }
}
