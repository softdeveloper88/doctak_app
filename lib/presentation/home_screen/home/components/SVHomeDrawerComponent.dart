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
import 'package:doctak_app/presentation/case_discussion/screens/discussion_list_screen.dart';
import 'package:doctak_app/presentation/case_discussion/bloc/discussion_list_bloc.dart';
import 'package:doctak_app/presentation/case_discussion/repository/case_discussion_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drugs_list_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/guidelines_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/meeting_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/news_screen/news_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/suggestion_screen.dart';
import 'package:doctak_app/presentation/home_screen/models/SVCommonModels.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/web_screen/web_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'dart:ui';

import '../../../../localization/app_localization.dart';
import '../../../case_discussion/screens/discussion_list_screen.dart';
import '../../../doctak_ai_module/presentation/ai_chat_screen.dart';
import '../../../group_screen/my_groups_screen.dart';
import '../screens/case_discussion/add_case_discuss_screen.dart';
import '../screens/case_discussion/case_discussion_screen.dart';
import '../screens/meeting_screen/manage_meeting_screen.dart';

class SVHomeDrawerComponent extends StatefulWidget {
  @override
  State<SVHomeDrawerComponent> createState() => _SVHomeDrawerComponentState();
}

class _SVHomeDrawerComponentState extends State<SVHomeDrawerComponent> {
  int selectedIndex = -1;

  // Menu categories for better organization
  final Map<String, List<int>> menuCategories = {
    'Professional Tools': [0, 1, 2, 3, 4],
    'Learning & Research': [5, 6, 7, 8, 9],
    'Communication': [10, 11],
    'Resources': [12, 13],
    'Settings': [14, 15, 16],
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<SVDrawerModel> options = getDrawerOptions(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    return Drawer(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              Colors.white,
              Colors.grey.shade50,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            _buildBackgroundPattern(),
            
            // Main content
            Column(
              children: [
                // Advanced Header
                _buildAdvancedHeader(),
                
                // Menu Content
                Expanded(
                  child: _buildAdvancedMenuContent(options),
                ),
                
                // Advanced Footer
                _buildAdvancedFooter(l10n, isRtl),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Subtle background pattern
  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundPatternPainter(),
      ),
    );
  }

  // Compact glassmorphism header
  Widget _buildAdvancedHeader() {
    return Container(
      height: 160,
      child: Stack(
        children: [
          // Solid app color background
          Container(
            decoration: BoxDecoration(
              color: SVAppColorPrimary,
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Advanced profile picture with status indicator
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: CachedNetworkImage(
                            imageUrl: AppData.imageUrl + AppData.profile_pic,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Online status indicator
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  16.width,
                  
                  // User info with modern typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppData.userType == 'doctor'
                              ? '${translation(context).lbl_dr_prefix}${capitalizeWords(AppData.name)}'
                              : capitalizeWords(AppData.name),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        6.height,
                        
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            AppData.userType == 'doctor'
                                ? AppData.specialty
                                : AppData.userType == 'student'
                                    ? '${AppData.university}${translation(context).lbl_student_suffix}'
                                    : AppData.specialty,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Advanced categorized menu with modern cards
  Widget _buildAdvancedMenuContent(List<SVDrawerModel> options) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        itemCount: menuCategories.length,
        itemBuilder: (context, categoryIndex) {
          String categoryName = menuCategories.keys.elementAt(categoryIndex);
          List<int> itemIndices = menuCategories[categoryName]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              _buildCategoryHeader(categoryName, categoryIndex),
              
              // Category items with optimized spacing
              ...itemIndices.map((index) {
                if (index < options.length) {
                  return _buildAdvancedMenuItem(options[index], index);
                }
                return SizedBox.shrink();
              }).toList(),
              
              12.height,
            ],
          );
        },
      ),
    );
  }

  // Compact category headers
  Widget _buildCategoryHeader(String title, int categoryIndex) {
    final icons = [
      Icons.work_outline,
      Icons.school_outlined,
      Icons.forum_outlined,
      Icons.library_books_outlined,
      Icons.settings_outlined,
    ];
    
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SVAppColorPrimary.withOpacity(0.04),
            SVAppColorPrimary.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: SVAppColorPrimary.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: SVAppColorPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icons[categoryIndex],
              size: 12,
              color: SVAppColorPrimary,
            ),
          ),
          8.width,
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontFamily: 'Poppins',
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Compact menu items with optimized height
  Widget _buildAdvancedMenuItem(SVDrawerModel item, int index) {
    bool isSelected = selectedIndex == index;
    
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      height: 56, // Fixed height for consistency
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMenuTap(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? SVAppColorPrimary.withOpacity(0.08)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected 
                    ? SVAppColorPrimary.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                width: isSelected ? 1.2 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? SVAppColorPrimary.withOpacity(0.08)
                      : Colors.black.withOpacity(0.015),
                  blurRadius: isSelected ? 6 : 3,
                  spreadRadius: 0,
                  offset: Offset(0, isSelected ? 1 : 0.5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Compact icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [SVAppColorPrimary.withOpacity(0.15), SVAppColorPrimary.withOpacity(0.08)]
                          : [Colors.grey.withOpacity(0.08), Colors.grey.withOpacity(0.04)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected 
                          ? SVAppColorPrimary.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: (item.image == 'assets/images/docktak_ai_light.png' ||
                            item.image == 'assets/icon/ic_discussion.png')
                        ? Image.asset(
                            item.image ?? "",
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            item.image ?? "",
                            height: 20,
                            width: 20,
                            color: isSelected ? SVAppColorPrimary : Colors.grey.shade600,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                
                12.width,
                
                // Compact title only (removed subtitle to save space)
                Expanded(
                  child: Text(
                    item.title.validate(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? SVAppColorPrimary : Colors.grey.shade800,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Minimalist chevron
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isSelected ? SVAppColorPrimary : Colors.grey.shade400,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get subtitle for menu items
  String _getMenuSubtitle(int index) {
    final subtitles = [
      'Learn about DocTak',
      'AI Assistant',
      'Find opportunities',
      'Medicine database',
      'Clinical discussions',
      'Community polls',
      'Professional groups',
      'Medical guidelines',
      'Medical conferences',
      'Health updates',
      'Video meetings',
      'Education credits',
      'Latest medical news',
      'Special offers',
      'Share feedback',
      'App preferences',
      'Privacy & terms',
      'Sign out',
    ];
    return index < subtitles.length ? subtitles[index] : '';
  }

  // Compact footer with modern styling
  Widget _buildAdvancedFooter(AppLocalizations l10n, bool isRtl) {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact version display
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SVAppColorPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "v${snapshot.data!.version}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: SVAppColorPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
          
          12.height,
          
          // Compact home button
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SVAppColorPrimary, SVAppColorPrimary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: SVAppColorPrimary.withOpacity(0.25),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => finish(context),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    6.width,
                    Text(
                      l10n.lbl_home,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Handle menu item taps
  void _handleMenuTap(int index) {
    setState(() {
      selectedIndex = index;
    });
    
    HapticFeedback.lightImpact();
    
    Future.delayed(const Duration(milliseconds: 150), () {
      finish(context);
      
      switch (index) {
        case 0: AboutUsScreen().launch(context); break;
        case 1: AiChatScreen().launch(context); break;
        case 2: const JobsScreen().launch(context); break;
        case 3: const DrugsListScreen().launch(context); break;
        case 4: // const CaseDiscussionScreen().launch(context);
      BlocProvider(
            create: (context) => DiscussionListBloc(
              repository: CaseDiscussionRepository(
                baseUrl: AppData.base2,
                // Use AppData.base instead of AppData.base2
                getAuthToken: () => AppData.userToken ?? "",
              ),
            ),
            child: const DiscussionListScreen(),
          ).launch(context);
          break;
        case 5: ComingSoonScreen().launch(context); break;
        case 6: MyGroupsScreen().launch(context); break;
        case 7: const GuidelinesScreen().launch(context); break;
        case 8: ConferencesScreen().launch(context); break;
        case 9: ComingSoonScreen().launch(context); break;
        case 10: ManageMeetingScreen().launch(context); break;
        case 11: ComingSoonScreen().launch(context); break;
        case 12: ComingSoonScreen().launch(context); break;
        case 13: const SuggestionScreen().launch(context); break;
        case 14: const AppSettingScreen().launch(context); break;
        case 15:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebPageScreen(
                page_name: AppLocalizations.of(context)!.lbl_privacy_policy,
                url: 'https://doctak.net/privacy-policy',
              ),
            ),
          );
          break;
        case 16: logoutAccount(context); break;
      }
    });
  }

  logoutAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.lbl_logout),
          content: Text(l10n.msg_confirm_logout),
          actions: [
            TextButton(
              child: Text(l10n.lbl_cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(child: Text(
                l10n.lbl_yes,
                style: const TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins',
                ),
              ),
              onPressed: () async {
                DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
                String deviceId = '';
                String deviceType = '';
                if (isAndroid) {
                  AndroidDeviceInfo androidInfo =
                      await deviceInfoPlugin.androidInfo;
                  print('Running on ${androidInfo.model}');
                  deviceType = "android";
                  deviceId = androidInfo.id;
                } else {
                  IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
                  print(
                      'Running on ${iosInfo.utsname.machine}'); // e.g. "iPod7,1"
                  deviceType = "ios";
                  deviceId = iosInfo.identifierForVendor.toString();
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
                } else {
                  AppSharedPreferences().clearSharedPreferencesData(context);
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                      (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.lbl_delete_account_confirmation),
          content: Text(l10n.msg_delete_account_warning),
          actions: [
            TextButton(
              child: Text(l10n.lbl_cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                l10n.lbl_delete,
                style: const TextStyle(
                  color: Colors.red,
                  fontFamily: 'Poppins',
                ),
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
        return true;
      } else {
        return false;
        throw Exception('Failed to delete account');
      }
    } catch (error) {
      return false;
    }
    return false;
  }

  Future<bool> logoutUserAccount(deviceId) async {
    final apiUrl = Uri.parse('${AppData.remoteUrl}/logout');
    try {
      print(AppData.userToken);
      final response = await http.post(
        body: {'device_id': deviceId},
        apiUrl,
        headers: <String, String>{
          'Authorization': 'Bearer ${AppData.userToken!}',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
        throw Exception('Failed to delete account');
      }
    } catch (error) {
      return false;
    }
  }
}

// Custom painter for background pattern
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.03)
      ..strokeWidth = 1;

    final path = Path();
    for (int i = 0; i < 20; i++) {
      for (int j = 0; j < 20; j++) {
        final x = (size.width / 20) * i;
        final y = (size.height / 20) * j;
        path.addOval(Rect.fromCircle(center: Offset(x, y), radius: 1));
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
