import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/data/models/profile_model/full_profile_model.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/interested_info_screen/interested_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/privacy_info_screen/privacy_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/profile/components/my_post_component.dart';
import 'package:doctak_app/presentation/network_screen/network_screen.dart';
import 'package:doctak_app/data/models/profile_model/experience_model.dart';
import 'package:doctak_app/data/models/profile_model/education_detail_model.dart';
import 'package:doctak_app/data/models/profile_model/publication_model.dart';
import 'package:doctak_app/data/models/profile_model/award_model.dart';
import 'package:doctak_app/data/models/profile_model/medical_license_model.dart';
import 'package:doctak_app/data/models/profile_model/social_profile_model.dart';
import 'package:doctak_app/data/models/profile_model/business_hour_model.dart';
import 'package:doctak_app/core/utils/app/app_environment.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SVProfilePostsComponent extends StatefulWidget {
  ProfileBloc profileBloc;
  final bool viewAsPublic;

  SVProfilePostsComponent(this.profileBloc, {this.viewAsPublic = false, super.key});

  @override
  State<SVProfilePostsComponent> createState() =>
      _SVProfilePostsComponentState();
}

class _SVProfilePostsComponentState extends State<SVProfilePostsComponent>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 6-tab layout matching website profile
  static const List<_TabInfo> _tabIcons = [
    _TabInfo(Icons.person_rounded),
    _TabInfo(Icons.work_rounded),
    _TabInfo(Icons.school_rounded),
    _TabInfo(Icons.emoji_events_rounded),
    _TabInfo(Icons.science_rounded),
    _TabInfo(Icons.article_rounded),
  ];

  List<String> _tabLabels(BuildContext context) => [
    translation(context).lbl_about,
    translation(context).lbl_experience,
    translation(context).lbl_education,
    translation(context).lbl_portfolio,
    translation(context).lbl_research,
    translation(context).lbl_posts,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.scaffoldBackground),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tab Bar (clean underline style matching reference) ──
          Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackground,
              border: Border(
                bottom: BorderSide(
                  color: theme.border,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.only(top: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_tabIcons.length, (index) {
                  final labels = _tabLabels(context);
                  final isSelected = selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 28),
                    child: GestureDetector(
                      onTap: () {
                        _animationController.reset();
                        setState(() => selectedIndex = index);
                        _animationController.forward();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSelected
                                  ? theme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          labels[index],
                          style: TextStyle(
                            color: isSelected
                                ? theme.primary
                                : theme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Tab Content (rebuilt on bloc state changes) ──
          BlocBuilder<ProfileBloc, ProfileState>(
            bloc: widget.profileBloc,
            builder: (context, state) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: _buildTabContent(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedIndex) {
      case 0:
        return _AboutTab(profileBloc: widget.profileBloc, viewAsPublic: widget.viewAsPublic);
      case 1:
        return _ExperienceTab(profileBloc: widget.profileBloc);
      case 2:
        return _EducationTab(profileBloc: widget.profileBloc);
      case 3:
        return _PortfolioTab(profileBloc: widget.profileBloc);
      case 4:
        return _ResearchTab(profileBloc: widget.profileBloc);
      case 5:
        return MyPostComponent(widget.profileBloc);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TabInfo {
  final IconData icon;
  const _TabInfo(this.icon);
}

// ═══════════════════════════════════════════════
//  TAB 0: ABOUT
// ═══════════════════════════════════════════════

class _AboutTab extends StatelessWidget {
  final ProfileBloc profileBloc;
  final bool viewAsPublic;
  const _AboutTab({required this.profileBloc, this.viewAsPublic = false});

  /// Check privacy for a field. When viewAsPublic, hide fields that are
  /// not set to 'public'. Returns true if the field should be shown.
  bool _canView(String recordType) {
    // If this is the user's own profile and NOT viewing as public, show everything
    if (profileBloc.isMe && !viewAsPublic) return true;

    final privacySettings = profileBloc.fullProfile?.privacySettings;
    if (privacySettings == null || privacySettings.isEmpty) {
      // No privacy settings available; for viewAsPublic default to hidden,
      // for other users trust what the server sent (show if not null)
      return !viewAsPublic;
    }

    String visibility = (privacySettings[recordType] ?? 'public').toString();
    // Normalize legacy values
    if (visibility == 'lock') visibility = 'only_me';
    if (visibility == 'group') visibility = 'friends';

    if (viewAsPublic) {
      // Public view: only show fields with 'public' visibility
      return visibility == 'public';
    }

    // Viewing another user's profile
    final isFriend = profileBloc.fullProfile?.isFriend ?? false;
    if (visibility == 'only_me') return false;
    if (visibility == 'friends') return isFriend;
    return true; // public
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final fp = profileBloc.fullProfile;
    final profile = fp?.profile;
    final user = fp?.user;
    final contactInfo = fp?.contactInfo;

    // Build profile URL using username
    final username = user?.username ?? '';
    final profileUrl = username.isNotEmpty
        ? '${AppEnvironment.base2}/u/$username'
        : '';

    // Convenience flag for own-profile editing mode
    final isOwn = profileBloc.isMe && !viewAsPublic;

    // ── Data-existence helpers (independent of privacy) ──
    final hasEmail = contactInfo?['email'] != null &&
        (contactInfo!['email'] as String).isNotEmpty;
    final hasPhone = contactInfo?['phone'] != null &&
        (contactInfo!['phone'] as String).isNotEmpty;
    final hasLocation = user?.city != null || user?.country != null;
    final hasClinic = user?.clinicName != null && user!.clinicName!.isNotEmpty;
    final hasAnyContactData = hasEmail || hasPhone || hasLocation || hasClinic;
    final hasVisibleContact = (hasEmail && _canView('email')) ||
        (hasPhone && _canView('phone')) ||
        (hasLocation && _canView('country')) ||
        (hasClinic && _canView('clinic_name'));

    final hasAboutMe =
        profile?.aboutMe != null && profile!.aboutMe!.isNotEmpty;

    final hasSpecialty =
        user?.specialty != null && user!.specialty!.isNotEmpty;
    final hasLicenseNo =
        user?.licenseNo != null && user!.licenseNo!.isNotEmpty;
    final hasClinicProf =
        user?.clinicName != null && user!.clinicName!.isNotEmpty;
    final hasCollege = user?.college != null && user!.college!.isNotEmpty;
    final hasAnyProfData =
        hasSpecialty || hasLicenseNo || hasClinicProf || hasCollege;
    final hasVisibleProf = (hasSpecialty && _canView('specialty')) ||
        (hasLicenseNo && _canView('license_no')) ||
        (hasClinicProf && _canView('clinic_name')) ||
        hasCollege; // college has no privacy setting

    final hasGender = user?.gender != null && user!.gender!.isNotEmpty;
    final hasDob = user?.dob != null && user!.dob!.isNotEmpty;
    final hasBirthplace =
        profile?.birthplace != null && profile!.birthplace!.isNotEmpty;
    final hasLivesIn =
        profile?.livesIn != null && profile!.livesIn!.isNotEmpty;
    final hasAddr =
        profile?.address != null && profile!.address!.isNotEmpty;
    final hasLangs =
        profile?.languages != null && profile!.languages!.isNotEmpty;
    final hasCountryOrigin =
        user?.countryOrigin != null && user!.countryOrigin!.isNotEmpty;
    final hasJoined =
        user?.createdAt != null && user!.createdAt!.isNotEmpty;
    final hasAnyPersonalData = hasGender ||
        hasDob ||
        hasBirthplace ||
        hasLivesIn ||
        hasAddr ||
        hasLangs ||
        hasCountryOrigin ||
        hasJoined;
    final hasVisiblePersonal = (hasGender && _canView('gender')) ||
        (hasDob && _canView('dob')) ||
        (hasBirthplace && _canView('birthplace')) ||
        (hasLivesIn && _canView('lives_in')) ||
        (hasAddr && _canView('address')) ||
        (hasLangs && _canView('languages')) ||
        (hasCountryOrigin && _canView('country_origin')) ||
        hasJoined; // joined date has no privacy setting

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Profile Completion ──
          if (isOwn && (fp?.profileCompletionPercentage ?? 0) < 100)
            _ProfileCompletionCard(
              percentage: fp?.profileCompletionPercentage ?? 0,
              sections: fp?.profileCompletionSections,
            ),

          // ── View as Public banner ──
          if (viewAsPublic)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, color: theme.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You are viewing your profile as a public user',
                      style: theme.bodyMedium.copyWith(
                        color: theme.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Contact Info ──
          if (isOwn || hasAnyContactData)
            _SectionCard(
              title: translation(context).lbl_contact_info,
              icon: Icons.contact_mail_outlined,
              iconColor: theme.primary,
              actionLabel: isOwn ? translation(context).lbl_edit : null,
              onAction: isOwn
                  ? () => _showContactInfoForm(context, profileBloc)
                  : null,
              child: Column(
                children: [
                  // Privacy banner: data exists but ALL fields are restricted
                  if (!isOwn && hasAnyContactData && !hasVisibleContact)
                    const _PrivacyBanner()
                  else ...[
                    if (_canView('email') && hasEmail)
                      _ContactRow(
                        icon: Icons.email_outlined,
                        value: contactInfo!['email'] as String,
                        onTap: () => launchUrl(Uri.parse('mailto:${contactInfo['email']}')),
                      ),
                    if (_canView('phone') && hasPhone)
                      _ContactRow(
                        icon: Icons.phone_outlined,
                        value: contactInfo!['phone'] as String,
                        onTap: () => launchUrl(Uri.parse('tel:${contactInfo['phone']}')),
                      ),
                    if (_canView('country') && hasLocation)
                      _ContactRow(
                        icon: Icons.location_on_outlined,
                        value: [user?.city, user?.state, user?.country]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(', '),
                      ),
                    if (_canView('clinic_name') && hasClinic)
                      _ContactRow(
                        icon: Icons.local_hospital_outlined,
                        value: user!.clinicName!,
                      ),
                    if (isOwn && !hasAnyContactData)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(translation(context).msg_no_contact_info,
                            style: TextStyle(color: theme.textSecondary, fontSize: 13)),
                      ),
                  ],
                ],
              ),
            ),

          // ── About Me section ──
          if (isOwn || hasAboutMe)
            _SectionCard(
              title: translation(context).lbl_about_me,
              icon: Icons.person_outline,
              iconColor: theme.primary,
              actionLabel: isOwn ? translation(context).lbl_edit : null,
              onAction: isOwn
                  ? () => _showAboutMeForm(context, profileBloc)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasAboutMe && !_canView('about_me'))
                    const _PrivacyBanner()
                  else if (hasAboutMe)
                    Text(profile!.aboutMe!,
                        style: theme.bodyMedium.copyWith(
                            color: theme.textSecondary,
                            height: 1.6))
                  else if (isOwn)
                    Text(translation(context).msg_tell_about_yourself,
                        style: TextStyle(color: theme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

          // ── Professional Information ──
          if (isOwn || hasAnyProfData)
            _SectionCard(
              title: translation(context).lbl_professional_information,
              icon: Icons.medical_services_outlined,
              iconColor: theme.primary,
              actionLabel: isOwn ? translation(context).lbl_edit : null,
              onAction: isOwn
                  ? () => _showProfessionalInfoForm(context, profileBloc)
                  : null,
              child: Column(
                children: [
                  if (!isOwn && hasAnyProfData && !hasVisibleProf)
                    const _PrivacyBanner()
                  else ...[
                    if (_canView('specialty') && hasSpecialty)
                      _InfoRow(icon: Icons.medical_services_outlined, label: translation(context).lbl_specialty, value: user!.specialty!),
                    if (_canView('license_no') && hasLicenseNo)
                      _InfoRow(icon: Icons.badge_outlined, label: translation(context).lbl_license_no, value: user!.licenseNo!),
                    if (_canView('clinic_name') && hasClinicProf)
                      _InfoRow(icon: Icons.local_hospital_outlined, label: translation(context).lbl_clinic_workplace, value: user!.clinicName!),
                    if (hasCollege)
                      _InfoRow(icon: Icons.school_outlined, label: translation(context).lbl_education_info, value: user!.college!),
                    if (isOwn && !hasAnyProfData)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(translation(context).msg_add_professional_info,
                            style: TextStyle(color: theme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                      ),
                  ],
                ],
              ),
            ),

          // ── Personal Details ──
          // ── Personal Details ──
          if (isOwn || hasAnyPersonalData)
            _SectionCard(
              title: translation(context).lbl_personal_details,
              icon: Icons.person_outline_rounded,
              iconColor: theme.primary,
              actionLabel: isOwn ? translation(context).lbl_edit : null,
              onAction: isOwn
                  ? () => _showPersonalDetailsForm(context, profileBloc)
                  : null,
              child: Column(
                children: [
                  if (!isOwn && hasAnyPersonalData && !hasVisiblePersonal)
                    const _PrivacyBanner()
                  else ...[
                    if (_canView('gender') && hasGender)
                      _InfoRow(icon: Icons.wc_outlined, label: translation(context).lbl_gender, value: user!.gender![0].toUpperCase() + user.gender!.substring(1)),
                    if (_canView('dob') && hasDob)
                      _InfoRow(icon: Icons.cake_outlined, label: translation(context).lbl_birthday, value: user!.dob!),
                    if (_canView('birthplace') && hasBirthplace)
                      _InfoRow(icon: Icons.place_outlined, label: translation(context).lbl_from, value: profile!.birthplace!),
                    if (_canView('lives_in') && hasLivesIn)
                      _InfoRow(icon: Icons.apartment_outlined, label: translation(context).lbl_lives_in, value: profile!.livesIn!),
                    if (_canView('address') && hasAddr)
                      _InfoRow(icon: Icons.home_outlined, label: translation(context).lbl_address, value: profile!.address!),
                    if (_canView('languages') && hasLangs)
                      _InfoRow(icon: Icons.language_rounded, label: translation(context).lbl_languages, value: profile!.languages!),
                    if (_canView('country_origin') && hasCountryOrigin)
                      _InfoRow(icon: Icons.flag_outlined, label: translation(context).lbl_country_of_origin, value: user!.countryOrigin!),
                    if (hasJoined)
                      _InfoRow(icon: Icons.calendar_today_outlined, label: translation(context).lbl_joined, value: user!.createdAt!.substring(0, 10)),
                    if (isOwn && !hasAnyPersonalData)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(translation(context).msg_add_personal_details,
                            style: TextStyle(color: theme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                      ),
                  ],
                ],
              ),
            ),

          // ── Medical Licenses (from Portfolio data) ──
          if (profileBloc.licenses.isNotEmpty)
            _SectionCard(
              title: translation(context).lbl_medical_licenses,
              icon: Icons.verified_outlined,
              iconColor: theme.success,
              child: Column(
                children: profileBloc.licenses.map((lic) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_outlined, size: 18, color: theme.success),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lic.licenseType ?? translation(context).lbl_license,
                                  style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w500, fontSize: 13, color: theme.textPrimary)),
                              Text('${lic.licenseNumber ?? ''} • ${lic.issuingAuthority ?? ''}',
                                  style: theme.caption.copyWith(color: theme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Social Links ──
          if (profileBloc.socialProfiles.isNotEmpty || isOwn)
            _SectionCard(
              title: translation(context).lbl_social_links,
              icon: Icons.link_rounded,
              iconColor: theme.primary,
              actionLabel: isOwn ? translation(context).lbl_add : null,
              onAction: isOwn
                  ? () => _showSocialProfileForm(context, profileBloc)
                  : null,
              child: Column(
                children: [
                  if (profileBloc.socialProfiles.isEmpty && isOwn)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        translation(context).msg_add_social_profiles,
                        style: theme.bodyMedium.copyWith(
                          fontSize: 13,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  ...profileBloc.socialProfiles.map((sp) {
                    return _SocialLinkRow(
                      profile: sp,
                      isMe: isOwn,
                      onEdit: isOwn
                          ? () => _showSocialProfileForm(context, profileBloc, existing: sp)
                          : null,
                      onDelete: isOwn
                          ? () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(translation(context).lbl_delete_social_link),
                                  content: Text(translation(context).msg_remove_social_link(sp.displayPlatform)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(translation(context).lbl_cancel),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final idToDelete = sp.id!;
                                        Navigator.pop(ctx);
                                        _safeBlocAdd(profileBloc, DeleteSocialProfileEvent(id: idToDelete));
                                      },
                                      child: Text(translation(context).lbl_delete, style: TextStyle(color: theme.error)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          : null,
                    );
                  }),
                ],
              ),
            ),

          // ── Business Hours ──
          if (isOwn || profileBloc.businessHours.isNotEmpty)
            _SectionCard(
              title: translation(context).lbl_business_hours,
              icon: Icons.access_time_rounded,
              iconColor: theme.warning,
              trailing: isOwn
                  ? IconButton(
                      icon: Icon(Icons.add_circle_outline, color: theme.primary, size: 20),
                      onPressed: () => _showBusinessHourForm(context, profileBloc),
                    )
                  : null,
              child: Column(
                children: [
                  ...profileBloc.businessHours.map((bh) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(bh.displayDay,
                                style: theme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: theme.textPrimary)),
                          ),
                          Expanded(
                            child: Text(
                              bh.isAvailable == true
                                  ? bh.displayTimeRange
                                  : translation(context).lbl_closed,
                              style: theme.bodyMedium.copyWith(
                                fontSize: 13,
                                color: bh.isAvailable == true
                                    ? theme.textSecondary
                                    : theme.error,
                              ),
                            ),
                          ),
                          if (isOwn)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _showBusinessHourForm(context, profileBloc, existing: bh),
                                  child: Icon(Icons.edit_outlined, size: 16, color: theme.textSecondary),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _safeBlocAdd(profileBloc, DeleteBusinessHourEvent(id: bh.id!)),
                                  child: Icon(Icons.delete_outline, size: 16, color: theme.error),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                  if (profileBloc.businessHours.isEmpty && isOwn)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(translation(context).msg_no_business_hours,
                          style: theme.bodyMedium.copyWith(
                              fontSize: 13,
                              color: theme.textSecondary)),
                    ),
                ],
              ),
            ),

          // ── Share Profile (QR code) ──
          if (profileUrl.isNotEmpty)
            _ShareProfileCard(profileUrl: profileUrl, username: username),

          // ── Quick Settings (Network, Interests & Privacy) ──
          if (isOwn) ...[
            const SizedBox(height: 8),
            _NavigationCard(
              icon: Icons.people_alt_rounded,
              iconColor: theme.primary,
              backgroundColor: theme.primary.withValues(alpha: 0.08),
              title: translation(context).lbl_my_network,
              onTap: () => const NetworkScreen().launch(context),
            ),
            const SizedBox(height: 8),
            _NavigationCard(
              icon: Icons.interests_rounded,
              iconColor: theme.primary,
              backgroundColor: theme.primary.withValues(alpha: 0.08),
              title: translation(context).lbl_interests_hobbies,
              onTap: () => InterestedInfoScreen(profileBloc: profileBloc).launch(context),
            ),
            const SizedBox(height: 8),
            _NavigationCard(
              icon: Icons.lock_outline_rounded,
              iconColor: theme.error,
              backgroundColor: theme.error.withValues(alpha: 0.08),
              title: translation(context).lbl_privacy_settings,
              onTap: () => PrivacyInfoScreen(profileBloc: profileBloc).launch(context),
            ),
            const SizedBox(height: 8),
            _NavigationCard(
              icon: Icons.visibility_outlined,
              iconColor: theme.warning,
              backgroundColor: theme.warning.withValues(alpha: 0.08),
              title: 'View Profile as Public',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SVProfileFragment(userId: AppData.logInUserId, viewAsPublic: true),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isPersonalDetailEmpty(FullProfileUser? user, FullProfileInfo? profile) {
    return (user?.gender == null || user!.gender!.isEmpty) &&
        (user?.dob == null || user!.dob!.isEmpty) &&
        (profile?.birthplace == null || profile!.birthplace!.isEmpty) &&
        (profile?.livesIn == null || profile!.livesIn!.isEmpty) &&
        (profile?.address == null || profile!.address!.isEmpty) &&
        (profile?.languages == null || profile!.languages!.isEmpty);
  }
}

// ═══════════════════════════════════════════════
//  TAB 1: EXPERIENCE
// ═══════════════════════════════════════════════

class _ExperienceTab extends StatelessWidget {
  final ProfileBloc profileBloc;
  const _ExperienceTab({required this.profileBloc});

  @override
  Widget build(BuildContext context) {
    final items = profileBloc.experiences;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderWithAction(
            title: translation(context).lbl_experience,
            addLabel: translation(context).lbl_add,
            onAdd: () => _showExperienceForm(context, profileBloc),
            isMe: profileBloc.isMe,
          ),
          if (items.isEmpty)
            _EmptySection(
              icon: Icons.work_off_rounded,
              message: translation(context).msg_no_experience,
            )
          else
            ...items.map((exp) => _ExperienceCard(
                  experience: exp,
                  profileBloc: profileBloc,
                  isMe: profileBloc.isMe,
                )),
        ],
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final ExperienceModel experience;
  final ProfileBloc profileBloc;
  final bool isMe;

  const _ExperienceCard(
      {required this.experience, required this.profileBloc, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.primary.withValues(alpha: 0.15)
                        : theme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.work_rounded, size: 22, color: theme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(experience.position ?? translation(context).lbl_position,
                          style: theme.titleSmall.copyWith(
                              color: theme.textPrimary)),
                      if (experience.organization != null)
                        Text(experience.organization!,
                            style: theme.bodySecondary.copyWith(
                                color: theme.textSecondary)),
                    ],
                  ),
                ),
                if (isMe)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _showExperienceForm(context, profileBloc,
                            existing: experience);
                      } else if (v == 'delete') {
                        profileBloc
                            .add(DeleteExperienceEvent(id: experience.id!));
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(translation(context).lbl_edit)),
                      PopupMenuItem(
                          value: 'delete', child: Text(translation(context).lbl_delete)),
                    ],
                    icon: Icon(Icons.more_vert,
                        size: 20, color: theme.textSecondary),
                  ),
              ],
            ),
            if (experience.location != null &&
                experience.location!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: theme.textSecondary),
                const SizedBox(width: 4),
                Text(experience.location!,
                    style: theme.caption.copyWith(
                        color: theme.textSecondary)),
              ]),
            ],
            if (experience.displayDateRange.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: theme.textSecondary),
                const SizedBox(width: 4),
                Text(experience.displayDateRange,
                    style: theme.caption.copyWith(
                        color: theme.textSecondary)),
              ]),
            ],
            if (experience.description != null &&
                experience.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(experience.description!,
                  style: theme.bodySecondary.copyWith(
                      color: theme.textPrimary,
                      height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 2: EDUCATION
// ═══════════════════════════════════════════════

class _EducationTab extends StatelessWidget {
  final ProfileBloc profileBloc;
  const _EducationTab({required this.profileBloc});

  @override
  Widget build(BuildContext context) {
    final items = profileBloc.educationList;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderWithAction(
            title: translation(context).lbl_education,
            addLabel: translation(context).lbl_add,
            onAdd: () => _showEducationForm(context, profileBloc),
            isMe: profileBloc.isMe,
          ),
          if (items.isEmpty)
            _EmptySection(
                icon: Icons.school_outlined,
                message: translation(context).msg_no_education)
          else
            ...items.map((edu) => _EducationCard(
                  education: edu,
                  profileBloc: profileBloc,
                  isMe: profileBloc.isMe,
                )),
        ],
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  final EducationDetailModel education;
  final ProfileBloc profileBloc;
  final bool isMe;

  const _EducationCard(
      {required this.education, required this.profileBloc, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.school_rounded,
                      size: 20, color: theme.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(education.degree ?? translation(context).lbl_degree,
                          style: theme.titleSmall.copyWith(
                              color: theme.textPrimary)),
                      Text(education.displayInstitution,
                          style: theme.bodySecondary.copyWith(
                              color: theme.textSecondary)),
                    ],
                  ),
                ),
                if (isMe)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _showEducationForm(context, profileBloc,
                            existing: education);
                      } else if (v == 'delete') {
                        profileBloc
                            .add(DeleteEducationEvent(id: education.id!));
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(translation(context).lbl_edit)),
                      PopupMenuItem(
                          value: 'delete', child: Text(translation(context).lbl_delete)),
                    ],
                    icon: Icon(Icons.more_vert,
                        size: 20, color: theme.textSecondary),
                  ),
              ],
            ),
            if (education.fieldOfStudy != null &&
                education.fieldOfStudy!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(translation(context).lbl_field_prefix(education.fieldOfStudy!),
                  style: theme.caption.copyWith(
                      color: theme.textSecondary)),
            ],
            if (education.displayYearRange.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: theme.textSecondary),
                const SizedBox(width: 4),
                Text(education.displayYearRange,
                    style: theme.caption.copyWith(
                        color: theme.textSecondary)),
              ]),
            ],
            if (education.gpa != null && education.gpa!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(translation(context).lbl_grade_gpa_prefix(education.gpa!),
                  style: theme.caption.copyWith(
                      color: theme.textSecondary)),
            ],
            if (education.location != null &&
                education.location!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: theme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(education.location!,
                      style: theme.caption.copyWith(
                          color: theme.textSecondary)),
                ),
              ]),
            ],
            if (education.specialization != null &&
                education.specialization!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(translation(context).lbl_specialization_prefix(education.specialization!),
                  style: theme.caption.copyWith(
                      color: theme.textSecondary)),
            ],
            if (education.honors != null &&
                education.honors!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(translation(context).lbl_honors_awards_prefix(education.honors!),
                  style: theme.caption.copyWith(
                      color: Colors.amber[700])),
            ],
            if (education.activities != null &&
                education.activities!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(translation(context).lbl_activities_prefix(education.activities!),
                  style: theme.caption.copyWith(
                      color: theme.textSecondary)),
            ],
            if (education.description != null &&
                education.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(education.description!,
                  style: theme.bodySecondary.copyWith(
                      color: theme.textPrimary,
                      height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 3: PORTFOLIO (Awards + Licenses)
// ═══════════════════════════════════════════════

class _PortfolioTab extends StatelessWidget {
  final ProfileBloc profileBloc;
  const _PortfolioTab({required this.profileBloc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Awards section
          _SectionHeaderWithAction(
            title: translation(context).lbl_awards_and_recognitions,
            addLabel: translation(context).lbl_add,
            onAdd: () => _showAwardForm(context, profileBloc),
            isMe: profileBloc.isMe,
          ),
          if (profileBloc.awards.isEmpty)
            _EmptySection(
                icon: Icons.emoji_events_outlined,
                message: translation(context).msg_no_awards)
          else
            ...profileBloc.awards.map((a) => _AwardCard(
                  award: a,
                  profileBloc: profileBloc,
                  isMe: profileBloc.isMe,
                )),

          const SizedBox(height: 20),

          // Licenses section
          _SectionHeaderWithAction(
            title: translation(context).lbl_medical_licenses,
            addLabel: translation(context).lbl_add,
            onAdd: () => _showLicenseForm(context, profileBloc),
            isMe: profileBloc.isMe,
          ),
          if (profileBloc.licenses.isEmpty)
            _EmptySection(
                icon: Icons.badge_outlined,
                message: translation(context).msg_no_licenses)
          else
            ...profileBloc.licenses.map((l) => _LicenseCard(
                  license: l,
                  profileBloc: profileBloc,
                  isMe: profileBloc.isMe,
                )),
        ],
      ),
    );
  }
}

class _AwardCard extends StatelessWidget {
  final AwardModel award;
  final ProfileBloc profileBloc;
  final bool isMe;

  const _AwardCard(
      {required this.award, required this.profileBloc, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.emoji_events_rounded,
                  size: 20, color: theme.warning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(award.awardName ?? '',
                      style: theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary)),
                  if (award.awardingBody != null)
                    Text(award.awardingBody!,
                        style: theme.caption.copyWith(
                            color: theme.textSecondary)),
                  if (award.dateReceived != null)
                    Text(award.dateReceived!,
                        style: theme.caption.copyWith(
                            fontSize: 11,
                            color: theme.textSecondary)),
                  if (award.level != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(award.level!,
                            style: theme.caption.copyWith(
                                fontSize: 11,
                                color: Colors.amber[800],
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  if (award.description != null &&
                      award.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(award.description!,
                          style: theme.caption.copyWith(
                              color: theme.textPrimary,
                              height: 1.4)),
                    ),
                ],
              ),
            ),
            if (isMe)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') {
                    _showAwardForm(context, profileBloc, existing: award);
                  } else if (v == 'delete') {
                    _safeBlocAdd(profileBloc, DeleteAwardEvent(id: award.id!));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(translation(context).lbl_edit)),
                  PopupMenuItem(value: 'delete', child: Text(translation(context).lbl_delete)),
                ],
                icon:
                    Icon(Icons.more_vert, size: 20, color: theme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  final MedicalLicenseModel license;
  final ProfileBloc profileBloc;
  final bool isMe;

  const _LicenseCard(
      {required this.license,
      required this.profileBloc,
      required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.badge_rounded,
                  size: 20, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(license.licenseType ?? '',
                      style: theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary)),
                  if (license.licenseNumber != null)
                    Text('# ${license.licenseNumber!}',
                        style: theme.caption.copyWith(
                            color: theme.textSecondary)),
                  if (license.issuingAuthority != null)
                    Text(license.issuingAuthority!,
                        style: theme.caption.copyWith(
                            color: theme.textSecondary)),
                  Row(
                    children: [
                      if (license.issueDate != null)
                        Text(translation(context).lbl_issued_prefix(license.issueDate!),
                            style: theme.caption.copyWith(
                                fontSize: 11,
                                color: theme.textSecondary)),
                      if (license.expiryDate != null)
                        Text(' | ${translation(context).lbl_expires_prefix(license.expiryDate!)}',
                            style: theme.caption.copyWith(
                              fontSize: 11,
                              color: license.isExpired
                                  ? theme.error
                                  : theme.textSecondary,
                            )),
                    ],
                  ),
                ],
              ),
            ),
            if (isMe)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') {
                    _showLicenseForm(context, profileBloc, existing: license);
                  } else if (v == 'delete') {
                    _safeBlocAdd(profileBloc, DeleteLicenseEvent(id: license.id!));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(translation(context).lbl_edit)),
                  PopupMenuItem(value: 'delete', child: Text(translation(context).lbl_delete)),
                ],
                icon:
                    Icon(Icons.more_vert, size: 20, color: theme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 4: RESEARCH (Publications)
// ═══════════════════════════════════════════════

class _ResearchTab extends StatelessWidget {
  final ProfileBloc profileBloc;
  const _ResearchTab({required this.profileBloc});

  @override
  Widget build(BuildContext context) {
    final items = profileBloc.publications;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderWithAction(
            title: translation(context).lbl_publications,
            addLabel: translation(context).lbl_add,
            onAdd: () => _showPublicationForm(context, profileBloc),
            isMe: profileBloc.isMe,
          ),
          if (items.isEmpty)
            _EmptySection(
                icon: Icons.science_outlined,
                message: translation(context).msg_no_publications)
          else
            ...items.map((pub) => _PublicationCard(
                  publication: pub,
                  profileBloc: profileBloc,
                  isMe: profileBloc.isMe,
                )),
        ],
      ),
    );
  }
}

class _PublicationCard extends StatelessWidget {
  final PublicationModel publication;
  final ProfileBloc profileBloc;
  final bool isMe;

  const _PublicationCard(
      {required this.publication,
      required this.profileBloc,
      required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.article_rounded,
                      size: 20, color: theme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(publication.title ?? '',
                          style: theme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary)),
                      if (publication.journalName != null)
                        Text(publication.journalName!,
                            style: theme.caption.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.textSecondary)),
                    ],
                  ),
                ),
                if (isMe)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _showPublicationForm(context, profileBloc,
                            existing: publication);
                      } else if (v == 'delete') {
                        _safeBlocAdd(profileBloc,
                            DeletePublicationEvent(id: publication.id!));
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text(translation(context).lbl_edit)),
                      PopupMenuItem(
                          value: 'delete', child: Text(translation(context).lbl_delete)),
                    ],
                    icon: Icon(Icons.more_vert,
                        size: 20, color: theme.textSecondary),
                  ),
              ],
            ),
            if (publication.publicationDate != null) ...[
              const SizedBox(height: 4),
              Text(translation(context).lbl_published_prefix(publication.publicationDate!),
                  style: theme.caption.copyWith(
                      fontSize: 11,
                      color: theme.textSecondary)),
            ],
            if (publication.coAuthor != null &&
                publication.coAuthor!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(translation(context).lbl_co_authors_prefix(publication.coAuthor!),
                  style: theme.caption.copyWith(
                      color: theme.textSecondary)),
            ],
            // Impact & Citations row
            if (publication.impactFactor != null ||
                publication.citations != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (publication.impactFactor != null)
                    _MetricChip(
                        label: translation(context).lbl_impact_factor_short,
                        value: publication.impactFactor!,
                        color: Colors.blue),
                  if (publication.impactFactor != null &&
                      publication.citations != null)
                    const SizedBox(width: 8),
                  if (publication.citations != null)
                    _MetricChip(
                        label: translation(context).lbl_citations,
                        value: publication.citations!,
                        color: Colors.green),
                ],
              ),
            ],
            if (publication.keywords != null &&
                publication.keywords!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: publication.keywords!.split(',').map((k) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(k.trim(),
                        style: theme.caption.copyWith(
                            fontSize: 11,
                            color: theme.textSecondary)),
                  );
                }).toList(),
              ),
            ],
            if (publication.abstract_ != null &&
                publication.abstract_!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(publication.abstract_!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.caption.copyWith(
                      color: theme.textPrimary,
                      height: 1.4)),
            ],
            if (publication.doiLink != null &&
                publication.doiLink!.isNotEmpty) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final url = publication.doiLink!.startsWith('http')
                      ? publication.doiLink!
                      : 'https://${publication.doiLink!}';
                  final uri = Uri.tryParse(url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.link, size: 14, color: theme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        publication.doiLink!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.caption.copyWith(
                          color: theme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.iconColor,
      required this.child,
      this.actionLabel,
      this.onAction,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (outside the card, matching reference)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: theme.titleMedium),
              ),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(actionLabel!,
                      style: theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primary)),
                ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        // Card body
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border),
            boxShadow: theme.isDark
                ? null
                : [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 85,
            child: Text(label,
                style: theme.bodySecondary),
          ),
          Expanded(
            child: Text(value,
                style: theme.bodyMedium.copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  PRIVACY RESTRICTION BANNER (LinkedIn-style)
// ═══════════════════════════════════════════════
class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.textSecondary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline, size: 14, color: theme.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translation(context).msg_privacy_restricted,
                  style: theme.bodyMedium.copyWith(
                    color: theme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  translation(context).msg_privacy_restricted_detail,
                  style: theme.caption.copyWith(
                    color: theme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  CONTACT ROW
// ═══════════════════════════════════════════════
class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback? onTap;

  const _ContactRow({required this.icon, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: onTap != null ? theme.primary : theme.textPrimary)),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 14, color: theme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  PROFILE COMPLETION CARD
// ═══════════════════════════════════════════════
class _ProfileCompletionCard extends StatelessWidget {
  final int percentage;
  final Map<String, dynamic>? sections;

  const _ProfileCompletionCard({required this.percentage, this.sections});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
        boxShadow: theme.isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 20, color: percentage >= 100 ? Colors.green : Colors.orange[700]),
              const SizedBox(width: 8),
              Text(translation(context).lbl_profile_completion,
                  style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: theme.textPrimary)),
              const Spacer(),
              Text('$percentage%',
                  style: theme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: percentage >= 80 ? Colors.green : (percentage >= 50 ? Colors.orange : Colors.red),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 6,
              backgroundColor: theme.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 80 ? Colors.green : (percentage >= 50 ? Colors.orange : Colors.red),
              ),
            ),
          ),
          if (sections != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: sections!.entries.map((entry) {
                final isDone = (entry.value as num?) != null && (entry.value as num) > 0;
                return Chip(
                  label: Text(
                    _localizedSectionName(context, entry.key),
                    style: TextStyle(fontSize: 11, color: isDone ? Colors.green[800] : theme.textSecondary),
                  ),
                  avatar: Icon(isDone ? Icons.check_circle : Icons.circle_outlined,
                      size: 14, color: isDone ? Colors.green : theme.textSecondary),
                  backgroundColor: isDone
                      ? Colors.green.withValues(alpha: 0.1)
                      : (theme.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _localizedSectionName(BuildContext context, String key) {
    final map = {
      'about_me': translation(context).lbl_section_about_me,
      'professional': translation(context).lbl_section_professional,
      'basic_info': translation(context).lbl_section_basic_info,
      'skills': translation(context).lbl_section_skills,
      'social_links': translation(context).lbl_section_social_links,
      'photo': translation(context).lbl_section_photo,
    };
    return map[key] ?? key.replaceAll('_', ' ');
  }
}

// ═══════════════════════════════════════════════
//  SHARE PROFILE CARD (QR Code)
// ═══════════════════════════════════════════════
class _ShareProfileCard extends StatelessWidget {
  final String profileUrl;
  final String username;

  const _ShareProfileCard({required this.profileUrl, required this.username});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(translation(context).lbl_share_profile,
                style: theme.titleSmall.copyWith(
                    fontSize: 16,
                    color: theme.textPrimary)),
            const SizedBox(height: 4),
            Text(translation(context).msg_scan_profile_qr,
                style: theme.caption.copyWith(
                    color: theme.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),

            // QR Code
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: QrImageView(
                data: profileUrl,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1565C0),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // URL display + Copy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.scaffoldBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(profileUrl,
                        style: theme.caption.copyWith(
                            color: theme.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: profileUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(translation(context).msg_profile_link_copied),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.primary),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(translation(context).lbl_copy,
                          style: theme.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme.primary)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Open & Share buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    launchUrl(Uri.parse(profileUrl), mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.open_in_browser, size: 16),
                  label: Text(translation(context).lbl_open, style: theme.bodySecondary),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary,
                    side: BorderSide(color: theme.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(ShareParams(
                      text: translation(context).msg_share_profile_text(profileUrl),
                    ));
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: Text(translation(context).lbl_share, style: theme.bodySecondary),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary,
                    side: BorderSide(color: theme.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLinkRow extends StatelessWidget {
  final SocialProfileModel profile;
  final bool isMe;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _SocialLinkRow({required this.profile, this.isMe = false, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return InkWell(
      onTap: () {
        final url = profile.effectiveUrl;
        if (url.isNotEmpty) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(_getPlatformIcon(profile.platform),
                size: 18, color: theme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.displayPlatform,
                      style: theme.bodySecondary.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.w500)),
                  if (profile.username != null && profile.username!.isNotEmpty)
                    Text('@${profile.username}',
                        style: theme.caption.copyWith(
                            fontSize: 11,
                            color: theme.textSecondary)),
                ],
              ),
            ),
            if (isMe) ...[
              InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 16, color: theme.textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                ),
              ),
            ] else
              Icon(Icons.open_in_new, size: 14, color: theme.textSecondary),
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'linkedin':
        return Icons.business_rounded;
      case 'twitter':
        return Icons.chat_bubble_outline;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'website':
        return Icons.language_rounded;
      default:
        return Icons.link_rounded;
    }
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: $value',
          style: theme.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        children: [
          Icon(icon, size: 48, color: theme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(message,
              style: theme.bodyMedium.copyWith(
                  color: theme.textSecondary)),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.primary, width: 1),
          borderRadius: BorderRadius.circular(8),
          color: theme.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: theme.primary),
            const SizedBox(width: 4),
            Text(label,
                style: theme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primary)),
          ],
        ),
      ),
    );
  }
}

/// Section header with optional inline add button
class _SectionHeaderWithAction extends StatelessWidget {
  final String title;
  final String? addLabel;
  final VoidCallback? onAdd;
  final bool isMe;

  const _SectionHeaderWithAction({
    required this.title,
    this.addLabel,
    this.onAdd,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
          if (isMe && addLabel != null && onAdd != null)
            _AddButton(label: addLabel!, onTap: onAdd!),
        ],
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? backgroundColor.withValues(alpha: 0.15)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: theme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  BOTTOM SHEET FORMS (CRUD)
// ═══════════════════════════════════════════════

/// Safe wrapper to dispatch bloc events. Prevents crashes when the bloc
/// has been closed or the event handler was deregistered (e.g. during
/// widget disposal, navigation, or hot-reload).
void _safeBlocAdd(ProfileBloc bloc, ProfileEvent event) {
  try {
    if (bloc.isClosed) return;
    bloc.add(event);
  } catch (e) {
    // Swallow StateError from closed bloc – UI already moved on.
    debugPrint('_safeBlocAdd: swallowed error for ${event.runtimeType}: $e');
  }
}

// ── Contact Info Edit Form ──
void _showContactInfoForm(BuildContext context, ProfileBloc bloc) {
  final user = bloc.fullProfile?.user;
  final phoneCtrl = TextEditingController(text: user?.phone ?? '');
  final cityCtrl = TextEditingController(text: user?.city ?? '');
  final clinicCtrl = TextEditingController(text: user?.clinicName ?? '');

  // For country/state dropdowns
  List<Countries> countries = [];
  List<String> states = [];
  String selectedCountry = user?.country ?? '';
  String selectedState = user?.state ?? '';
  bool isLoadingCountries = true;
  bool isLoadingStates = false;
  bool _sheetMounted = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx2, setSheetState) {
          // Safe setState wrapper to prevent calling after disposal
          void safeSetState(VoidCallback fn) {
            if (_sheetMounted) setSheetState(fn);
          }

          // Load countries on first build
          if (isLoadingCountries && countries.isEmpty) {
            bloc.getCountries().then((list) {
              if (list != null) {
                safeSetState(() {
                  countries = list;
                  isLoadingCountries = false;
                });
                // If we have a pre-selected country, load its states
                if (selectedCountry.isNotEmpty && _sheetMounted) {
                  safeSetState(() => isLoadingStates = true);
                  bloc.getStates(selectedCountry).then((stateList) {
                    safeSetState(() {
                      states = stateList ?? [];
                      isLoadingStates = false;
                    });
                  });
                }
              } else {
                safeSetState(() => isLoadingCountries = false);
              }
            });
          }

          return _FormBottomSheet(
            title: translation(context).lbl_edit_contact_info,
            onSave: () {
              final phone = phoneCtrl.text;
              final city = cityCtrl.text;
              final state = selectedState;
              final country = selectedCountry;
              final clinic = clinicCtrl.text;
              _sheetMounted = false;
              Navigator.pop(ctx);
              _safeBlocAdd(bloc, UpdateProfileV5Event(
                phone: phone.isNotEmpty ? phone : null,
                city: city.isNotEmpty ? city : null,
                state: state.isNotEmpty ? state : null,
                country: country.isNotEmpty ? country : null,
                clinicName: clinic.isNotEmpty ? clinic : null,
              ));
            },
            children: [
              _FormField(label: translation(context).lbl_phone, controller: phoneCtrl),
              _FormField(label: translation(context).lbl_city, controller: cityCtrl),
              // Country searchable dropdown
              _SearchableDropdownField(
                label: translation(context).lbl_country,
                value: selectedCountry,
                items: countries.map((c) => c.countryName ?? '').where((s) => s.isNotEmpty).toList(),
                isLoading: isLoadingCountries,
                onSelected: (val) {
                  safeSetState(() {
                    selectedCountry = val;
                    selectedState = '';
                    states = [];
                    isLoadingStates = true;
                  });
                  bloc.getStates(val).then((stateList) {
                    safeSetState(() {
                      states = stateList ?? [];
                      isLoadingStates = false;
                    });
                  });
                },
              ),
              // State searchable dropdown
              _SearchableDropdownField(
                label: translation(context).lbl_state_province,
                value: selectedState,
                items: states,
                isLoading: isLoadingStates,
                allowManualInput: true,
                onSelected: (val) {
                  safeSetState(() => selectedState = val);
                },
              ),
              _FormField(label: translation(context).lbl_clinic_workplace, controller: clinicCtrl),
            ],
          );
        },
      );
    },
  ).whenComplete(() {
    _sheetMounted = false;
  });
}

// ── About Me Edit Form ──
void _showAboutMeForm(BuildContext context, ProfileBloc bloc) {
  final profile = bloc.fullProfile?.profile;
  final aboutMeCtrl = TextEditingController(text: profile?.aboutMe ?? '');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _FormBottomSheet(
        title: translation(context).lbl_edit_about_me,
        onSave: () {
          final aboutMe = aboutMeCtrl.text;
          Navigator.pop(ctx);
          _safeBlocAdd(bloc, UpdateAboutMeV5Event(
            aboutMe: aboutMe,
          ));
        },
        children: [
          _FormField(label: translation(context).lbl_about_me, controller: aboutMeCtrl, maxLines: 5),
        ],
      );
    },
  );
}

// ── Professional Info Edit Form ──
void _showProfessionalInfoForm(BuildContext context, ProfileBloc bloc) {
  final user = bloc.fullProfile?.user;
  String selectedSpecialty = user?.specialty ?? '';
  final licenseCtrl = TextEditingController(text: user?.licenseNo ?? '');
  final clinicCtrl = TextEditingController(text: user?.clinicName ?? '');
  final collegeCtrl = TextEditingController(text: user?.college ?? '');

  List<String> specialties = [];
  bool isLoadingSpecialties = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx2, setSheetState) {
          // Load specialties on first build
          if (isLoadingSpecialties && specialties.isEmpty) {
            bloc.getSpecialties().then((list) {
              setSheetState(() {
                specialties = (list ?? []).where((s) => s != 'Select Specialty').toList();
                isLoadingSpecialties = false;
              });
            });
          }

          return _FormBottomSheet(
            title: translation(context).lbl_edit_professional_info,
            onSave: () {
              final specialty = selectedSpecialty;
              final license = licenseCtrl.text;
              final clinic = clinicCtrl.text;
              final college = collegeCtrl.text;
              Navigator.pop(ctx);
              _safeBlocAdd(bloc, UpdateProfileV5Event(
                specialty: specialty.isNotEmpty ? specialty : null,
                licenseNo: license.isNotEmpty ? license : null,
                clinicName: clinic.isNotEmpty ? clinic : null,
                college: college.isNotEmpty ? college : null,
              ));
            },
            children: [
              _SearchableDropdownField(
                label: translation(context).lbl_specialty,
                value: selectedSpecialty,
                items: specialties,
                isLoading: isLoadingSpecialties,
                onSelected: (val) {
                  setSheetState(() => selectedSpecialty = val);
                },
              ),
              _FormField(label: translation(context).lbl_license_number, controller: licenseCtrl),
              _FormField(label: translation(context).lbl_clinic_workplace, controller: clinicCtrl),
              _FormField(label: translation(context).lbl_education_college, controller: collegeCtrl),
            ],
          );
        },
      );
    },
  );
}

// ── Personal Details Edit Form ──
void _showPersonalDetailsForm(BuildContext context, ProfileBloc bloc) {
  final user = bloc.fullProfile?.user;
  final profile = bloc.fullProfile?.profile;
  final firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
  final lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
  final dobCtrl = TextEditingController(text: user?.dob ?? '');
  String selectedGender = user?.gender ?? 'male';
  final birthplaceCtrl = TextEditingController(text: profile?.birthplace ?? '');
  final livesInCtrl = TextEditingController(text: profile?.livesIn ?? '');
  final addressCtrl = TextEditingController(text: profile?.address ?? '');
  final languagesCtrl = TextEditingController(text: profile?.languages ?? '');
  // Country/State hidden — already in Contact Info
  // String selectedCountryOrigin = user?.countryOrigin ?? '';
  // String selectedStateOrigin = user?.stateOrigin ?? '';
  // List<Countries> countries = [];
  // List<String> statesOrigin = [];
  // bool isLoadingCountries = true;
  // bool isLoadingStates = false;
  bool _sheetMounted = true;

  Future<void> _pickDob() async {
    final initial = dobCtrl.text.isNotEmpty
        ? (DateTime.tryParse(dobCtrl.text) ?? DateTime(1990))
        : DateTime(1990);
    final picked = await _showOneUIDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      dobCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx2, setSheetState) {
          // Country loading removed — handled in Contact Info

          return _FormBottomSheet(
            title: translation(context).lbl_edit_personal_details,
            onSave: () {
              // Capture all values before popping
              final firstName = firstNameCtrl.text;
              final lastName = lastNameCtrl.text;
              final dob = dobCtrl.text;
              final gender = selectedGender;
              final birthplace = birthplaceCtrl.text;
              final livesIn = livesInCtrl.text;
              final address = addressCtrl.text;
              final languages = languagesCtrl.text;
              _sheetMounted = false;
              Navigator.pop(ctx);
              _safeBlocAdd(bloc, UpdateProfileV5Event(
                firstName: firstName.isNotEmpty ? firstName : null,
                lastName: lastName.isNotEmpty ? lastName : null,
                dob: dob.isNotEmpty ? dob : null,
                gender: gender.isNotEmpty ? gender : null,
              ));
              _safeBlocAdd(bloc, UpdateAboutMeV5Event(
                birthplace: birthplace.isNotEmpty ? birthplace : null,
                livesIn: livesIn.isNotEmpty ? livesIn : null,
                address: address.isNotEmpty ? address : null,
                languages: languages.isNotEmpty ? languages : null,
              ));
            },
            children: [
              _FormField(label: translation(context).lbl_first_name_required, controller: firstNameCtrl),
              _FormField(label: translation(context).lbl_last_name_required, controller: lastNameCtrl),
              _DatePickerField(
                label: translation(context).lbl_date_of_birth,
                controller: dobCtrl,
                onTap: _pickDob,
              ),
              // Gender dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: selectedGender,
                  items: ['male', 'female', 'other'].map((g) {
                    final genderLabels = {
                      'male': translation(ctx2).lbl_male,
                      'female': translation(ctx2).lbl_female,
                      'other': translation(ctx2).lbl_other_gender,
                    };
                    return DropdownMenuItem(
                      value: g,
                      child: Text(genderLabels[g] ?? g,
                          style: OneUITheme.of(ctx2).bodyMedium),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setSheetState(() => selectedGender = val ?? 'male');
                  },
                  decoration: OneUITheme.of(ctx2).inputDecoration(label: translation(ctx2).lbl_gender),
                ),
              ),
              _FormField(label: translation(context).lbl_birthplace, controller: birthplaceCtrl),
              _FormField(label: translation(context).lbl_lives_in, controller: livesInCtrl),
              _FormField(label: translation(context).lbl_address, controller: addressCtrl),
              _FormField(label: translation(context).lbl_languages, controller: languagesCtrl),
              // Country of Origin & State hidden — already in Contact Info
              // _SearchableDropdownField(
              //   label: 'Country of Origin',
              //   ...
              // ),
              // _SearchableDropdownField(
              //   label: 'State / Province',
              //   ...
              // ),
            ],
          );
        },
      );
    },
  ).whenComplete(() {
    _sheetMounted = false;
  });
}

void _showExperienceForm(BuildContext context, ProfileBloc bloc,
    {ExperienceModel? existing}) {
  final positionCtrl =
      TextEditingController(text: existing?.position ?? '');
  final companyCtrl =
      TextEditingController(text: existing?.organization ?? '');
  final locationCtrl =
      TextEditingController(text: existing?.location ?? '');
  // Normalize existing date to YYYY-MM for display
  String _normalizeToYearMonth(String? date) {
    if (date == null || date.isEmpty) return '';
    // If YYYY-MM-DD, strip day
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(date)) return date.substring(0, 7);
    // If YYYY-MM, keep
    if (RegExp(r'^\d{4}-\d{2}$').hasMatch(date)) return date;
    // If just a year
    if (RegExp(r'^\d{4}$').hasMatch(date)) return '$date-01';
    return date;
  }
  final startDateCtrl =
      TextEditingController(text: _normalizeToYearMonth(existing?.startDate));
  final endDateCtrl = TextEditingController(
      text: existing?.isCurrentlyWorking == true
          ? ''
          : _normalizeToYearMonth(existing?.endDate));
  final descCtrl =
      TextEditingController(text: existing?.description ?? '');
  bool isEditing = existing != null;

  Future<void> _pickDate(TextEditingController ctrl) async {
    final initial = ctrl.text.isNotEmpty
        ? (DateTime.tryParse('${ctrl.text}-01') ?? DateTime.now())
        : DateTime.now();
    final picked = await _showOneUIDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _FormBottomSheet(
        title: isEditing ? translation(context).lbl_edit_experience : translation(context).lbl_add_experience,
        onSave: () {
          if (positionCtrl.text.isEmpty || companyCtrl.text.isEmpty) return;
          if (startDateCtrl.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(translation(context).msg_select_start_date)),
            );
            return;
          }
          final position = positionCtrl.text;
          final company = companyCtrl.text;
          final startDate = startDateCtrl.text;
          final endDate = endDateCtrl.text.isEmpty ? null : endDateCtrl.text;
          final location = locationCtrl.text;
          final desc = descCtrl.text;
          final editId = isEditing ? existing!.id! : null;
          Navigator.pop(ctx);
          if (editId != null) {
            _safeBlocAdd(bloc, UpdateExperienceEvent(
              id: editId,
              position: position,
              companyName: company,
              startDate: startDate,
              endDate: endDate,
              location: location,
              description: desc,
            ));
          } else {
            _safeBlocAdd(bloc, StoreExperienceEvent(
              position: position,
              companyName: company,
              startDate: startDate,
              endDate: endDate,
              location: location,
              description: desc,
            ));
          }
        },
        children: [
          _FormField(label: translation(context).lbl_position_required, controller: positionCtrl),
          _FormField(label: translation(context).lbl_company_required, controller: companyCtrl),
          _FormField(label: translation(context).lbl_location, controller: locationCtrl),
          _DatePickerField(
              label: translation(context).lbl_start_date_required,
              controller: startDateCtrl,
              onTap: () => _pickDate(startDateCtrl)),
          _DatePickerField(
              label: translation(context).lbl_end_date_present,
              controller: endDateCtrl,
              onTap: () => _pickDate(endDateCtrl)),
          _FormField(
              label: translation(context).lbl_description,
              controller: descCtrl,
              maxLines: 3),
        ],
      );
    },
  );
}

void _showEducationForm(BuildContext context, ProfileBloc bloc,
    {EducationDetailModel? existing}) {
  final degreeCtrl =
      TextEditingController(text: existing?.degree ?? '');
  final institutionCtrl =
      TextEditingController(text: existing?.displayInstitution ?? '');
  final fieldCtrl =
      TextEditingController(text: existing?.fieldOfStudy ?? '');
  final startYearCtrl =
      TextEditingController(text: existing?.startYear?.toString() ?? '');
  final endYearCtrl =
      TextEditingController(text: existing?.endYear?.toString() ?? '');
  final gpaCtrl = TextEditingController(text: existing?.gpa ?? existing?.grade ?? '');
  final honorsCtrl =
      TextEditingController(text: existing?.honors ?? '');
  final descCtrl =
      TextEditingController(text: existing?.description ?? '');
  final locationCtrl =
      TextEditingController(text: existing?.location ?? '');
  final specializationCtrl =
      TextEditingController(text: existing?.specialization ?? '');
  final activitiesCtrl =
      TextEditingController(text: existing?.activities ?? '');
  bool isEditing = existing != null;
  bool currentlyStudying = existing?.isCurrentlyStudying ?? false;

  Future<void> _pickYear(TextEditingController ctrl) async {
    final initialYear = int.tryParse(ctrl.text) ?? DateTime.now().year;
    final picked = await _showOneUIDatePicker(
      context: context,
      initialDate: DateTime(initialYear),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      ctrl.text = picked.year.toString();
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          return _FormBottomSheet(
            title: isEditing ? translation(context).lbl_edit_education : translation(context).lbl_add_education,
            onSave: () {
              if (degreeCtrl.text.isEmpty || institutionCtrl.text.isEmpty) return;
              final degree = degreeCtrl.text;
              final institution = institutionCtrl.text;
              final fieldOfStudy = fieldCtrl.text;
              final startYear = int.tryParse(startYearCtrl.text) ?? 2020;
              final endYear = currentlyStudying ? null : int.tryParse(endYearCtrl.text);
              final currentStudy = currentlyStudying;
              final gpa = gpaCtrl.text;
              final honors = honorsCtrl.text;
              final desc = descCtrl.text;
              final location = locationCtrl.text;
              final specialization = specializationCtrl.text;
              final activities = activitiesCtrl.text;
              final editId = isEditing ? existing!.id! : null;
              Navigator.pop(ctx);
              if (editId != null) {
                _safeBlocAdd(bloc, UpdateEducationDetailEvent(
                  id: editId,
                  degree: degree,
                  institution: institution,
                  fieldOfStudy: fieldOfStudy,
                  startYear: startYear,
                  endYear: endYear,
                  currentStudy: currentStudy,
                  gpa: gpa,
                  honors: honors,
                  description: desc,
                  location: location,
                  specialization: specialization,
                  activities: activities,
                ));
              } else {
                _safeBlocAdd(bloc, StoreEducationEvent(
                  degree: degree,
                  institution: institution,
                  fieldOfStudy: fieldOfStudy,
                  startYear: startYear,
                  endYear: endYear,
                  currentStudy: currentStudy,
                  gpa: gpa,
                  honors: honors,
                  description: desc,
                  location: location,
                  specialization: specialization,
                  activities: activities,
                ));
              }
            },
            children: [
              _FormField(label: translation(context).lbl_degree_required, controller: degreeCtrl),
              _FormField(label: translation(context).lbl_field_of_study, controller: fieldCtrl),
              _FormField(label: translation(context).lbl_institution_required, controller: institutionCtrl),
              _FormField(label: translation(context).lbl_grade_gpa, controller: gpaCtrl),
              _DatePickerField(
                  label: translation(context).lbl_start_year_required,
                  controller: startYearCtrl,
                  onTap: () => _pickYear(startYearCtrl)),
              if (!currentlyStudying)
                _DatePickerField(
                    label: translation(context).lbl_end_year,
                    controller: endYearCtrl,
                    onTap: () => _pickYear(endYearCtrl)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: currentlyStudying,
                      onChanged: (v) {
                        setModalState(() {
                          currentlyStudying = v ?? false;
                          if (currentlyStudying) endYearCtrl.clear();
                        });
                      },
                    ),
                    Text(translation(context).lbl_currently_studying,
                      style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              _FormField(label: translation(context).lbl_location, controller: locationCtrl),
              _FormField(label: translation(context).lbl_specialization, controller: specializationCtrl),
              _FormField(label: translation(context).lbl_description, controller: descCtrl, maxLines: 3),
              _FormField(label: translation(context).lbl_activities_societies, controller: activitiesCtrl),
              _FormField(label: translation(context).lbl_honors_awards, controller: honorsCtrl),
            ],
          );
        },
      );
    },
  );
}

void _showPublicationForm(BuildContext context, ProfileBloc bloc,
    {PublicationModel? existing}) {
  final titleCtrl =
      TextEditingController(text: existing?.title ?? '');
  final journalCtrl =
      TextEditingController(text: existing?.journalName ?? '');
  final dateCtrl =
      TextEditingController(text: existing?.publicationDate ?? '');
  final coAuthorCtrl =
      TextEditingController(text: existing?.coAuthor ?? '');
  final abstractCtrl =
      TextEditingController(text: existing?.abstract_ ?? '');
  final keywordsCtrl =
      TextEditingController(text: existing?.keywords ?? '');
  final impactCtrl =
      TextEditingController(text: existing?.impactFactor ?? '');

  Future<void> _pickPublicationDate() async {
    final initial = dateCtrl.text.isNotEmpty
        ? (DateTime.tryParse('${dateCtrl.text}-01') ?? DateTime.now())
        : DateTime.now();
    final picked = await _showOneUIDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      dateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
    }
  }
  final citationsCtrl =
      TextEditingController(text: existing?.citations ?? '');
  final doiLinkCtrl =
      TextEditingController(text: existing?.doiLink ?? '');
  bool isEditing = existing != null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _FormBottomSheet(
        title: isEditing ? translation(context).lbl_edit_publication : translation(context).lbl_add_publication,
        onSave: () {
          if (titleCtrl.text.isEmpty || journalCtrl.text.isEmpty) return;
          final title = titleCtrl.text;
          final journal = journalCtrl.text;
          final pubDate = dateCtrl.text;
          final coAuthor = coAuthorCtrl.text;
          final abstract_ = abstractCtrl.text;
          final keywords = keywordsCtrl.text;
          final impact = impactCtrl.text;
          final citations = citationsCtrl.text;
          final doiLink = doiLinkCtrl.text;
          final editId = isEditing ? existing!.id! : null;
          Navigator.pop(ctx);
          if (editId != null) {
            _safeBlocAdd(bloc, UpdatePublicationEvent(
              id: editId,
              title: title,
              journalName: journal,
              publicationDate: pubDate,
              coAuthor: coAuthor,
              abstract_: abstract_,
              keywords: keywords,
              impactFactor: impact,
              citations: citations,
              doiLink: doiLink,
            ));
          } else {
            _safeBlocAdd(bloc, StorePublicationEvent(
              title: title,
              journalName: journal,
              publicationDate: pubDate,
              coAuthor: coAuthor,
              abstract_: abstract_,
              keywords: keywords,
              impactFactor: impact,
              citations: citations,
              doiLink: doiLink,
            ));
          }
        },
        children: [
          _FormField(label: translation(context).lbl_title_required, controller: titleCtrl),
          _FormField(label: translation(context).lbl_journal_name_required, controller: journalCtrl),
          _DatePickerField(
              label: translation(context).lbl_publication_date,
              controller: dateCtrl,
              onTap: _pickPublicationDate),
          _FormField(label: translation(context).lbl_co_authors, controller: coAuthorCtrl),
          _FormField(
              label: translation(context).lbl_abstract, controller: abstractCtrl, maxLines: 3),
          _FormField(
              label: translation(context).lbl_keywords_comma,
              controller: keywordsCtrl),
          _FormField(label: translation(context).lbl_impact_factor, controller: impactCtrl),
          _FormField(label: translation(context).lbl_citations, controller: citationsCtrl),
          _FormField(label: translation(context).lbl_doi_link, controller: doiLinkCtrl),
        ],
      );
    },
  );
}

void _showSocialProfileForm(BuildContext context, ProfileBloc bloc,
    {SocialProfileModel? existing}) {
  final urlCtrl = TextEditingController(text: existing?.effectiveUrl ?? '');
  final usernameCtrl = TextEditingController(text: existing?.username ?? '');
  bool isEditing = existing != null;
  String selectedPlatform = existing?.platform ?? SocialProfileModel.availablePlatforms.first;
  bool isPublic = existing?.isPublic ?? true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx2, setSheetState) {
          return _FormBottomSheet(
            title: isEditing ? translation(context).lbl_edit_social_link : translation(context).lbl_add_social_link,
            onSave: () {
              if (urlCtrl.text.isEmpty) return;
              final platform = selectedPlatform;
              final profileUrl = urlCtrl.text.trim();
              final username = usernameCtrl.text.trim().isNotEmpty
                  ? usernameCtrl.text.trim()
                  : null;
              final public_ = isPublic;
              final editId = isEditing ? existing!.id! : null;
              Navigator.pop(ctx);
              if (editId != null) {
                _safeBlocAdd(bloc, UpdateSocialProfileEvent(
                  id: editId,
                  platform: platform,
                  profileUrl: profileUrl,
                  username: username,
                  isPublic: public_,
                ));
              } else {
                _safeBlocAdd(bloc, StoreSocialProfileEvent(
                  platform: platform,
                  profileUrl: profileUrl,
                  username: username,
                  isPublic: public_,
                ));
              }
            },
            children: [
              // Platform dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: selectedPlatform,
                  decoration: OneUITheme.of(ctx2).inputDecoration(label: translation(ctx2).lbl_platform_required),
                  items: SocialProfileModel.availablePlatforms.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        _displayPlatformName(ctx2, p),
                        style: OneUITheme.of(ctx2).bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setSheetState(() => selectedPlatform = v);
                  },
                ),
              ),
              _FormField(label: translation(context).lbl_profile_url_required, controller: urlCtrl),
              _FormField(label: translation(context).lbl_username_optional, controller: usernameCtrl),
              // Public toggle
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SwitchListTile(
                  title: Text(translation(ctx2).lbl_visible_to_others,
                      style: OneUITheme.of(ctx2).bodyMedium.copyWith(
                          color: OneUITheme.of(ctx2).textPrimary)),
                  value: isPublic,
                  activeColor: OneUITheme.of(ctx2).primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setSheetState(() => isPublic = v),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

String _displayPlatformName(BuildContext context, String platform) {
  switch (platform.toLowerCase()) {
    case 'linkedin': return 'LinkedIn';
    case 'twitter': return 'Twitter / X';
    case 'facebook': return 'Facebook';
    case 'instagram': return 'Instagram';
    case 'researchgate': return 'ResearchGate';
    case 'orcid': return 'ORCID';
    case 'pubmed': return 'PubMed';
    case 'google_scholar': return 'Google Scholar';
    case 'website': return translation(context).lbl_platform_website;
    case 'other': return translation(context).lbl_platform_other;
    default: return platform;
  }
}

void _showAwardForm(BuildContext context, ProfileBloc bloc,
    {AwardModel? existing}) {
  final nameCtrl =
      TextEditingController(text: existing?.awardName ?? '');
  final bodyCtrl =
      TextEditingController(text: existing?.awardingBody ?? '');
  final dateCtrl =
      TextEditingController(text: existing?.dateReceived ?? '');
  final levelCtrl =
      TextEditingController(text: existing?.level ?? '');
  final descCtrl =
      TextEditingController(text: existing?.description ?? '');
  bool isEditing = existing != null;

  Future<void> _pickAwardDate() async {
    final initial = dateCtrl.text.isNotEmpty
        ? (DateTime.tryParse('${dateCtrl.text}-01') ?? DateTime.now())
        : DateTime.now();
    final picked = await _showOneUIDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      dateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _FormBottomSheet(
        title: isEditing ? translation(context).lbl_edit_award : translation(context).lbl_add_award,
        onSave: () {
          if (nameCtrl.text.isEmpty) return;
          final awardName = nameCtrl.text;
          final awardingBody = bodyCtrl.text;
          final dateReceived = dateCtrl.text;
          final desc = descCtrl.text;
          final level = levelCtrl.text;
          final editId = isEditing ? existing!.id! : null;
          Navigator.pop(ctx);
          if (editId != null) {
            _safeBlocAdd(bloc, UpdateAwardEvent(
              id: editId,
              awardName: awardName,
              awardingBody: awardingBody,
              dateReceived: dateReceived,
              description: desc,
              level: level,
            ));
          } else {
            _safeBlocAdd(bloc, StoreAwardEvent(
              awardName: awardName,
              awardingBody: awardingBody,
              dateReceived: dateReceived,
              description: desc,
              level: level,
            ));
          }
        },
        children: [
          _FormField(label: translation(context).lbl_award_name_required, controller: nameCtrl),
          _FormField(label: translation(context).lbl_awarding_body, controller: bodyCtrl),
          _DatePickerField(
              label: translation(context).lbl_date_received,
              controller: dateCtrl,
              onTap: _pickAwardDate),
          _FormField(label: translation(context).lbl_level_hint, controller: levelCtrl),
          _FormField(label: translation(context).lbl_description, controller: descCtrl, maxLines: 3),
        ],
      );
    },
  );
}

void _showLicenseForm(BuildContext context, ProfileBloc bloc,
    {MedicalLicenseModel? existing}) {
  final typeCtrl =
      TextEditingController(text: existing?.licenseType ?? '');
  final numberCtrl =
      TextEditingController(text: existing?.licenseNumber ?? '');
  final authorityCtrl =
      TextEditingController(text: existing?.issuingAuthority ?? '');
  final issueDateCtrl =
      TextEditingController(text: existing?.issueDate ?? '');
  final expiryDateCtrl =
      TextEditingController(text: existing?.expiryDate ?? '');
  bool isEditing = existing != null;

  Future<void> _pickDate(TextEditingController ctrl) async {
    final initial = ctrl.text.isNotEmpty
        ? (DateTime.tryParse(ctrl.text) ?? DateTime.now())
        : DateTime.now();
    final picked = await _showOneUIDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _FormBottomSheet(
        title: isEditing ? translation(context).lbl_edit_license : translation(context).lbl_add_license,
        onSave: () {
          if (typeCtrl.text.isEmpty || numberCtrl.text.isEmpty ||
              authorityCtrl.text.isEmpty) return;
          final licenseType = typeCtrl.text;
          final licenseNumber = numberCtrl.text;
          final authority = authorityCtrl.text;
          final issueDate = issueDateCtrl.text;
          final expiryDate = expiryDateCtrl.text.isEmpty ? null : expiryDateCtrl.text;
          final editId = isEditing ? existing!.id! : null;
          Navigator.pop(ctx);
          if (editId != null) {
            _safeBlocAdd(bloc, UpdateLicenseEvent(
              id: editId,
              licenseType: licenseType,
              licenseNumber: licenseNumber,
              issuingAuthority: authority,
              issueDate: issueDate,
              expiryDate: expiryDate,
            ));
          } else {
            _safeBlocAdd(bloc, StoreLicenseEvent(
              licenseType: licenseType,
              licenseNumber: licenseNumber,
              issuingAuthority: authority,
              issueDate: issueDate,
              expiryDate: expiryDate,
            ));
          }
        },
        children: [
          _FormField(label: translation(context).lbl_license_type_required, controller: typeCtrl),
          _FormField(label: translation(context).lbl_license_number_required, controller: numberCtrl),
          _FormField(
              label: translation(context).lbl_issuing_authority_required, controller: authorityCtrl),
          _DatePickerField(
              label: translation(context).lbl_issue_date,
              controller: issueDateCtrl,
              onTap: () => _pickDate(issueDateCtrl)),
          _DatePickerField(
              label: translation(context).lbl_expiry_date,
              controller: expiryDateCtrl,
              onTap: () => _pickDate(expiryDateCtrl)),
        ],
      );
    },
  );
}

// ── Business Hour Edit Form ──
void _showBusinessHourForm(BuildContext context, ProfileBloc bloc,
    {BusinessHourModel? existing}) {
  final locationCtrl =
      TextEditingController(text: existing?.locationName ?? '');
  final addressCtrl =
      TextEditingController(text: existing?.locationAddress ?? '');
  final startTimeCtrl =
      TextEditingController(text: existing?.startTime ?? '');
  final endTimeCtrl =
      TextEditingController(text: existing?.endTime ?? '');
  final notesCtrl =
      TextEditingController(text: existing?.notes ?? '');
  bool isEditing = existing != null;
  String selectedDay = existing?.dayOfWeek ?? BusinessHourModel.weekDays.first;
  bool isAvailable = existing?.isAvailable ?? true;

  Future<void> _pickTime(TextEditingController ctrl) async {
    TimeOfDay initial = TimeOfDay.now();
    if (ctrl.text.isNotEmpty) {
      final parts = ctrl.text.split(':');
      if (parts.length >= 2) {
        initial = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    final picked = await _showOneUITimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      ctrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx2, setSheetState) {
          return _FormBottomSheet(
            title: isEditing ? translation(context).lbl_edit_business_hour : translation(context).lbl_add_business_hour,
            onSave: () {
              if (locationCtrl.text.isEmpty || startTimeCtrl.text.isEmpty ||
                  endTimeCtrl.text.isEmpty) return;
              final locName = locationCtrl.text;
              final locAddr = addressCtrl.text.isNotEmpty ? addressCtrl.text : null;
              final day = selectedDay;
              final start = startTimeCtrl.text;
              final end = endTimeCtrl.text;
              final available = isAvailable;
              final notes = notesCtrl.text.isNotEmpty ? notesCtrl.text : null;
              final editId = isEditing ? existing!.id! : null;
              Navigator.pop(ctx);
              if (editId != null) {
                _safeBlocAdd(bloc, UpdateBusinessHourEvent(
                  id: editId,
                  locationName: locName,
                  locationAddress: locAddr,
                  dayOfWeek: day,
                  startTime: start,
                  endTime: end,
                  isAvailable: available,
                  notes: notes,
                ));
              } else {
                _safeBlocAdd(bloc, StoreBusinessHourEvent(
                  locationName: locName,
                  locationAddress: locAddr,
                  dayOfWeek: day,
                  startTime: start,
                  endTime: end,
                  isAvailable: available,
                  notes: notes,
                ));
              }
            },
            children: [
              _FormField(label: translation(context).lbl_location_name_required, controller: locationCtrl),
              _FormField(label: translation(context).lbl_location_address, controller: addressCtrl),
              // Day dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: selectedDay,
                  items: BusinessHourModel.weekDays.map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(day[0].toUpperCase() + day.substring(1),
                          style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setSheetState(() => selectedDay = val ?? BusinessHourModel.weekDays.first);
                  },
                  decoration: OneUITheme.of(ctx2).inputDecoration(label: translation(ctx2).lbl_day_of_week_required),
                ),
              ),
              _TimePickerField(
                  label: translation(context).lbl_start_time_required,
                  controller: startTimeCtrl,
                  onTap: () => _pickTime(startTimeCtrl)),
              _TimePickerField(
                  label: translation(context).lbl_end_time_required,
                  controller: endTimeCtrl,
                  onTap: () => _pickTime(endTimeCtrl)),
              // Available toggle
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SwitchListTile(
                  title: Text(translation(ctx2).lbl_available,
                      style: OneUITheme.of(ctx2).bodyMedium.copyWith(
                          color: OneUITheme.of(ctx2).textPrimary)),
                  value: isAvailable,
                  activeColor: OneUITheme.of(ctx2).primary,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setSheetState(() => isAvailable = v),
                ),
              ),
              _FormField(label: translation(context).lbl_notes, controller: notesCtrl, maxLines: 2),
            ],
          );
        },
      );
    },
  );
}

// ═══════════════════════════════════════════════
//  OneUI 8.5 THEMED PICKERS
// ═══════════════════════════════════════════════

/// Themed date picker with OneUI 8.5 styling for both dark and light mode
Future<DateTime?> _showOneUIDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
}) {
  final theme = OneUITheme.of(context);
  final isDark = theme.isDark;

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDatePickerMode: initialDatePickerMode,
    builder: (ctx, child) {
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: theme.primary,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1B2838),
                  onSurface: Colors.white,
                  onSurfaceVariant: Colors.white.withValues(alpha: 0.7),
                  outline: Colors.white.withValues(alpha: 0.15),
                  secondaryContainer: theme.primary.withValues(alpha: 0.2),
                  onSecondaryContainer: theme.primary,
                )
              : ColorScheme.light(
                  primary: theme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: const Color(0xFF1C1C1E),
                  onSurfaceVariant: const Color(0xFF636366),
                  outline: Colors.black.withValues(alpha: 0.1),
                  secondaryContainer: theme.primary.withValues(alpha: 0.1),
                  onSecondaryContainer: theme.primary,
                ),
          dialogTheme: DialogThemeData(
            backgroundColor: isDark ? const Color(0xFF1B2838) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
          ),
          textTheme: Theme.of(ctx).textTheme.apply(
            fontFamily: 'Poppins',
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: theme.primary,
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: isDark ? const Color(0xFF1B2838) : Colors.white,
            headerBackgroundColor: theme.primary,
            headerForegroundColor: Colors.white,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              if (states.contains(WidgetState.disabled)) {
                return isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3);
              }
              return isDark ? Colors.white : const Color(0xFF1C1C1E);
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return theme.primary;
              return Colors.transparent;
            }),
            todayForegroundColor: WidgetStateProperty.all(theme.primary),
            todayBorder: BorderSide(color: theme.primary, width: 1.5),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return isDark ? Colors.white : const Color(0xFF1C1C1E);
            }),
            yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return theme.primary;
              return Colors.transparent;
            }),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            dayOverlayColor: WidgetStateProperty.all(theme.primary.withValues(alpha: 0.1)),
            yearOverlayColor: WidgetStateProperty.all(theme.primary.withValues(alpha: 0.1)),
          ),
        ),
        child: child!,
      );
    },
  );
}

/// Themed time picker with OneUI 8.5 styling for both dark and light mode
Future<TimeOfDay?> _showOneUITimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  final theme = OneUITheme.of(context);
  final isDark = theme.isDark;

  return showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (ctx, child) {
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: theme.primary,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1B2838),
                  onSurface: Colors.white,
                  onSurfaceVariant: Colors.white.withValues(alpha: 0.7),
                  outline: Colors.white.withValues(alpha: 0.15),
                  secondaryContainer: theme.primary.withValues(alpha: 0.25),
                  onSecondaryContainer: Colors.white,
                  tertiary: theme.primary,
                  onTertiary: Colors.white,
                  tertiaryContainer: theme.primary.withValues(alpha: 0.25),
                  onTertiaryContainer: Colors.white,
                )
              : ColorScheme.light(
                  primary: theme.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: const Color(0xFF1C1C1E),
                  onSurfaceVariant: const Color(0xFF636366),
                  outline: Colors.black.withValues(alpha: 0.1),
                  secondaryContainer: theme.primary.withValues(alpha: 0.12),
                  onSecondaryContainer: theme.primary,
                  tertiary: theme.primary,
                  onTertiary: Colors.white,
                  tertiaryContainer: theme.primary.withValues(alpha: 0.12),
                  onTertiaryContainer: theme.primary,
                ),
          dialogTheme: DialogThemeData(
            backgroundColor: isDark ? const Color(0xFF1B2838) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
          ),
          textTheme: Theme.of(ctx).textTheme.apply(
            fontFamily: 'Poppins',
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: theme.primary,
              textStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: isDark ? const Color(0xFF1B2838) : Colors.white,
            hourMinuteColor: isDark
                ? const Color(0xFF2D3E50)
                : const Color(0xFFF0F0F0),
            hourMinuteTextColor: isDark ? Colors.white : const Color(0xFF1C1C1E),
            dayPeriodColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return theme.primary.withValues(alpha: 0.2);
              }
              return isDark ? const Color(0xFF2D3E50) : const Color(0xFFF0F0F0);
            }),
            dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return theme.primary;
              return isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF636366);
            }),
            dayPeriodBorderSide: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
            ),
            dialHandColor: theme.primary,
            dialBackgroundColor: isDark
                ? const Color(0xFF2D3E50)
                : const Color(0xFFF0F0F0),
            dialTextColor: WidgetStateColor.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return isDark ? Colors.white : const Color(0xFF1C1C1E);
            }),
            entryModeIconColor: theme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}

// ═══════════════════════════════════════════════
//  FORM BOTTOM SHEET TEMPLATE
// ═══════════════════════════════════════════════

class _FormBottomSheet extends StatelessWidget {
  final String title;
  final VoidCallback onSave;
  final List<Widget> children;

  const _FormBottomSheet({
    required this.title,
    required this.onSave,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(title,
                      style: theme.titleMedium.copyWith(
                          color: theme.textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(translation(context).lbl_cancel,
                        style: theme.bodyMedium.copyWith(
                            color: theme.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: theme.scaffoldBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(translation(context).lbl_save,
                        style: theme.buttonText),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const _FormField(
      {required this.label,
      required this.controller,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: theme.bodyMedium.copyWith(color: theme.textPrimary),
        decoration: theme.inputDecoration(label: label),
      ),
    );
  }
}

/// A date picker field that opens a date picker on tap
class _DatePickerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: theme.bodyMedium.copyWith(color: theme.textPrimary),
        decoration: theme.inputDecoration(
          label: label,
          suffixIcon: Icon(Icons.calendar_today, size: 20, color: theme.textSecondary),
        ),
      ),
    );
  }
}

/// A searchable dropdown field that opens a full-screen bottom sheet selector.
/// This avoids overlay clipping issues and works smoothly at any position.
class _SearchableDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final bool isLoading;
  final ValueChanged<String> onSelected;
  final bool allowManualInput;

  const _SearchableDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
    this.isLoading = false,
    this.allowManualInput = false,
  });

  void _openSelector(BuildContext context) {
    final theme = OneUITheme.of(context);
    final searchCtrl = TextEditingController();
    List<String> filtered = List.from(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSheetState) {
            void _filter(String query) {
              setSheetState(() {
                if (query.isEmpty) {
                  filtered = List.from(items);
                } else {
                  filtered = items
                      .where((item) =>
                          item.toLowerCase().contains(query.toLowerCase()))
                      .toList();
                }
              });
            }

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.65,
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Text(
                          translation(ctx).lbl_select_value(label),
                          style: theme.titleMedium.copyWith(
                            color: theme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: theme.textSecondary, size: 22),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      onChanged: _filter,
                      style: theme.bodyMedium.copyWith(
                        color: theme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: translation(ctx).lbl_search_hint,
                        hintStyle: theme.bodyMedium.copyWith(
                          color: theme.textTertiary,
                        ),
                        prefixIcon: Icon(Icons.search,
                            color: theme.textSecondary, size: 20),
                        filled: true,
                        fillColor: theme.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Results list
                  Expanded(
                    child: filtered.isEmpty
                        ? (allowManualInput && searchCtrl.text.trim().isNotEmpty
                            ? ListView(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                children: [
                                  ListTile(
                                    dense: true,
                                    visualDensity: const VisualDensity(vertical: -1),
                                    leading: Icon(Icons.add_circle_outline,
                                        color: theme.primary, size: 20),
                                    title: Text(
                                      translation(ctx).lbl_use_custom_value(searchCtrl.text.trim()),
                                      style: theme.bodyMedium.copyWith(
                                        color: theme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      translation(ctx).msg_type_own_value,
                                      style: theme.caption.copyWith(
                                        color: theme.textTertiary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    onTap: () {
                                      onSelected(searchCtrl.text.trim());
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                ],
                              )
                            : Center(
                                child: Text(
                                  allowManualInput ? translation(ctx).msg_type_custom_value : translation(ctx).msg_no_results_found,
                                  style: theme.bodyMedium.copyWith(
                                    color: theme.textTertiary,
                                  ),
                                ),
                              ))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: filtered.length,
                            itemBuilder: (_, index) {
                              final item = filtered[index];
                              final isSelected = item == value;
                              return ListTile(
                                dense: true,
                                visualDensity: const VisualDensity(vertical: -1),
                                leading: isSelected
                                    ? Icon(Icons.check_circle,
                                        color: theme.primary, size: 20)
                                    : Icon(Icons.circle_outlined,
                                        color: theme.border, size: 20),
                                title: Text(
                                  item,
                                  style: theme.bodyMedium.copyWith(
                                    color: isSelected
                                        ? theme.primary
                                        : theme.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                onTap: () {
                                  onSelected(item);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () {
          if (!isLoading && (items.isNotEmpty || allowManualInput)) {
            _openSelector(context);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: theme.bodySecondary,
            suffixIcon: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(Icons.arrow_drop_down, color: theme.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.border),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          child: Text(
            value.isNotEmpty ? value : '',
            style: theme.bodyMedium.copyWith(
              color: value.isNotEmpty ? theme.textPrimary : theme.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A time picker field that opens a time picker on tap
class _TimePickerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        style: theme.bodyMedium.copyWith(color: theme.textPrimary),
        decoration: theme.inputDecoration(
          label: label,
          suffixIcon: Icon(Icons.access_time, size: 20, color: theme.textSecondary),
        ),
      ),
    );
  }
}
