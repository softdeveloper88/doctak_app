import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

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
        backgroundColor: svGetScaffoldColor(),
    iconTheme: IconThemeData(color: context.iconColor),
    title: Text('App Setting', style: boldTextStyle(size: 20)),
    elevation: 0,
    centerTitle: true,
    actions: const [
    // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
    ],
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
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing:  Switch(
                onChanged: (val) {
                  appStore.toggleDarkMode(value: val);
                },
                value: appStore.isDarkMode,
                activeColor: SVAppColorPrimary,
              ),
            ),
            const Divider(color: Colors.grey,),
            ListTile(

              title: const Text(
                'App Language',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing:  PopupMenuButton(
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
            // const Divider(color: Colors.grey,),
            // const ListTile(
            //   title: Text(
            //     'Reset Password',
            //     style: TextStyle(
            //       fontSize: 18.0,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            //
            // ),
            const Divider(color: Colors.grey,),
            if(AppData.isShowGoogleBannerAds??false)BannerAdWidget()
          ],
        ),
      ),
    );
  }
}
