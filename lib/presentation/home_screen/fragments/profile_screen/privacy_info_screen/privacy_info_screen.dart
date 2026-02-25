import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';

class PrivacyInfoScreen extends StatefulWidget {
  final ProfileBloc profileBloc;

  const PrivacyInfoScreen({required this.profileBloc, super.key});

  @override
  State<PrivacyInfoScreen> createState() => _PrivacyInfoScreenState();
}

class _PrivacyInfoScreenState extends State<PrivacyInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isEditMode = false;

  @override
  void initState() {
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_privacy_settings,
        titleIcon: Icons.shield_rounded,
        actions: [
          if (widget.profileBloc.isMe) _buildEditToggle(theme),
          const SizedBox(width: 16),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy information header
                if (!_isEditMode) ...[
                  _buildInfoBanner(theme),
                  const SizedBox(height: 12),
                  // View as Public button — like LinkedIn
                  _buildViewAsPublicButton(theme),
                ],

                // Privacy settings
                _buildPrivacyInfoFields(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewAsPublicButton(OneUITheme theme) {
    return InkWell(
      onTap: () {
        // Navigate to own profile in "other user" mode to preview public view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SVProfileFragment(
              userId: AppData.logInUserId,
              viewAsPublic: true,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility_outlined, color: theme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Profile as Public',
                    style: theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'See how others view your profile',
                    style: theme.caption.copyWith(
                      color: theme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: theme.primary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyInfoFields() {
    final theme = OneUITheme.of(context);

    final privacySettings = widget.profileBloc.userProfile?.privacySetting;
    if (privacySettings == null || privacySettings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 48,
                color: theme.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'No privacy settings available',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group privacy settings by category
    final personalSettings = privacySettings
        .where(
          (item) => [
            'dob',
            'first_name',
            'last_name',
            'phone',
            'license_no',
            'email',
            'gender',
          ].contains(item.recordType),
        )
        .toList();

    final professionalSettings = privacySettings
        .where(
          (item) => [
            'specialty',
            'about_me',
            'current_workplace',
            'work',
          ].contains(item.recordType),
        )
        .toList();

    final locationSettings = privacySettings
        .where((item) => ['country', 'state'].contains(item.recordType))
        .toList();

    final otherSettings = privacySettings
        .where(
          (item) => ![
            'dob',
            'first_name',
            'last_name',
            'phone',
            'license_no',
            'email',
            'gender',
            'specialty',
            'about_me',
            'current_workplace',
            'work',
            'country',
            'state',
          ].contains(item.recordType),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal information privacy
        _buildPrivacyCategory(
          title: translation(context).lbl_personal_info_privacy,
          icon: Icons.person_outline,
          iconColor: theme.primary,
          settings: personalSettings,
          theme: theme,
        ),

        const SizedBox(height: 16),

        // Professional information privacy
        _buildPrivacyCategory(
          title: translation(context).lbl_professional_info_privacy,
          icon: Icons.work_outline,
          iconColor: theme.success,
          settings: professionalSettings,
          theme: theme,
        ),

        const SizedBox(height: 16),

        // Location information privacy
        _buildPrivacyCategory(
          title: translation(context).lbl_location_info_privacy,
          icon: Icons.location_on_outlined,
          iconColor: theme.warning,
          settings: locationSettings,
          theme: theme,
        ),

        // Other privacy settings
        if (otherSettings.isNotEmpty) const SizedBox(height: 16),

        if (otherSettings.isNotEmpty)
          _buildPrivacyCategory(
            title: translation(context).lbl_other_info_privacy,
            icon: Icons.more_horiz,
            iconColor: theme.secondary,
            settings: otherSettings,
            theme: theme,
          ),
      ],
    );
  }

  // Helper to build a category of privacy settings
  Widget _buildPrivacyCategory({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<PrivacySetting> settings,
    required OneUITheme theme,
  }) {
    if (settings.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: theme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: theme.radiusM,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Privacy settings
            ...settings.map((item) => _buildFieldRow(item, theme)),
          ],
        ),
      ),
    );
  }

  // Helper to get proper label for privacy items
  String _getPrivacyItemLabel(String? recordType) {
    if (recordType == null || recordType.isEmpty) {
      return translation(context).lbl_unknown_state;
    }

    switch (recordType.toLowerCase()) {
      case 'dob':
        return translation(context).lbl_date_of_birth;
      case 'first_name':
        return translation(context).lbl_first_name;
      case 'last_name':
        return translation(context).lbl_last_name;
      case 'phone':
        return translation(context).lbl_phone_number;
      case 'license_no':
        return translation(context).lbl_license_no;
      case 'specialty':
        return translation(context).lbl_specialty;
      case 'about_me':
        return translation(context).lbl_years_experience;
      case 'current_workplace':
        return translation(context).lbl_current_workplace;
      case 'work':
        return translation(context).lbl_professional_experience;
      case 'country':
        return translation(context).lbl_country;
      case 'state':
        return translation(context).lbl_state;
      case 'email':
        return 'Email';
      case 'gender':
        return translation(context).lbl_gender;
      default:
        return capitalizeWords(recordType.replaceAll('_', ' '));
    }
  }

  // --- Privacy helpers ---
  String _normalize(String? raw) {
    if (raw == null || raw.isEmpty) return 'only_me';
    if (raw == 'lock') return 'only_me';
    if (raw == 'group') return 'friends';
    if (['only_me', 'friends', 'public'].contains(raw)) return raw;
    return 'only_me';
  }

  String _displayLabel(String value) {
    switch (value) {
      case 'only_me':
        return translation(context).lbl_only_me;
      case 'friends':
        return translation(context).lbl_friends;
      default:
        return translation(context).lbl_public;
    }
  }

  String _toApiValue(String displayLabel) {
    if (displayLabel == translation(context).lbl_only_me) return 'only_me';
    if (displayLabel == translation(context).lbl_friends) return 'friends';
    return 'public';
  }

  IconData _privacyIcon(String value) {
    switch (value) {
      case 'only_me':
        return Icons.lock_outline;
      case 'friends':
        return Icons.people_outline;
      default:
        return Icons.public;
    }
  }

  Color _privacyColor(OneUITheme theme, String value) {
    switch (value) {
      case 'only_me':
        return theme.error;
      case 'friends':
        return theme.warning;
      default:
        return theme.success;
    }
  }

  // --- New helper widgets ---
  Widget _buildEditToggle(OneUITheme theme) {
    final color = _isEditMode ? theme.success : theme.primary;
    final bg = _isEditMode
        ? theme.success.withValues(alpha: 0.1)
        : theme.iconButtonBg;
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(
          _isEditMode ? Icons.check : Icons.edit,
          color: color,
          size: 16,
        ),
      ),
      onPressed: () {
        setState(() {
          if (_isEditMode) _saveChanges();
          _isEditMode = !_isEditMode;
        });
      },
    );
  }

  Widget _buildInfoBanner(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: theme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              translation(context).msg_privacy_info_desc,
              style: theme.caption.copyWith(
                color: theme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Combined field renderer (replaces _buildDropdownField) ---
  Widget _buildFieldRow(PrivacySetting item, OneUITheme theme) {
    final normalized = _normalize(item.visibility);
    final display = _displayLabel(normalized);
    final color = _privacyColor(theme, normalized);
    final icon = _privacyIcon(normalized);
    final label = _getPrivacyItemLabel(item.recordType);
    final options = [
      'only_me',
      'friends',
      'public',
    ].map((v) => _displayLabel(v)).toList();

    if (_isEditMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border),
                  color: color.withValues(alpha: 0.06),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: display,
                    isExpanded: true,
                    isDense: true,
                    icon: Icon(Icons.expand_more, size: 18, color: color),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                    items: options.map((opt) {
                      final optApi = _toApiValue(opt);
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Row(
                          children: [
                            Icon(
                              _privacyIcon(optApi),
                              size: 14,
                              color: _privacyColor(theme, optApi),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                opt,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _privacyColor(theme, optApi),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        item.visibility = _toApiValue(val);
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // View mode
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Text(
                  display,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    widget.profileBloc.add(
      UpdateProfileEvent(
        updateProfileSection: 3,
        userProfile: widget.profileBloc.userProfile,
        interestModel: widget.profileBloc.interestList,
        workEducationModel: widget.profileBloc.workEducationList,
        userProfilePrivacyModel: UserProfilePrivacyModel(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translation(context).msg_privacy_settings_updated),
        backgroundColor: OneUITheme.of(context).success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
