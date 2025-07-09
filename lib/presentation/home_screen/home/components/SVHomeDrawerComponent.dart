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
import 'package:doctak_app/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'dart:ui';
import 'dart:math' as math;

import '../../../../localization/app_localization.dart';
import '../../../case_discussion/screens/discussion_list_screen.dart';
import '../../../doctak_ai_module/presentation/ai_chat_screen.dart';
import '../../../group_screen/my_groups_screen.dart';
import '../screens/meeting_screen/manage_meeting_screen.dart';

class SVHomeDrawerComponent extends StatefulWidget {
  const SVHomeDrawerComponent({Key? key}) : super(key: key);

  @override
  State<SVHomeDrawerComponent> createState() => _SVHomeDrawerComponentState();
}

class _SVHomeDrawerComponentState extends State<SVHomeDrawerComponent>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int selectedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isDisposed = false;

  // Updated menu items with localization keys
  static List<MenuItemData> getMenuItems(BuildContext context) {
    final l10n = translation(context);
    return [
      MenuItemData(
        0,
        Icons.psychology_outlined,
        l10n.lbl_medical_ai,
        l10n.desc_medical_ai,
      ),
      MenuItemData(
        1,
        Icons.business_center_outlined,
        l10n.lbl_jobs,
        l10n.desc_jobs,
      ),
      MenuItemData(
        2,
        Icons.medical_services_outlined,
        l10n.lbl_drugs,
        l10n.desc_drugs,
      ),
      MenuItemData(
        3,
        Icons.forum_outlined,
        l10n.lbl_discussions,
        l10n.desc_discussions,
      ),
      MenuItemData(
        4,
        Icons.description_outlined,
        l10n.lbl_guidelines,
        l10n.desc_guidelines,
      ),
      MenuItemData(
        5,
        Icons.event_outlined,
        l10n.lbl_conferences,
        l10n.desc_conferences,
      ),
      MenuItemData(
        6,
        Icons.video_call_outlined,
        l10n.lbl_meetings,
        l10n.desc_meetings,
      ),
      MenuItemData(
        7,
        Icons.lightbulb_outline,
        l10n.lbl_suggestions,
        l10n.desc_suggestions,
      ),
      MenuItemData(
        8,
        Icons.settings_outlined,
        l10n.lbl_settings,
        l10n.desc_settings,
      ),
      MenuItemData(
        9,
        Icons.privacy_tip_outlined,
        l10n.lbl_privacy,
        l10n.desc_privacy,
      ),
      MenuItemData(10, Icons.work_outline, l10n.lbl_about, l10n.desc_about),
    ];
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    if (!mounted) return;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    if (mounted) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!mounted) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Drawer(
      key: const ValueKey('main_drawer'),
      elevation: 0,
      width: math.max(
        280,
        MediaQuery.of(context).size.width * 0.75,
      ), // Responsive width with minimum
      child: Container(
        decoration: BoxDecoration(
          // Brighter, cleaner background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.blue.shade50,
              Colors.blue.shade100.withOpacity(0.5),
              Colors.blue.shade200.withOpacity(0.3),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Compact Professional Header
            _buildCompactHeader(),

            // Optimized Menu Content
            Expanded(child: _buildOptimizedMenuContent()),

            // Compact Footer
            _buildCompactFooter(l10n, isRtl),
          ],
        ),
      ),
    );
  }

  // Professional header with matching splash screen background
  Widget _buildCompactHeader() {
    // Calculate dynamic height based on safe area
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = math.max(
      220,
      topPadding + 180,
    ); // Ensure minimum space

    return SizedBox(
      key: const ValueKey('drawer_header'),
      height: headerHeight.toDouble(),
      child: Stack(
        children: [
          // Main background matching splash screen
          Container(
            height: headerHeight.toDouble(),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                  Colors.blue.shade100.withOpacity(0.5),
                  Colors.blue.shade200.withOpacity(0.3),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // Decorative curved elements like splash screen
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Another decorative element
          Positioned(
            top: 30,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4285F4).withOpacity(0.1),
                    const Color(0xFF4285F4).withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Curved design element
          Positioned(
            bottom: 0,
            right: 0,
            child: SizedBox(
              width: 150,
              height: 100,
              child: CustomPaint(painter: CurvedElementPainter()),
            ),
          ),

          // Profile section with proper positioning
          Positioned(
            top: 60, // Fixed top position to avoid status bar overlap
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile avatar with professional styling
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4285F4), // Google Blue
                        Color(0xFF1A73E8),
                        Color(0xFF1557B0),
                      ],
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4285F4).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: CachedNetworkImage(
                      imageUrl: AppData.imageUrl + AppData.profile_pic,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(AppData.name),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(AppData.name),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // User info section with better spacing
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // User name with better typography
                      Text(
                        AppData.userType == 'doctor'
                            ? 'Dr. ${capitalizeWords(AppData.name)}'
                            : capitalizeWords(AppData.name),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A365D), // Dark blue-gray
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 6),

                      // Specialty/Role with professional styling
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF4285F4).withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4285F4).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          AppData.userType == 'doctor'
                              ? AppData.specialty
                              : AppData.userType == 'student'
                              ? '${AppData.university} ${translation(context).lbl_student}'
                              : AppData.specialty,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4285F4),
                            fontFamily: 'Poppins',
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to get user initials
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, math.min(2, name.length)).toUpperCase();
    }
  }

  // Menu content with responsive design and overflow protection
  Widget _buildOptimizedMenuContent() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 50),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Container(
              key: const ValueKey('menu_content'),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ), // Further reduced padding for mobile
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Get screen width for responsive adjustments
                  final screenWidth = MediaQuery.of(context).size.width;
                  final drawerWidth = constraints.maxWidth;

                  return ListView.builder(
                    key: const ValueKey('menu_list'),
                    padding: EdgeInsets.zero,
                    physics:
                        const BouncingScrollPhysics(), // Better scroll physics
                    itemCount: getMenuItems(context).length,
                    itemBuilder: (context, index) {
                      return _buildMenuItem(getMenuItems(context)[index]);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Menu item with overflow protection and responsive design
  Widget _buildMenuItem(MenuItemData item) {
    bool isSelected = selectedIndex == item.index;

    return Container(
      key: ValueKey('menu_item_${item.index}'),
      margin: const EdgeInsets.only(bottom: 8),
      height: 64, // Adjusted height to prevent overflow
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _handleMenuTap(item.index),
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF4285F4).withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              // Notification card style background
              color: isSelected
                  ? Colors.blue.withOpacity(0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon container with compact styling
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.15)
                        : Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: isSelected
                        ? Colors.blue[700]
                        : Colors.blue[600],
                  ),
                ),

                const SizedBox(width: 8), // Further reduced spacing
                // Text content with overflow protection
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title with better overflow handling
                      Flexible(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                            fontFamily: 'Poppins',
                            height: 1.2,
                            letterSpacing: 0.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Subtitle with better overflow handling
                      Flexible(
                        child: Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                            fontFamily: 'Poppins',
                            height: 1.1,
                            letterSpacing: 0.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 4), // Small spacing before arrow
                // Arrow icon like notification
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.blue[600],
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Footer with splash screen compatible styling
  Widget _buildCompactFooter(AppLocalizations l10n, bool isRtl) {
    return Container(
      key: const ValueKey('drawer_footer'),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 6,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main button row
          Row(
            children: [
              // Version info
              Expanded(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    return Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4285F4).withOpacity(0.1),
                            const Color(0xFF1A73E8).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4285F4).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: Color(0xFF4285F4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            snapshot.hasData
                                ? "v${snapshot.data!.version}"
                                : "DocTak",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4285F4),
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Home button with icon only
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4285F4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (mounted && !_isDisposed) {
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Logout button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => logoutAccount(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade600,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Button labels row
          Row(
            children: [
              // Version label
              Expanded(
                child: Text(
                  translation(context).lbl_version,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 10),

              // Home label
              SizedBox(
                width: 44,
                child: Text(
                  l10n.lbl_home,
                  style: const TextStyle(
                    fontSize: 9, // Slightly reduced for better fit
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4285F4),
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 10),

              // Logout label
              SizedBox(
                width: 44,
                child: Text(
                  l10n.lbl_logout,
                  style: TextStyle(
                    fontSize: 9, // Slightly reduced for better fit
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Handle menu item taps with updated indices
  void _handleMenuTap(int index) {
    _safeSetState(() {
      selectedIndex = index;
    });

    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _isDisposed) return;

      Navigator.of(context).pop();

      switch (index) {
        case 0:
          const AiChatScreen().launch(context);
          break;
        case 1:
          const JobsScreen().launch(context);
          break;
        case 2:
          const DrugsListScreen().launch(context);
          break;
        case 3:
          BlocProvider(
            create: (context) => DiscussionListBloc(
              repository: CaseDiscussionRepository(
                baseUrl: AppData.base2,
                getAuthToken: () => AppData.userToken ?? "",
              ),
            ),
            child: const DiscussionListScreen(),
          ).launch(context);
          break;
        case 4:
          const GuidelinesScreen().launch(context);
          break;
        case 5:
          const ConferencesScreen().launch(context);
          break;
        case 6:
          const ManageMeetingScreen().launch(context);
          break;
        case 7:
          const SuggestionScreen().launch(context);
          break;
        case 8:
          const AppSettingScreen().launch(context);
          break;
        case 9:
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
        case 10:
          AboutUsScreen().launch(context);
          break;
      }
    });
  }

  Future<void> logoutAccount(BuildContext context) async {
    if (!mounted || _isDisposed) return;

    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(l10n.lbl_logout),
          content: Text(l10n.msg_confirm_logout),
          actions: [
            TextButton(
              child: Text(l10n.lbl_cancel),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(
                l10n.lbl_yes,
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
                String deviceId = '';

                if (isAndroid) {
                  AndroidDeviceInfo androidInfo =
                      await deviceInfoPlugin.androidInfo;
                  deviceId = androidInfo.id;
                } else {
                  IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
                  deviceId = iosInfo.identifierForVendor.toString();
                }

                SharedPreferences prefs = await SharedPreferences.getInstance();
                var result = await logoutUserAccount(deviceId);

                if (mounted && !_isDisposed) {
                  AppSharedPreferences().clearSharedPreferencesData(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
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
      return response.statusCode == 200;
    } catch (error) {
      return false;
    }
  }

  Future<bool> logoutUserAccount(String deviceId) async {
    final apiUrl = Uri.parse('${AppData.remoteUrl}/logout');
    try {
      final response = await http.post(
        apiUrl,
        body: {'device_id': deviceId},
        headers: <String, String>{
          'Authorization': 'Bearer ${AppData.userToken!}',
        },
      );
      return response.statusCode == 200;
    } catch (error) {
      return false;
    }
  }
}

// Data class for menu items
class MenuItemData {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;

  const MenuItemData(this.index, this.icon, this.title, this.subtitle);
}

// Header pattern painter
class HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final y = (size.height / 8) * i;
      path.moveTo(0, y);
      path.quadraticBezierTo(size.width / 2, y + 10, size.width, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Curved element painter for splash screen style decorations
class CurvedElementPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4285F4).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Create a curved element similar to splash screen
    path.moveTo(size.width * 0.3, 0);
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.3,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.7, size.height);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.6,
      0,
      size.height * 0.3,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Add another subtle curved layer
    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.5, 0);
    path2.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.2,
      size.width,
      size.height * 0.6,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(size.width * 0.8, size.height);
    path2.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.4,
      size.width * 0.2,
      size.height * 0.1,
    );
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
