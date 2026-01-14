import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/about_us/about_us_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/app_setting_screen/app_setting_screen.dart';
import 'package:doctak_app/presentation/case_discussion/screens/discussion_list_screen.dart';
import 'package:doctak_app/presentation/case_discussion/bloc/discussion_list_bloc.dart';
import 'package:doctak_app/presentation/case_discussion/repository/case_discussion_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drugs_list_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/guidelines_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/suggestion_screen.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/web_screen/web_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:doctak_app/l10n/app_localizations.dart';
import 'dart:math' as math;

import '../../../../localization/app_localization.dart';
import '../../../doctak_ai_module/presentation/ai_chat_screen.dart';
import '../screens/meeting_screen/manage_meeting_screen.dart';

class SVHomeDrawerComponent extends StatefulWidget {
  const SVHomeDrawerComponent({super.key});

  @override
  State<SVHomeDrawerComponent> createState() => _SVHomeDrawerComponentState();
}

class _SVHomeDrawerComponentState extends State<SVHomeDrawerComponent>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  int selectedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isDisposed = false;

  // One UI 8.5 Color System - Complete
  static const Color _oneUIPrimary = Color(0xFF0A84FF);
  static const Color _oneUIPrimaryLight = Color(0xFF4DA3FF);

  // Background Colors
  static const Color _oneUIBackgroundDark = Color(0xFF0D1B2A);
  static const Color _oneUIBackgroundLight = Color(
    0xFFFFFFFF,
  ); // White like HTML

  // Surface Colors
  static const Color _oneUISurfaceDark = Color(0xFF1B2838);
  static const Color _oneUISurfaceLight = Color(0xFFFFFFFF);
  static const Color _oneUISurfaceVariantDark = Color(0xFF2D3E50);
  static const Color _oneUISurfaceVariantLight = Color(0xFFF0F0F0);
  static const Color _oneUISurfaceElevatedDark = Color(0xFF243447);
  static const Color _oneUISurfaceElevatedLight = Color(0xFFFAFAFA);

  // Text Colors
  static const Color _oneUITextPrimaryDark = Color(0xFFFFFFFF);
  static const Color _oneUITextPrimaryLight = Color(0xFF1C1C1E);
  static const Color _oneUITextSecondaryDark = Color(0xB3FFFFFF); // 70% white
  static const Color _oneUITextSecondaryLight = Color(0xFF8E8E93);
  static const Color _oneUITextTertiaryDark = Color(0x80FFFFFF); // 50% white
  static const Color _oneUITextTertiaryLight = Color(0xFFC7C7CC);

  // Divider & Border Colors
  static const Color _oneUIDividerDark = Color(0x1AFFFFFF); // 10% white
  static const Color _oneUIDividerLight = Color(0x1A000000); // 10% black
  static const Color _oneUIBorderDark = Color(0x33FFFFFF); // 20% white
  static const Color _oneUIBorderLight = Color(0x33000000); // 20% black

  // Semantic Colors
  static const Color _oneUISuccess = Color(0xFF34C759);
  static const Color _oneUIWarning = Color(0xFFFF9500);
  static const Color _oneUIError = Color(0xFFFF3B30);
  static const Color _oneUIInfo = Color(0xFF5AC8FA);

  // Accent Colors for menu sections
  static const Color _oneUIAccentBlue = Color(0xFF3B82F6);
  static const Color _oneUIAccentBlueBgLight = Color(0xFFEFF6FF);
  static const Color _oneUIAccentBlueBgDark = Color(0xFF1E3A5F);
  static const Color _oneUIAccentIndigo = Color(0xFF6366F1);
  static const Color _oneUIAccentIndigoBgLight = Color(0xFFEEF2FF);
  static const Color _oneUIAccentIndigoBgDark = Color(0xFF2D2B55);
  static const Color _oneUIAccentSlate = Color(0xFF64748B);
  static const Color _oneUIAccentSlateBgLight = Color(0xFFF1F5F9);
  static const Color _oneUIAccentSlateBgDark = Color(0xFF374151);

  // Helper to check dark mode
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // Helper getters for theme-aware colors
  Color get _backgroundColor =>
      _isDark ? _oneUIBackgroundDark : _oneUIBackgroundLight;
  Color get _surfaceColor => _isDark ? _oneUISurfaceDark : _oneUISurfaceLight;
  Color get _surfaceVariantColor =>
      _isDark ? _oneUISurfaceVariantDark : _oneUISurfaceVariantLight;
  Color get _surfaceElevatedColor =>
      _isDark ? _oneUISurfaceElevatedDark : _oneUISurfaceElevatedLight;
  Color get _textPrimaryColor =>
      _isDark ? _oneUITextPrimaryDark : _oneUITextPrimaryLight;
  Color get _textSecondaryColor =>
      _isDark ? _oneUITextSecondaryDark : _oneUITextSecondaryLight;
  Color get _textTertiaryColor =>
      _isDark ? _oneUITextTertiaryDark : _oneUITextTertiaryLight;
  Color get _dividerColor => _isDark ? _oneUIDividerDark : _oneUIDividerLight;
  Color get _borderColor => _isDark ? _oneUIBorderDark : _oneUIBorderLight;

  // Updated menu items with localization keys and icon color types
  static List<MenuSection> getMenuSections(BuildContext context) {
    final l10n = translation(context);
    return [
      MenuSection(
        title: "CLINICAL PRACTICE",
        iconColorType: IconColorType.blue,
        items: [
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
            4,
            Icons.description_outlined,
            l10n.lbl_guidelines,
            l10n.desc_guidelines,
          ),
        ],
      ),
      MenuSection(
        title: "COMMUNITY",
        iconColorType: IconColorType.indigo,
        items: [
          MenuItemData(
            3,
            Icons.forum_outlined,
            l10n.lbl_discussions,
            l10n.desc_discussions,
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
        ],
      ),
      MenuSection(
        title: "SYSTEM",
        iconColorType: IconColorType.slate,
        items: [
          MenuItemData(
            8,
            Icons.settings_outlined,
            l10n.lbl_settings,
            l10n.desc_settings,
          ),
          MenuItemData(
            9,
            Icons.shield_outlined,
            l10n.lbl_privacy,
            l10n.desc_privacy,
          ),
          MenuItemData(10, Icons.info_outline, l10n.lbl_about, l10n.desc_about),
          MenuItemData(
            11,
            Icons.logout,
            l10n.lbl_logout,
            l10n.desc_logout,
            isLogout: true,
          ),
        ],
      ),
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

    return SafeArea(
      child: Drawer(
        key: const ValueKey('main_drawer'),
        elevation: 0,
        backgroundColor: _backgroundColor,
        width: math.max(300, MediaQuery.of(context).size.width * 0.82),
        child: Column(
          children: [
            // Clean Header
            _buildCleanHeader(),

            // Menu Content
            Expanded(child: _buildCleanMenuContent()),

            // Simple Footer
            _buildSimpleFooter(),
          ],
        ),
      ),
    );
  }

  // Clean header matching HTML design - blue soft background
  Widget _buildCleanHeader() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: _isDark
            ? _oneUISurfaceDark
            : _oneUIAccentBlueBgLight, // bg-[var(--brand-bg-soft)] = #EFF6FF
        border: Border(
          bottom: BorderSide(
            color: _isDark
                ? _dividerColor
                : const Color(0xFFDBEAFE), // border-blue-100
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Gradient green circular avatar with initials matching HTML design
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_oneUISuccess, _oneUISuccess.withOpacity(0.7)],
                  ),
                  border: Border.all(color: _surfaceColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isDark ? 0.3 : 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: AppCachedNetworkImage(
                    imageUrl: AppData.imageUrl + AppData.profile_pic,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Text(
                        _getInitials(AppData.name),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        _getInitials(AppData.name),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Online status indicator
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _oneUISuccess,
                    shape: BoxShape.circle,
                    border: Border.all(color: _surfaceColor, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Name and specialty
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppData.userType == 'doctor'
                      ? 'Dr. ${capitalizeWords(AppData.name)}'
                      : capitalizeWords(AppData.name),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Blue specialty pill matching HTML design: bg-blue-100 text-blue-700
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? _oneUIPrimary.withOpacity(0.2)
                        : const Color(0xFFDBEAFE),  // bg-blue-100 for better visibility
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    AppData.userType == 'doctor'
                        ? AppData.specialty
                        : AppData.userType == 'student'
                        ? '${AppData.university} Student'
                        : AppData.specialty,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _isDark ? _oneUIPrimaryLight : const Color(0xFF1D4ED8),  // text-blue-700
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
    );
  }

  // Clean menu content matching HTML design
  Widget _buildCleanMenuContent() {
    final l10n = translation(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Doctak AI Card (special top item) - replacing Dashboard
        _buildDoctakAiCard(l10n),

        const SizedBox(height: 16),

        // Section headers and items
        ...getMenuSections(context).expand((section) {
          return [
            if (section.title != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                child: Text(
                  section.title!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textSecondaryColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ...section.items.map(
              (item) => _buildCleanMenuItem(item, section.iconColorType),
            ),
            const SizedBox(height: 8),
          ];
        }).toList(),

        // Bottom padding
        const SizedBox(height: 16),
      ],
    );
  }

  // Doctak AI card (special highlighted item) - replacing Dashboard
  Widget _buildDoctakAiCard(dynamic l10n) {
    // Matching HTML design: bg-blue-50/50 hover:bg-blue-50 with subtle border on hover
    final cardBgColor = _isDark
        ? _oneUIPrimary.withOpacity(0.06) // Subtle blue tint for dark mode
        : const Color(
            0xFFEFF6FF,
          ).withOpacity(0.5); // bg-blue-50/50 exactly like HTML

    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDark
              ? Colors.transparent
              : Colors.transparent, // border-transparent like HTML
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            const AiChatScreen().launch(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Blue icon container matching HTML: bg-[var(--brand-primary)] = #3B82F6
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        _oneUIAccentBlue, // #3B82F6 matching HTML brand-primary
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _oneUIAccentBlue.withOpacity(0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/docktak_ai_light.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.lbl_medical_ai,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.desc_medical_ai,
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Clean menu item matching HTML design with icon colors and badges
  Widget _buildCleanMenuItem(MenuItemData item, IconColorType colorType) {
    // Get colors based on type using One UI 8.5 color system
    Color iconBgColor;
    Color iconColor;

    if (item.isLogout) {
      iconBgColor = _isDark
          ? _oneUIError.withOpacity(0.15)
          : _oneUIError.withOpacity(0.12);
      iconColor = _oneUIError;
    } else {
      switch (colorType) {
        case IconColorType.blue:
          iconBgColor = _isDark
              ? _oneUIAccentBlueBgDark
              : _oneUIAccentBlueBgLight;
          iconColor = _isDark ? _oneUIPrimaryLight : _oneUIAccentBlue;
          break;
        case IconColorType.indigo:
          iconBgColor = _isDark
              ? _oneUIAccentIndigoBgDark
              : _oneUIAccentIndigoBgLight;
          iconColor = _isDark
              ? _oneUIAccentIndigo.withOpacity(0.85)
              : _oneUIAccentIndigo;
          break;
        case IconColorType.slate:
          iconBgColor = _isDark
              ? _oneUIAccentSlateBgDark
              : _oneUIAccentSlateBgLight;
          iconColor = _isDark ? _oneUITextSecondaryDark : _oneUIAccentSlate;
          break;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 4, top: item.isLogout ? 8 : 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _handleMenuTap(item.index),
          borderRadius: BorderRadius.circular(12),
          hoverColor: item.isLogout ? _oneUIError.withOpacity(0.1) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                // Icon in rounded container with proper colors
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: item.isLogout
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: item.isLogout
                              ? _oneUIError
                              : _textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: item.isLogout
                              ? _oneUIError.withOpacity(0.8)
                              : _textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge or Chevron
                if (item.showBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _oneUIError,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (!item.isLogout)
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: _textTertiaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Simple footer matching HTML design
  Widget _buildSimpleFooter() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _backgroundColor,
            border: Border(
              top: BorderSide(
                color: _isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: Text(
            snapshot.hasData
                ? 'Version ${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})'
                : 'DocTak',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _textTertiaryColor,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  // Colorful header with gradient and decorative elements + One UI 8.5 refinements
  Widget _buildColorfulHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    // Compact header height - avatar and name in one row
    final headerHeight = topPadding + 90;

    return SizedBox(
      key: const ValueKey('drawer_header'),
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Beautiful gradient background
          Container(
            height: headerHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isDark
                    ? [const Color(0xFF1B2838), const Color(0xFF0D1B2A)]
                    : [
                        Colors.white,
                        Colors.blue.shade50,
                        Colors.blue.shade100.withOpacity(0.5),
                      ],
              ),
            ),
          ),

          // Decorative curved elements
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _isDark
                      ? [
                          _oneUIPrimary.withOpacity(0.15),
                          _oneUIPrimary.withOpacity(0.05),
                          Colors.transparent,
                        ]
                      : [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                ),
              ),
            ),
          ),

          // Profile content - horizontal layout, centered vertically
          Positioned.fill(
            top: topPadding,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Profile avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4285F4),
                          Color(0xFF1A73E8),
                          Color(0xFF1557B0),
                        ],
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4285F4).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: AppCachedNetworkImage(
                        imageUrl: AppData.imageUrl + AppData.profile_pic,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            _buildColorfulInitialsAvatar(),
                        errorWidget: (context, url, error) =>
                            _buildColorfulInitialsAvatar(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Name and specialty - vertical stack
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User name - single line with ellipsis
                        Text(
                          AppData.userType == 'doctor'
                              ? 'Dr. ${capitalizeWords(AppData.name)}'
                              : capitalizeWords(AppData.name),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _isDark
                                ? Colors.white
                                : const Color(0xFF1A365D),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 6),

                        // Specialty pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _oneUIPrimary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            AppData.userType == 'doctor'
                                ? AppData.specialty
                                : AppData.userType == 'student'
                                ? '${AppData.university} ${translation(context).lbl_student}'
                                : AppData.specialty,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _oneUIPrimary,
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

  // Colorful initials avatar
  Widget _buildColorfulInitialsAvatar() {
    return Container(
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
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.0,
          ),
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
                    child: AppCachedNetworkImage(
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

    List<String> nameParts = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0]
          .substring(0, math.min(2, nameParts[0].length))
          .toUpperCase();
    } else {
      return 'U';
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
              decoration: BoxDecoration(
                color: _isDark ? _oneUIBackgroundDark : _oneUIBackgroundLight,
              ),
              child: ListView(
                key: const ValueKey('menu_list'),
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: getMenuSections(context).map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (section.title != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            section.title!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ...section.items
                          .map((item) => _buildColorfulMenuItem(item))
                          .toList(),
                      // Add divider after sections except the last one?
                      // For now, spacing is enough or maybe a divider.
                      if (section.title == null && section.items.isNotEmpty)
                        const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  // Clean, standard menu item logic
  Widget _buildColorfulMenuItem(MenuItemData item) {
    bool isSelected = selectedIndex == item.index;

    return Container(
      key: ValueKey('menu_item_${item.index}'),
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (_isDark
                  ? _oneUIPrimary.withOpacity(0.2)
                  : const Color(0xFFE8F0FE))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _handleMenuTap(item.index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Icon or Image
              SizedBox(
                width: 24,
                height: 24,
                child: item.imagePath != null
                    ? Image.asset(
                        item.imagePath!,
                        fit: BoxFit.contain,
                        color: isSelected
                            ? _oneUIPrimary
                            : (_isDark ? Colors.white70 : Colors.black54),
                      )
                    : Icon(
                        item.icon,
                        size: 22,
                        color: isSelected
                            ? _oneUIPrimary
                            : (_isDark ? Colors.white70 : Colors.black54),
                      ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? _oneUIPrimary
                        : (_isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              // Notification card style background
              color: isSelected ? Colors.blue.withOpacity(0.12) : Colors.white,
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
                    color: isSelected ? Colors.blue[700] : Colors.blue[600],
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
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color:
                                Theme.of(context).brightness == Brightness.dark
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

  // Colorful footer with One UI 8.5 refinements
  Widget _buildColorfulFooter(AppLocalizations l10n, bool isRtl) {
    return Container(
      key: const ValueKey('drawer_footer'),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (!_isDark)
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 6,
              offset: const Offset(0, -1),
            ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main button row
            Row(
              children: [
                // Version info with colorful styling
                Expanded(
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      return Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isDark
                                ? [
                                    _oneUIPrimary.withOpacity(0.2),
                                    _oneUIPrimary.withOpacity(0.1),
                                  ]
                                : [
                                    _oneUIPrimary.withOpacity(0.1),
                                    _oneUIPrimary.withOpacity(0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _oneUIPrimary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: _oneUIPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              snapshot.hasData
                                  ? "v${snapshot.data!.version}"
                                  : "DocTak",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _oneUIPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Home button with beautiful gradient
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFF1A73E8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4285F4).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
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

                const SizedBox(width: 8),

                // Logout button with colorful styling
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isDark
                        ? Colors.red.withOpacity(0.15)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(_isDark ? 0.4 : 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => logoutAccount(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Labels row
            Row(
              children: [
                Expanded(
                  child: Text(
                    translation(context).lbl_version,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  child: Text(
                    l10n.lbl_home,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _oneUIPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  child: Text(
                    l10n.lbl_logout,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // One UI 8.5 styled footer (kept for reference)
  Widget _buildOneUIFooter(AppLocalizations l10n, bool isRtl) {
    return Container(
      key: const ValueKey('drawer_footer'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark ? _oneUISurfaceDark : _oneUISurfaceLight,
        border: Border(
          top: BorderSide(
            color: _isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Button row
            Row(
              children: [
                // Version info
                Expanded(
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      return Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _isDark
                              ? _oneUISurfaceVariantDark
                              : _oneUISurfaceVariantLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: _isDark
                                  ? _oneUITextSecondaryDark
                                  : _oneUITextSecondaryLight,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              snapshot.hasData
                                  ? "v${snapshot.data!.version}"
                                  : "DocTak",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _isDark
                                    ? _oneUITextPrimaryDark
                                    : _oneUITextPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Home button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A84FF), Color(0xFF0066CC)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _oneUIPrimary.withOpacity(0.3),
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
                        size: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Logout button
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isDark
                        ? const Color(0xFFFF3B30).withOpacity(0.15)
                        : const Color(0xFFFF3B30).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF3B30).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => logoutAccount(context),
                      borderRadius: BorderRadius.circular(12),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFF3B30),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Labels row
            Row(
              children: [
                Expanded(
                  child: Text(
                    translation(context).lbl_version,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _isDark
                          ? _oneUITextSecondaryDark
                          : _oneUITextSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  child: Text(
                    l10n.lbl_home,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _oneUIPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  child: Text(
                    l10n.lbl_logout,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF3B30),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
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
                pageName: AppLocalizations.of(context)!.lbl_privacy_policy,
                url: '${AppData.base}privacy-policy',
              ),
            ),
          );
          break;
        case 10:
          const AboutUsScreen().launch(context);
          break;
        case 11:
          // Logout
          logoutAccount(context);
          break;
      }
    });
  }

  Future<void> logoutAccount(BuildContext context) async {
    if (!mounted || _isDisposed) return;

    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // OneUI 8.5 color palette
    final backgroundColor = isDark ? const Color(0xFF1B2838) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF666666);
    final destructive = isDark
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFE53935);
    final buttonBackground = isDark
        ? const Color(0xFF2A3A4A)
        : const Color(0xFFF5F5F5);

    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                // Logout icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: destructive.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: destructive,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  l10n.lbl_logout,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.msg_confirm_logout,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: Material(
                          color: buttonBackground,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                l10n.lbl_cancel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Logout button
                      Expanded(
                        child: Material(
                          color: destructive,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () async {
                              Navigator.of(dialogContext).pop();

                              DeviceInfoPlugin deviceInfoPlugin =
                                  DeviceInfoPlugin();
                              String deviceId = '';

                              if (isAndroid) {
                                AndroidDeviceInfo androidInfo =
                                    await deviceInfoPlugin.androidInfo;
                                deviceId = androidInfo.id;
                              } else {
                                IosDeviceInfo iosInfo =
                                    await deviceInfoPlugin.iosInfo;
                                deviceId = iosInfo.identifierForVendor
                                    .toString();
                              }

                              final prefs = SecureStorageService.instance;
                              await prefs.initialize();
                              await logoutUserAccount(deviceId);

                              if (mounted && !_isDisposed) {
                                AppSharedPreferences()
                                    .clearSharedPreferencesData(context);
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                l10n.lbl_yes,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
// Enum for icon color types
enum IconColorType { blue, indigo, slate }

class MenuItemData {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? imagePath;
  final bool showBadge;
  final bool isLogout;

  const MenuItemData(
    this.index,
    this.icon,
    this.title,
    this.subtitle, {
    this.imagePath,
    this.showBadge = false,
    this.isLogout = false,
  });
}

class MenuSection {
  final String? title;
  final List<MenuItemData> items;
  final IconColorType iconColorType;

  MenuSection({
    this.title,
    required this.items,
    this.iconColorType = IconColorType.blue,
  });
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
  final bool isDark;

  CurvedElementPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4285F4).withOpacity(isDark ? 0.15 : 0.08)
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
      ..color = (isDark ? Colors.white : Colors.white).withOpacity(
        isDark ? 0.1 : 0.5,
      )
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
  bool shouldRepaint(covariant CurvedElementPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
