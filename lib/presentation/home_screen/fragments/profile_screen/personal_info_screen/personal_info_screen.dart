import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../../../../core/app_export.dart';
import '../../../utils/SVCommon.dart';
import '../bloc/profile_state.dart';

class PersonalInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  PersonalInfoScreen({required this.profileBloc, super.key});

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

  Countries findModelByNameOrDefault(
    List<Countries> countries,
    String name,
    Countries defaultCountry,
  ) {
    return countries.firstWhere(
      (country) => country.countryName?.toLowerCase() == name.toLowerCase(),
      orElse: () => defaultCountry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: DoctakAppBar(
        title: translation(context).lbl_personal_information,
        titleIcon: Icons.person_rounded,
        actions: [
          if (widget.profileBloc.isMe)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEditModeMap ? Icons.check : Icons.edit,
                  color: isEditModeMap ? Colors.green[600] : Colors.blue[600],
                  size: 16,
                ),
              ),
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
                if (!isEditModeMap)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            translation(context).msg_personal_info_desc,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main info card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isEditModeMap)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                translation(context).lbl_basic_info,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // First name field
                      TextFieldEditWidget(
                        isEditModeMap: isEditModeMap,
                        index: 0,
                        icon: Icons.person,
                        label: translation(context).lbl_first_name,
                        value:
                            widget.profileBloc.userProfile?.user?.firstName ??
                            '',
                        onSave: (value) =>
                            widget.profileBloc.userProfile?.user?.firstName =
                                value,
                      ),
                      if (!isEditModeMap)
                        Divider(
                          color: Colors.grey[200],
                          thickness: 1.5,
                          indent: 10,
                          endIndent: 10,
                        ),

                      // Last name field
                      TextFieldEditWidget(
                        isEditModeMap: isEditModeMap,
                        index: 0,
                        icon: Icons.person,
                        label: translation(context).lbl_last_name,
                        value:
                            widget.profileBloc.userProfile?.user?.lastName ??
                            '',
                        onSave: (value) =>
                            widget.profileBloc.userProfile?.user?.lastName =
                                value,
                      ),
                      if (!isEditModeMap)
                        Divider(
                          color: Colors.grey[200],
                          thickness: 1.5,
                          indent: 10,
                          endIndent: 10,
                        ),

                      // Phone number field - Only visible to profile owner
                      if (widget.profileBloc.isMe)
                        TextFieldEditWidget(
                          isEditModeMap: isEditModeMap,
                          index: 0,
                          icon: Icons.phone,
                          label: translation(context).lbl_phone_number,
                          value:
                              widget.profileBloc.userProfile?.user?.phone ?? '',
                          onSave: (value) =>
                              widget.profileBloc.userProfile?.user?.phone = value,
                        ),
                      if (!isEditModeMap && widget.profileBloc.isMe)
                        Divider(
                          color: Colors.grey[200],
                          thickness: 1.5,
                          indent: 10,
                          endIndent: 10,
                        ),

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

                const SizedBox(height: 20),

                // License info card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isEditModeMap)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.badge_rounded,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                translation(context).lbl_license_info,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // License number field
                      TextFieldEditWidget(
                        isEditModeMap: isEditModeMap,
                        icon: Icons.numbers_rounded,
                        index: 0,
                        label: translation(context).lbl_license_no,
                        value:
                            widget.profileBloc.userProfile?.user?.licenseNo ??
                            '',
                        onSave: (value) =>
                            widget.profileBloc.userProfile?.user?.licenseNo =
                                value,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Location info card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isEditModeMap)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                translation(context).lbl_location_info,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Country field
                      if (!isEditModeMap)
                        TextFieldEditWidget(
                          index: 0,
                          label: translation(context).lbl_country,
                          value:
                              widget.profileBloc.userProfile?.user?.country ??
                              '',
                          onSave: (value) =>
                              widget.profileBloc.userProfile?.user?.country =
                                  value,
                        ),
                      if (!isEditModeMap)
                        Divider(
                          color: Colors.grey[200],
                          thickness: 1.5,
                          indent: 10,
                          endIndent: 10,
                        ),

                      // State field
                      if (!isEditModeMap)
                        TextFieldEditWidget(
                          index: 0,
                          label: translation(context).lbl_state,
                          value:
                              widget.profileBloc.userProfile?.user?.state ?? '',
                          onSave: (value) =>
                              widget.profileBloc.userProfile?.user?.state =
                                  value,
                        ),

                      // Country and State dropdown fields in edit mode
                      if (isEditModeMap)
                        BlocBuilder<ProfileBloc, ProfileState>(
                          bloc: widget.profileBloc,
                          builder: (context, state) {
                            if (state is PaginationLoadedState) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Text(
                                    translation(context).lbl_country,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Country dropdown
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: CustomDropdownButtonFormField(
                                      itemBuilder: (item) => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.countryName ?? '',
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(item.flag ?? ''),
                                        ],
                                      ),
                                      selectedItemBuilder: (context) =>
                                          state.firstDropdownValues.map((item) {
                                            return Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                item.countryName ?? '',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      items: state.firstDropdownValues,
                                      value: findModelByNameOrDefault(
                                        state.firstDropdownValues,
                                        state.selectedFirstDropdownValue ?? '',
                                        state.firstDropdownValues.first,
                                      ),
                                      width: double.infinity,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                      onChanged: (newValue) {
                                        widget.profileBloc.country =
                                            newValue?.countryName ?? '';
                                        widget
                                                .profileBloc
                                                .userProfile
                                                ?.user
                                                ?.country =
                                            newValue?.countryName ?? '';
                                        widget.profileBloc.add(
                                          UpdateSecondDropdownValues(
                                            newValue?.countryName ?? "",
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // State dropdown
                                  Text(
                                    translation(context).lbl_state,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: CustomDropdownButtonFormField(
                                      itemBuilder: (item) => Text(
                                        item ?? '',
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      selectedItemBuilder: (context) => state
                                          .secondDropdownValues
                                          .map((item) {
                                            return Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                item ?? '',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                      items: state.secondDropdownValues,
                                      value: state.selectedSecondDropdownValue,
                                      width: double.infinity,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                      onChanged: (String? newValue) {
                                        widget.profileBloc.stateName =
                                            newValue!;
                                        widget
                                                .profileBloc
                                                .userProfile
                                                ?.user
                                                ?.state =
                                            newValue;
                                        widget.profileBloc.add(
                                          UpdateSpecialtyDropdownValue(
                                            state.selectedSecondDropdownValue,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Specialty dropdown for doctors
                                  if (AppData.userType == "doctor")
                                    const SizedBox(height: 16),
                                  if (AppData.userType == "doctor")
                                    Text(
                                      translation(context).lbl_specialty,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  if (AppData.userType == "doctor")
                                    const SizedBox(height: 8),
                                  if (AppData.userType == "doctor")
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: CustomDropdownButtonFormField(
                                        itemBuilder: (item) => Text(
                                          item ?? '',
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        selectedItemBuilder: (context) => state
                                            .specialtyDropdownValue
                                            .map((item) {
                                              return Container(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  item ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList(),
                                        items: state.specialtyDropdownValue,
                                        value: state
                                            .selectedSpecialtyDropdownValue,
                                        width: double.infinity,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                        onChanged: (String? newValue) {
                                          widget.profileBloc.specialtyName =
                                              newValue!;
                                          widget.profileBloc.add(
                                            UpdateSpecialtyDropdownValue(
                                              newValue,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              );
                            } else {
                              return Text(
                                translation(context).msg_something_wrong,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Update button
                if (isEditModeMap)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditModeMap = false;
                        });
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                        }

                        widget.profileBloc.add(
                          UpdateProfileEvent(
                            updateProfileSection: 1,
                            userProfile: widget.profileBloc.userProfile,
                            userProfilePrivacyModel: UserProfilePrivacyModel(),
                          ),
                        );

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              translation(context).msg_profile_updated,
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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
}
