import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:http/http.dart' as http;

import '../../../utils/SVCommon.dart';

class AppSettingScreen extends StatefulWidget {
  const AppSettingScreen({super.key});

  @override
  State<AppSettingScreen> createState() => _AppSettingScreenState();
}

class _AppSettingScreenState extends State<AppSettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('App Settings', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ListTile(
              title: const Text(
                'Theme Appearance',
                style: TextStyle(
               fontFamily: 'Poppins-Light',
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Switch(
                onChanged: (val) {
                  appStore.toggleDarkMode(value: val);
                },
                value: appStore.isDarkMode,
                activeColor: SVAppColorPrimary,
              ),
            ),
            const Divider(
              color: Colors.grey,
            ),
            ListTile(
              title: const Text(
                'App Language',
                style: TextStyle(
                  fontFamily: 'Poppins-Light',
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: PopupMenuButton(
                icon: Icon(
                  Icons.translate,
                  color: context.iconColor,
                ),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: Builder(builder: (context) {
                        return const Column(children: [
                          PopupMenuItem(
                            value: 'English',
                            child: Text('🇺🇸 English'),
                          ),
                          PopupMenuItem(
                            value: 'Arabic',
                            child: Text('🇸🇦 اَلْعَرَبِيَّة '),
                          )
                        ]);
                      }),
                    )
                  ];
                },
                onSelected: (value) async {
                  if (value == 'English') {
                    if (value != null) {
                      Locale _locale = await setLocale('en');
                      MyApp.setLocale(context, _locale);
                    }
                  } else {
                    if (value != null) {
                      Locale _locale = await setLocale('ar');
                      MyApp.setLocale(context, _locale);
                    }
                  }
                },
              ),
            ),
            const Divider(color: Colors.grey,),
            ListTile(
              trailing: const Icon(Icons.delete,color: Colors.red,),
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  fontFamily: 'Poppins-Light',
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: (){
                deleteAccount(context);
              },
            ),
            const Divider(
              color: Colors.grey,
            ),
            // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
          ],
        ),
      ),
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
                style: TextStyle(color: Colors.red,fontFamily: 'Poppins-Light',),
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
}
