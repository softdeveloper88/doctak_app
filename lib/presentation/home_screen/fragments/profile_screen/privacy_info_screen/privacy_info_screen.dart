import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../core/app_export.dart';
import '../../../utils/SVColors.dart';
import '../../../utils/SVCommon.dart';
import '../bloc/profile_state.dart';

class PrivacyInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  PrivacyInfoScreen({required this.profileBloc, super.key});

  @override
  State<PrivacyInfoScreen> createState() => _PrivacyInfoScreenState();
}

bool isEditModeMap = false;

class _PrivacyInfoScreenState extends State<PrivacyInfoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    isEditModeMap = false;

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
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
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        elevation: 0,
        toolbarHeight: 70,
        surfaceTintColor: svGetScaffoldColor(),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.blue[600],
              size: 16,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          }
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              color: Colors.blue[600],
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              translation(context).lbl_privacy_information,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.profileBloc.isMe)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEditModeMap ? Icons.check : Icons.edit,
                  color: isEditModeMap ? Colors.green[600] : Colors.blue[600],
                  size: 14,
                ),
              ),
              onPressed: () {
                setState(() {
                  isEditModeMap = !isEditModeMap;
                  if (!isEditModeMap) {
                    _saveChanges();
                  }
                });
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy information header
                if (!isEditModeMap)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.purple[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            translation(context).msg_privacy_info_desc,
                            style: TextStyle(
                              color: Colors.purple[700],
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Privacy settings
                _buildPrivacyInfoFields(),

                const SizedBox(height: 24),

                // Update button
                if (isEditModeMap)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            translation(context).lbl_update,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyInfoFields() {
    // Group privacy settings by category
    final personalSettings = widget.profileBloc.userProfile!.privacySetting!
        .where((item) => ['dob', 'first_name', 'last_name', 'phone', 'license_no'].contains(item.recordType))
        .toList();

    final professionalSettings = widget.profileBloc.userProfile!.privacySetting!
        .where((item) => ['specialty', 'about_me', 'current_workplace', 'work'].contains(item.recordType))
        .toList();

    final locationSettings = widget.profileBloc.userProfile!.privacySetting!
        .where((item) => ['country', 'state'].contains(item.recordType))
        .toList();

    final otherSettings = widget.profileBloc.userProfile!.privacySetting!
        .where((item) => !['dob', 'first_name', 'last_name', 'phone', 'license_no',
      'specialty', 'about_me', 'current_workplace', 'work',
      'country', 'state'].contains(item.recordType))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal information privacy
        _buildPrivacyCategory(
          title: translation(context).lbl_personal_info_privacy,
          icon: Icons.person_outline,
          iconColor: Colors.blue,
          settings: personalSettings,
        ),

        const SizedBox(height: 16),

        // Professional information privacy
        _buildPrivacyCategory(
          title: translation(context).lbl_professional_info_privacy,
          icon: Icons.work_outline,
          iconColor: Colors.green,
          settings: professionalSettings,
        ),

        const SizedBox(height: 16),

        // Location information privacy
        _buildPrivacyCategory(
          title: translation(context).lbl_location_info_privacy,
          icon: Icons.location_on_outlined,
          iconColor: Colors.orange,
          settings: locationSettings,
        ),

        // Other privacy settings
        if (otherSettings.isNotEmpty)
          const SizedBox(height: 16),

        if (otherSettings.isNotEmpty)
          _buildPrivacyCategory(
            title: translation(context).lbl_other_info_privacy,
            icon: Icons.more_horiz,
            iconColor: Colors.purple,
            settings: otherSettings,
          ),
      ],
    );
  }

  // Helper to build a category of privacy settings
  Widget _buildPrivacyCategory({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<PrivacySetting> settings
  }) {
    if (settings.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 18,
                  ),
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
            ...settings.map((item) {
              // Handle null/empty visibility by defaulting to 'lock'
              String effectiveVisibility = item.visibility ?? 'lock';
              if (effectiveVisibility.isEmpty || effectiveVisibility.trim().isEmpty) {
                effectiveVisibility = 'lock';
              }
              
              var selectValue = effectiveVisibility == 'lock'
                  ? translation(context).lbl_only_me
                  : effectiveVisibility == 'group'
                  ? translation(context).lbl_friends
                  : translation(context).lbl_public;

              return _buildDropdownField(
                index: 4,
                label: _getPrivacyItemLabel(item.recordType),
                value: selectValue,
                onSave: (value) {
                  var updateValue = value == translation(context).lbl_only_me
                      ? 'lock'
                      : value == translation(context).lbl_friends
                      ? 'group'
                      : 'public';
                  item.visibility = updateValue;
                },
                options: [
                  translation(context).lbl_only_me,
                  translation(context).lbl_friends,
                  translation(context).lbl_public
                ],
                colorScheme: _getColorForPrivacyLevel(selectValue),
              );
            }).toList(),
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
      default:
        return capitalizeWords(recordType.replaceAll('_', ' '));
    }
  }

  // Helper to get appropriate colors for different privacy levels
  ColorScheme _getColorForPrivacyLevel(String level) {
    if (level == translation(context).lbl_only_me) {
      return ColorScheme.fromSeed(
        seedColor: Colors.red,
        primary: Colors.red,
        surface: Colors.red.shade50,
      );
    } else if (level == translation(context).lbl_friends) {
      return ColorScheme.fromSeed(
        seedColor: Colors.orange,
        primary: Colors.orange,
        surface: Colors.orange.shade50,
      );
    } else {
      return ColorScheme.fromSeed(
        seedColor: Colors.green,
        primary: Colors.green,
        surface: Colors.green.shade50,
      );
    }
  }

  Widget _buildDropdownField({
    required int index,
    required String label,
    required String value,
    void Function(String)? onSave,
    required List<String> options,
    required ColorScheme colorScheme,
  }) {
    options = options.where((opt) => opt.isNotEmpty && opt.trim().isNotEmpty).toList();

    return isEditModeMap
        ? Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              capitalizeWords(label.replaceAll('_', ' ')),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: CustomDropdownButtonFormField(
              items: options,
              value: value,
              width: double.infinity,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              itemBuilder: (item) => Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getColorForPrivacyLevel(item).surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        item == translation(context).lbl_only_me
                            ? Icons.lock_outline
                            : item == translation(context).lbl_friends
                            ? Icons.people_outline
                            : Icons.public,
                        color: _getColorForPrivacyLevel(item).primary,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item,
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
              onChanged: (String? selectedValue) {
                if (selectedValue != value) {
                  onSave?.call(selectedValue!);
                }
              },
            ),
          ),
        ],
      ),
    )
        : Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              capitalizeWords(label),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  value == translation(context).lbl_only_me
                      ? Icons.lock_outline
                      : value == translation(context).lbl_friends
                      ? Icons.people_outline
                      : Icons.public,
                  color: colorScheme.primary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  capitalizeWords(value),
                  style: TextStyle(
                    color: colorScheme.primary,
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
    widget.profileBloc.add(UpdateProfileEvent(
      updateProfileSection: 3,
      userProfile: widget.profileBloc.userProfile,
      interestModel: widget.profileBloc.interestList,
      workEducationModel: widget.profileBloc.workEducationList,
      userProfilePrivacyModel: UserProfilePrivacyModel(),
    ));

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translation(context).msg_privacy_settings_updated),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}