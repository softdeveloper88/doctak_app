import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_state.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/one_ui_profile_components.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalInfoScreen extends StatefulWidget {
  final ProfileBloc profileBloc;

  const PersonalInfoScreen({required this.profileBloc, super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

bool isEditModeMap = false;
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  @override
  void initState() {
    isEditModeMap = false;
    super.initState();
  }

  Countries findModelByNameOrDefault(List<Countries> countries, String name, Countries defaultCountry) {
    return countries.firstWhere((country) => country.countryName?.toLowerCase() == name.toLowerCase(), orElse: () => defaultCountry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_personal_information,
        titleIcon: Icons.person_rounded,
        actions: [
          if (widget.profileBloc.isMe)
            OneUIEditActionButton(
              isEditMode: isEditModeMap,
              onPressed: () {
                setState(() {
                  isEditModeMap = !isEditModeMap;
                });
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header card
                if (!isEditModeMap) OneUIInfoBanner(message: translation(context).msg_personal_info_desc, icon: Icons.info_outline, accentColor: theme.primary),

                // Main info card
                OneUIProfileSection(
                  title: translation(context).lbl_basic_info,
                  icon: Icons.person_rounded,
                  iconColor: theme.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First name field
                      TextFieldEditWidget(
                        isEditModeMap: isEditModeMap,
                        index: 0,
                        icon: Icons.person,
                        label: translation(context).lbl_first_name,
                        value: widget.profileBloc.userProfile?.user?.firstName ?? '',
                        onSave: (value) => widget.profileBloc.userProfile?.user?.firstName = value,
                      ),
                      if (!isEditModeMap) Divider(color: theme.divider, thickness: 1, indent: 10, endIndent: 10),

                      // Last name field
                      TextFieldEditWidget(
                        isEditModeMap: isEditModeMap,
                        index: 0,
                        icon: Icons.person,
                        label: translation(context).lbl_last_name,
                        value: widget.profileBloc.userProfile?.user?.lastName ?? '',
                        onSave: (value) => widget.profileBloc.userProfile?.user?.lastName = value,
                      ),
                      if (!isEditModeMap) Divider(color: theme.divider, thickness: 1, indent: 10, endIndent: 10),

                      // Phone number field - Only visible to profile owner
                      if (widget.profileBloc.isMe)
                        TextFieldEditWidget(
                          isEditModeMap: isEditModeMap,
                          index: 0,
                          icon: Icons.phone,
                          label: translation(context).lbl_phone_number,
                          value: widget.profileBloc.userProfile?.user?.phone ?? '',
                          onSave: (value) => widget.profileBloc.userProfile?.user?.phone = value,
                        ),
                      if (!isEditModeMap && widget.profileBloc.isMe) Divider(color: theme.divider, thickness: 1, indent: 10, endIndent: 10),

                      // Date of birth field - Only visible to profile owner
                      if (widget.profileBloc.isMe)
                        ProfileDateWidget(
                          isEditModeMap: isEditModeMap,
                          index: 0,
                          label: translation(context).lbl_date_of_birth,
                          value: widget.profileBloc.userProfile?.user?.dob ?? '',
                          onSave: (value) {
                            setState(() {
                              widget.profileBloc.userProfile?.user?.dob = value;
                            });
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // License info card
                OneUIProfileSection(
                  title: translation(context).lbl_license_info,
                  icon: Icons.badge_rounded,
                  iconColor: theme.success,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // License number field
                      TextFieldEditWidget(
                        isEditModeMap: isEditModeMap,
                        icon: Icons.numbers_rounded,
                        iconColor: theme.success,
                        index: 0,
                        label: translation(context).lbl_license_no,
                        value: widget.profileBloc.userProfile?.user?.licenseNo ?? '',
                        onSave: (value) => widget.profileBloc.userProfile?.user?.licenseNo = value,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Location info card
                OneUIProfileSection(title: translation(context).lbl_location_info, icon: Icons.location_on_rounded, iconColor: theme.warning, child: _buildLocationFields(theme)),

                const SizedBox(height: 24),

                // Update button
                if (isEditModeMap)
                  OneUIProfilePrimaryButton(
                    label: translation(context).lbl_update,
                    icon: Icons.check_circle,
                    color: theme.primary,
                    onPressed: () {
                      setState(() {
                        isEditModeMap = false;
                      });
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                      }

                      widget.profileBloc.add(UpdateProfileEvent(updateProfileSection: 1, userProfile: widget.profileBloc.userProfile, userProfilePrivacyModel: UserProfilePrivacyModel()));

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(translation(context).msg_profile_updated),
                          backgroundColor: theme.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFields(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country and State in view mode
        if (!isEditModeMap) ...[
          OneUIProfileInfoRow(icon: Icons.public, label: translation(context).lbl_country, value: widget.profileBloc.userProfile?.user?.country ?? ''),
          Divider(color: theme.divider, thickness: 1, indent: 10, endIndent: 10),
          OneUIProfileInfoRow(icon: Icons.location_city, label: translation(context).lbl_state, value: widget.profileBloc.userProfile?.user?.state ?? ''),
        ],

        // Country and State dropdown fields in edit mode
        if (isEditModeMap)
          BlocBuilder<ProfileBloc, ProfileState>(
            bloc: widget.profileBloc,
            builder: (context, state) {
              if (state is PaginationLoadedState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country dropdown
                    Text(translation(context).lbl_country, style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: theme.radiusM,
                        border: Border.all(color: theme.border),
                      ),
                      child: CustomDropdownButtonFormField(
                        itemBuilder: (item) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.countryName ?? '',
                                style: TextStyle(color: theme.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(item.flag ?? ''),
                          ],
                        ),
                        selectedItemBuilder: (context) => state.firstDropdownValues.map((item) {
                          return Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.countryName ?? '',
                              style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                            ),
                          );
                        }).toList(),
                        items: state.firstDropdownValues,
                        value: findModelByNameOrDefault(state.firstDropdownValues, state.selectedFirstDropdownValue ?? '', state.firstDropdownValues.first),
                        width: double.infinity,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        onChanged: (newValue) {
                          widget.profileBloc.country = newValue?.countryName ?? '';
                          widget.profileBloc.userProfile?.user?.country = newValue?.countryName ?? '';
                          widget.profileBloc.add(UpdateSecondDropdownValues(newValue?.countryName ?? ""));
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // State dropdown
                    Text(translation(context).lbl_state, style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: theme.radiusM,
                        border: Border.all(color: theme.border),
                      ),
                      child: CustomDropdownButtonFormField(
                        itemBuilder: (item) => Text(
                          item ?? '',
                          style: TextStyle(color: theme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        selectedItemBuilder: (context) => state.secondDropdownValues.map((item) {
                          return Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item ?? '',
                              style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                            ),
                          );
                        }).toList(),
                        items: state.secondDropdownValues,
                        value: state.selectedSecondDropdownValue,
                        width: double.infinity,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        onChanged: (String? newValue) {
                          widget.profileBloc.stateName = newValue!;
                          widget.profileBloc.userProfile?.user?.state = newValue;
                          widget.profileBloc.add(UpdateSpecialtyDropdownValue(state.selectedSecondDropdownValue));
                        },
                      ),
                    ),

                    // Specialty dropdown for doctors
                    if (AppData.userType == "doctor") ...[
                      const SizedBox(height: 16),
                      Text(translation(context).lbl_specialty, style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: theme.radiusM,
                          border: Border.all(color: theme.border),
                        ),
                        child: CustomDropdownButtonFormField(
                          itemBuilder: (item) => Text(
                            item ?? '',
                            style: TextStyle(color: theme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          selectedItemBuilder: (context) => state.specialtyDropdownValue.map((item) {
                            return Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item ?? '',
                                style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                              ),
                            );
                          }).toList(),
                          items: state.specialtyDropdownValue,
                          value: state.selectedSpecialtyDropdownValue,
                          width: double.infinity,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          onChanged: (String? newValue) {
                            widget.profileBloc.specialtyName = newValue!;
                            widget.profileBloc.add(UpdateSpecialtyDropdownValue(newValue));
                          },
                        ),
                      ),
                    ],
                  ],
                );
              } else {
                return Text(translation(context).msg_something_wrong);
              }
            },
          ),
      ],
    );
  }
}
