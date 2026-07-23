import 'package:device_info_plus/device_info_plus.dart';
import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/notification_counter_service.dart';
import 'package:doctak_app/core/notification_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/core/utils/app/app_shared_preferences.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/l10n/app_localizations.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/about_us/about_us_screen.dart';
import 'package:doctak_app/presentation/case_discussion/bloc/discussion_list_bloc.dart';
import 'package:doctak_app/presentation/case_discussion/repository/case_discussion_repository.dart';
import 'package:doctak_app/presentation/case_discussion/screens/discussion_list_screen.dart';
import 'package:doctak_app/presentation/cme_module/cme_main_screen.dart';
import 'package:doctak_app/presentation/diagnosis_module/diagnosis_main_screen.dart';
import 'package:doctak_app/presentation/doctak_ai_module/presentation/ai_chat_screen.dart';
import 'package:doctak_app/presentation/groups_module/groups_main_screen.dart';
import 'package:doctak_app/presentation/guideline_module/blocs/guideline_agent/guideline_agent_bloc.dart';
import 'package:doctak_app/presentation/guideline_module/presentation/guideline_agent_screen.dart';
import 'package:doctak_app/widgets/premium/premium_mark.dart';
import 'package:doctak_app/presentation/home_screen/home/components/drawer_icons.dart';
import 'package:doctak_app/presentation/settings/account_settings_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drugs_list_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/manage_meeting_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/moderation_screen/moderation_privacy_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/suggestion_screen.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';
import 'package:doctak_app/presentation/web_screen/web_page_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/workspace_switcher_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SVHomeDrawerComponent extends StatefulWidget {
  const SVHomeDrawerComponent({super.key});

  @override
  State<SVHomeDrawerComponent> createState() => _SVHomeDrawerComponentState();
}

class _SVHomeDrawerComponentState extends State<SVHomeDrawerComponent>
    with AutomaticKeepAliveClientMixin {
  static String? _cachedVersion;

  String _resolvedSpecialty = displaySpecialty(AppData.specialty);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _refreshSpecialtyLabel();
    ActingContextService.instance.addListener(_onActingChanged);
    // ignore: discarded_futures
    ActingContextService.instance.initialize();
    if (_cachedVersion == null) {
      PackageInfo.fromPlatform().then((info) {
        _cachedVersion = 'DocTak · Version ${info.version} (Build ${info.buildNumber})';
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    ActingContextService.instance.removeListener(_onActingChanged);
    super.dispose();
  }

  void _onActingChanged() {
    if (mounted) setState(() {});
  }

  ActingOrganization? get _actingOrg =>
      ActingContextService.instance.organization;

  Future<void> _refreshSpecialtyLabel() async {
    final resolved = await displaySpecialtyAsync(AppData.specialty);
    if (!mounted) return;
    if (resolved != _resolvedSpecialty) {
      setState(() => _resolvedSpecialty = resolved);
    }
    if (resolved.isNotEmpty && resolved != AppData.specialty) {
      AppData.specialty = resolved;
    }
  }

  List<_DrawerSection> _sections(BuildContext context) {
    final l10n = translation(context);
    return [
      _DrawerSection(
        title: 'CLINICAL PRACTICE',
        items: [
          _DrawerItem(1, DrawerIconAssets.jobs, l10n.lbl_jobs, l10n.desc_jobs),
          _DrawerItem(2, DrawerIconAssets.drugs, l10n.lbl_drugs, l10n.desc_drugs),
          _DrawerItem(4, DrawerIconAssets.guidelines, l10n.lbl_guidelines, l10n.desc_guidelines),
          _DrawerItem(14, DrawerIconAssets.cme, l10n.lbl_CME, l10n.lbl_cme_full),
          _DrawerItem(15, DrawerIconAssets.diagnosis, 'Diagnosis', 'AI Differential Diagnosis'),
        ],
      ),
      _DrawerSection(
        title: 'COMMUNITY',
        items: [
          _DrawerItem(3, DrawerIconAssets.discussions, l10n.lbl_discussions, l10n.desc_discussions),
          _DrawerItem(16, DrawerIconAssets.groups, 'Groups', 'Medical communities & specialty groups'),
          _DrawerItem(5, DrawerIconAssets.conferences, l10n.lbl_conferences, l10n.desc_conferences),
          _DrawerItem(6, DrawerIconAssets.meetings, l10n.lbl_meetings, l10n.desc_meetings),
          _DrawerItem(7, DrawerIconAssets.suggestions, l10n.lbl_suggestions, l10n.desc_suggestions),
        ],
      ),
      _DrawerSection(
        title: 'SYSTEM',
        items: [
          _DrawerItem(8, DrawerIconAssets.settings, l10n.lbl_settings, l10n.desc_settings),
          _DrawerItem(12, DrawerIconAssets.moderation, 'Moderation & Privacy', 'Blocked users, reports & safety'),
          _DrawerItem(9, DrawerIconAssets.privacy, l10n.lbl_privacy, l10n.desc_privacy),
          _DrawerItem(10, DrawerIconAssets.about, l10n.lbl_about, l10n.desc_about),
          _DrawerItem(13, DrawerIconAssets.star, 'My Subscription', 'Manage your plan & features'),
        ],
      ),
    ];
  }

  String get _displayName {
    final name = capitalizeWords(AppData.name);
    return AppData.userType == 'doctor' ? 'Dr. $name' : name;
  }

  String get _headerSubtitle {
    final org = _actingOrg;
    if (org == null) return _subtitleLine;
    final role = org.roleDisplay;
    return role.isEmpty ? org.typeDisplay : '${org.typeDisplay} · $role';
  }

  String get _subtitleLine {
    final specialty = _resolvedSpecialty.trim();
    final location = AppData.city.trim().isNotEmpty
        ? AppData.city.trim()
        : AppData.countryName.trim();
    if (specialty.isEmpty && location.isEmpty) return '';
    if (specialty.isEmpty) return location;
    if (location.isEmpty) return specialty;
    return '$specialty · $location';
  }

  int get _profileCompletionPercent {
    var filled = 0;
    const total = 5;
    if (AppData.name.trim().isNotEmpty) filled++;
    if (AppData.specialty.trim().isNotEmpty) filled++;
    if (AppData.profile_pic.trim().isNotEmpty) filled++;
    if (AppData.city.trim().isNotEmpty || AppData.countryName.trim().isNotEmpty) filled++;
    if ((AppData.userToken ?? '').isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = OneUITheme.of(context);

    return Drawer(
      key: const ValueKey('main_drawer'),
      elevation: 0,
      backgroundColor: theme.scaffoldBackground,
      width: MediaQuery.sizeOf(context).width * 0.88,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, theme),
            Expanded(child: _buildBody(context, theme)),
            _buildSignOutButton(context, theme),
            _buildVersionFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OneUITheme theme) {
    final acting = ActingContextService.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: theme.drawerHeaderGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close temporarily hidden — restore when needed.
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: _iconCircleButton(
            //     theme,
            //     onTap: () => Navigator.of(context).pop(),
            //     child: DrawerIcon(
            //       asset: DrawerIconAssets.close,
            //       size: 18,
            //       color: theme.textPrimary,
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _actingOrg != null
                    ? _buildOrgAvatar(theme, _actingOrg!)
                    : _buildAvatar(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _actingOrg?.name ?? _displayName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textPrimary,
                                      letterSpacing: -0.1,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_actingOrg == null &&
                                    AppData.isVerified) ...[
                                  const SizedBox(width: 4),
                                  theme.buildVerifiedBadge(
                                    size: 14,
                                    isPremium: AppData.isPremium,
                                  ),
                                ],
                                if (_actingOrg == null && AppData.isPremium) ...[
                                  const SizedBox(width: 4),
                                  const PremiumMark(size: 14),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          _iconCircleButton(
                            theme,
                            onTap: () {
                              Navigator.of(context).pop();
                              const AccountSettingsScreen().launch(context);
                            },
                            child: Icon(
                              Icons.settings_rounded,
                              size: 18,
                              color: theme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _iconCircleButton(
                            theme,
                            onTap: acting.isSwitching
                                ? () {}
                                : () => showWorkspaceSwitcherSheet(context),
                            child: acting.isSwitching
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.primary,
                                    ),
                                  )
                                : Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 18,
                                    color: theme.primary,
                                  ),
                          ),
                        ],
                      ),
                      if (_headerSubtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _headerSubtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.textSecondary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPlanCard(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(OneUITheme theme) {
    final isPremium = AppData.isPremium;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primary, theme.secondary],
            ),
            border: isPremium
                ? Border.all(color: PremiumStyle.gold, width: 2.5)
                : null,
            boxShadow: [
              if (isPremium)
                BoxShadow(
                  color: PremiumStyle.gold.withValues(alpha: 0.45),
                  blurRadius: 0,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: ValueListenableBuilder<String>(
              valueListenable: AppData.profilePicNotifier,
              builder: (context, picUrl, __) {
                final url = picUrl.isNotEmpty ? picUrl : AppData.profilePicUrl;
                return AppCachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: Text(
                      _initials(AppData.name),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Center(
                    child: Text(
                      _initials(AppData.name),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: theme.success,
              shape: BoxShape.circle,
              border: Border.all(color: theme.cardBackground, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrgAvatar(OneUITheme theme, ActingOrganization org) {
    final logo = (org.logoUrl != null && org.logoUrl!.isNotEmpty)
        ? AppData.fullImageUrl(org.logoUrl!)
        : '';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardBackground,
        border: Border.all(color: theme.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: logo.isNotEmpty
          ? AppCachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) =>
                  Icon(Icons.business_rounded, color: theme.primary, size: 26),
            )
          : Icon(Icons.business_rounded, color: theme.primary, size: 26),
    );
  }

  Widget _buildPlanCard(BuildContext context, OneUITheme theme) {
    final isPremium = AppData.isPremium;
    final planLabel = isPremium
        ? ((AppData.planName?.isNotEmpty == true) ? AppData.planName! : 'Premium')
        : 'Free Plan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isPremium
                  ? PremiumStyle.gold.withValues(alpha: 0.12)
                  : theme.accentSoft,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isPremium
                    ? PremiumStyle.gold.withValues(alpha: 0.35)
                    : theme.primary.withValues(alpha: 0.12),
              ),
            ),
            alignment: Alignment.center,
            child: isPremium
                ? const PremiumMark(size: 16)
                : DrawerIcon(
                    asset: DrawerIconAssets.star,
                    size: 18,
                    color: theme.primary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Profile $_profileCompletionPercent% complete',
                  style: TextStyle(fontSize: 12, color: theme.textSecondary),
                ),
              ],
            ),
          ),
          if (!isPremium)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                const SubscriptionScreen().launch(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Upgrade',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, OneUITheme theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildAiBanner(context, theme),
        ..._sections(context).expand((section) sync* {
          yield const SizedBox(height: 20);
          yield Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              section.title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: theme.textTertiary,
              ),
            ),
          );
          for (final item in section.items) {
            yield _buildMenuItem(context, theme, item);
          }
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAiBanner(BuildContext context, OneUITheme theme) {
    final l10n = translation(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).pop();
          const AiChatScreen().launch(context);
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primary, theme.accentInk],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                alignment: Alignment.center,
                child: DrawerIcon(
                  asset: DrawerIconAssets.doctakAi,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.lbl_medical_ai,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.desc_medical_ai,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              DrawerIcon(
                asset: DrawerIconAssets.chevronRight,
                size: 18,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, OneUITheme theme, _DrawerItem item) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleMenuTap(context, item.index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: theme.divider),
                ),
                alignment: Alignment.center,
                child: DrawerIcon(asset: item.iconAsset, size: 19, color: theme.textSecondary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(fontSize: 12, color: theme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              DrawerIcon(asset: DrawerIconAssets.chevronRight, size: 18, color: theme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, OneUITheme theme) {
    final l10n = translation(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _confirmLogout(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DrawerIcon(asset: DrawerIconAssets.signOut, size: 18, color: theme.error),
                const SizedBox(width: 8),
                Text(
                  l10n.lbl_logout,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: theme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionFooter(OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        _cachedVersion ?? 'DocTak',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10.5, color: theme.textTertiary, letterSpacing: 0.2),
      ),
    );
  }

  Widget _iconCircleButton(OneUITheme theme, {required VoidCallback onTap, required Widget child}) {
    return Material(
      color: theme.cardBackground,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.divider),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  void _handleMenuTap(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!context.mounted) return;
      switch (index) {
        case 1:
          const JobsScreen().launch(context);
        case 2:
          const DrugsListScreen().launch(context);
        case 3:
          BlocProvider(
            create: (_) => DiscussionListBloc(
              repository: CaseDiscussionRepository(
                baseUrl: AppData.base2,
                getAuthToken: () => AppData.userToken ?? '',
              ),
            ),
            child: const DiscussionListScreen(),
          ).launch(context);
        case 4:
          AppNavigator.push(
            context,
            BlocProvider(
              create: (_) => GuidelineAgentBloc(),
              child: const GuidelineAgentScreen(),
            ),
          );
        case 5:
          const ConferencesScreen().launch(context);
        case 6:
          const ManageMeetingScreen().launch(context);
        case 7:
          const SuggestionScreen().launch(context);
        case 8:
          const AccountSettingsScreen().launch(context);
        case 9:
          AppNavigator.push(
            context,
            WebPageScreen(
              pageName: AppLocalizations.of(context)!.lbl_privacy_policy,
              url: '${AppData.base}privacy-policy',
            ),
          );
        case 10:
          const AboutUsScreen().launch(context);
        case 12:
          const ModerationPrivacyScreen().launch(context);
        case 13:
          const SubscriptionScreen().launch(context);
        case 14:
          const CmeMainScreen().launch(context);
        case 15:
          const DiagnosisMainScreen().launch(context);
        case 16:
          const GroupsMainScreen().launch(context);
      }
    });
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = OneUITheme.of(context);

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded, color: theme.error, size: 28),
                ),
                const SizedBox(height: 16),
                Text(l10n.lbl_logout, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  l10n.msg_confirm_logout,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: theme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(l10n.lbl_cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: theme.error),
                        onPressed: () async {
                          final navigator = Navigator.of(dialogContext, rootNavigator: true);
                          Navigator.of(dialogContext).pop();
                          try {
                            await NotificationService.deregisterDeviceToken();
                            NotificationCounterService().dispose();
                            await ActingContextService.instance.clear();
                            final prefs = SecureStorageService.instance;
                            await prefs.initialize();
                            await AppSharedPreferences().clearSharedPreferencesData(dialogContext);
                          } catch (_) {}
                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                          _callLogoutApiInBackground();
                        },
                        child: Text(l10n.lbl_yes),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> logoutUserAccount(String deviceId) async {
    try {
      final fcmToken = AppData.deviceToken.trim();
      final response = await SharedApiService().logout(
        deviceId: deviceId,
        deviceToken: fcmToken.isNotEmpty ? fcmToken : null,
      );
      return response.success;
    } catch (_) {
      return false;
    }
  }

  void _callLogoutApiInBackground() {
    Future.microtask(() async {
      try {
        final deviceInfoPlugin = DeviceInfoPlugin();
        String deviceId = '';
        if (isAndroid) {
          deviceId = (await deviceInfoPlugin.androidInfo).id;
        } else {
          deviceId = (await deviceInfoPlugin.iosInfo).identifierForVendor.toString();
        }
        await logoutUserAccount(deviceId);
      } catch (_) {}
    });
  }
}

class _DrawerSection {
  final String title;
  final List<_DrawerItem> items;
  const _DrawerSection({required this.title, required this.items});
}

class _DrawerItem {
  final int index;
  final String iconAsset;
  final String title;
  final String subtitle;
  const _DrawerItem(this.index, this.iconAsset, this.title, this.subtitle);
}
