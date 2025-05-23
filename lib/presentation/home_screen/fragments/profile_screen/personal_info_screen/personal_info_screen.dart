import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
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
    // TODO: implement initState
    super.initState();
  }
  Countries findModelByNameOrDefault(
      List<Countries> countries,
      String name,
      Countries defaultCountry,
      ) {
    return countries.firstWhere(
          (country) => country.countryName?.toLowerCase() == name.toLowerCase(), // Case-insensitive match
      orElse: () => defaultCountry, // Return defaultCountry if not found
    );
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        surfaceTintColor: svGetScaffoldColor(),
        title: Text(translation(context).lbl_personal_information, style: boldTextStyle(size: 20,fontFamily: 'Poppins',)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Icon(
              Icons.arrow_back_ios,
              color: svGetBodyColor(),
              size: 17,
            )),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          if (widget.profileBloc.isMe)
            MaterialButton(
              textColor: Colors.black,
              onPressed: () {
                setState(() {
                  isEditModeMap = !isEditModeMap;
                });
              },
              elevation: 1,
              // color: Colors.white,
              minWidth: 50,
              // shape: RoundedRectangleBorder(
              //   borderRadius: radius(100),
              //   side: const BorderSide(color: Colors.blue),
              // ),
              animationDuration: const Duration(milliseconds: 300),
              focusColor: SVAppColorPrimary,
              hoverColor: SVAppColorPrimary,
              splashColor: SVAppColorPrimary,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomImageView(
                    onTap: () {
                      setState(() {
                        isEditModeMap = !isEditModeMap;
                      });
                    },
                    color: Colors.black,
                    imagePath: 'assets/icon/ic_vector.svg',
                    height: 15,
                    width: 15,
                    // margin: const EdgeInsets.only(bottom: 4),
                  ),
                  // const Text(
                  //   "Edit",
                  //   style: TextStyle(
                  //     fontSize: 10,
                  //     fontWeight: FontWeight.w400,
                  //     color: Colors.blue,
                  //   ),
                  // ),
                ],
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  index: 0,
                  icon: Icons.person,
                  label: translation(context).lbl_first_name,
                  value: widget.profileBloc.userProfile?.user?.firstName ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.firstName = value,
                ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  index: 0,
                  icon: Icons.person,
                  label: translation(context).lbl_last_name,
                  value: widget.profileBloc.userProfile?.user?.lastName ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.lastName = value,
                ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  index: 0,
                  icon: Icons.person,
                  label: translation(context).lbl_phone_number,
                  value: widget.profileBloc.userProfile?.user?.phone ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.phone = value,
                ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                ProfileDateWidget(
                  isEditModeMap: isEditModeMap,
                  index: 0,
                  label: translation(context).lbl_date_of_birth,
                  value: widget.profileBloc.userProfile?.user?.dob ?? '',
                  onSave: (value) {
                    setState(() {
                      // Value received from date picker
                      widget.profileBloc.userProfile?.user?.dob = value;
                    });
                  },
                ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.numbers_rounded,
                  index: 0,
                  label: translation(context).lbl_license_no,
                  value: widget.profileBloc.userProfile?.user?.licenseNo ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.licenseNo = value,
                ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                if (!isEditModeMap)
                  TextFieldEditWidget(
                    index: 0,
                    label: translation(context).lbl_country,
                    value: widget.profileBloc.userProfile?.user?.country ?? '',
                    onSave: (value) =>
                        widget.profileBloc.userProfile?.user?.country = value,
                  ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                if (!isEditModeMap)
                  TextFieldEditWidget(
                    index: 0,
                    label: translation(context).lbl_state,
                    value: widget.profileBloc.userProfile?.user?.state ?? '',
                    onSave: (value) => widget.profileBloc.userProfile?.user?.state = value,
                  ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
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
                              CustomDropdownButtonFormField(
                                itemBuilder: (item) => Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.countryName??'',
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                    Text(item.flag??'')
                                  ],
                                ),
                                items: state.firstDropdownValues,
                                value: findModelByNameOrDefault(state.firstDropdownValues,state.selectedFirstDropdownValue??'',state.firstDropdownValues.first),
                                width: double.infinity,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                onChanged: (newValue) {
                                  widget.profileBloc.country = newValue?.countryName??'';
                                  widget.profileBloc.userProfile?.user
                                      ?.country = newValue?.countryName??'';
                                  // widget.profileBloc
                                  //     .add(UpdateFirstDropdownValue(newValue));
                                  widget.profileBloc.add(
                                      UpdateSecondDropdownValues(newValue?.countryName??""));
                                },
                              ),
                              const SizedBox(height: 10),
                              Text(
                                translation(context).lbl_state,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              CustomDropdownButtonFormField(
                                itemBuilder: (item) => Text(
                                  item??'',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                items: state.secondDropdownValues,
                                value: state.selectedSecondDropdownValue,
                                width: double.infinity,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                onChanged: (String? newValue) {
                                  widget.profileBloc.stateName = newValue!;
                                  widget.profileBloc.userProfile?.user?.state =
                                      newValue;
                                  widget.profileBloc.add(
                                      UpdateSpecialtyDropdownValue(
                                          state.selectedSecondDropdownValue));
                                  // widget.profileBloc.add(
                                  //     UpdateUniversityDropdownValues(newValue));
                                },
                              ),
                              if (AppData.userType == "doctor")
                                const SizedBox(height: 10),
                              if (AppData.userType == "doctor")
                                Text(
                                  translation(context).lbl_specialty,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (AppData.userType == "doctor")
                                CustomDropdownButtonFormField(
                                  itemBuilder: (item) => Text(
                                    item??'',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  items: state.specialtyDropdownValue,
                                  value: state.selectedSpecialtyDropdownValue,
                                  width: double.infinity,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 0,
                                  ),
                                  onChanged: (String? newValue) {
                                    // Selected specialty value
                                    // Update specialty in profile bloc
                                    widget.profileBloc.specialtyName = newValue!;
                                    widget.profileBloc.add(UpdateSpecialtyDropdownValue(newValue));
                                  },
                                ),
                              if (AppData.userType != "doctor")
                                const SizedBox(height: 10),
                              // if (AppData.userType != "doctor")
                              //   Padding(
                              //     padding: EdgeInsets.only(top: 8.0),
                              //     child: Text(
                              //       translation(context).lbl_university,
                              //       style: TextStyle(
                              //         fontSize: 16,
                              //         fontWeight: FontWeight.w500,
                              //       ),
                              //     ),
                              //   ),
                              // if (AppData.userType != "doctor")
                                // CustomDropdownButtonFormField(
                                //   itemBuilder: (item) => Text(
                                //     item??'',
                                //     style: const TextStyle(color: Colors.black),
                                //   ),
                                //   items: state.universityDropdownValue,
                                //   value: state.selectedUniversityDropdownValue ==
                                //               ''
                                //           ? null
                                //           : state
                                //               .selectedUniversityDropdownValue,
                                //   width: double.infinity,
                                //   contentPadding: const EdgeInsets.symmetric(
                                //     horizontal: 10,
                                //     vertical: 0,
                                //   ),
                                //   onChanged: (String? newValue) {
                                //     print(newValue);
                                //     widget.profileBloc.university = newValue!;
                                //     // selectedNewUniversity=newValue;
                                //     // widget.profileBloc.add(
                                //     //     UpdateUniversityDropdownValues(
                                //     //         newValue));
                                //   },
                                // ),
                              // if (AppData.userType!="doctor")
                              //   const SizedBox(height: 10),
                              // if (AppData.userType != "doctor" &&
                              //     state.selectedUniversityDropdownValue ==
                              //         'Add new University')
                            ],
                          );
                        } else {
                          return Text(translation(context).msg_something_wrong);
                        }
                      }),
                10.height,
                if (isEditModeMap)
                  svAppButton(
                    context: context,
                    // style: svAppButton(text: text, onTap: onTap, context: context),
                    onTap: () async {
                      setState(() {
                        isEditModeMap = false;
                      });
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                      }
                      widget.profileBloc.add(UpdateProfileEvent(
                        updateProfileSection: 1,
                        userProfile: widget.profileBloc.userProfile,
                        userProfilePrivacyModel: UserProfilePrivacyModel(),
                      ));
                    },
                    text: translation(context).lbl_update,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
