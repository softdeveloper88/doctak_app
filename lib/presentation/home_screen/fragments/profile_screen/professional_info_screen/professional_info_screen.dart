import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../../../../core/app_export.dart';
import '../../../utils/SVColors.dart';
import '../../../utils/SVCommon.dart';
import '../bloc/profile_state.dart';

class ProfessionalInfoScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  ProfessionalInfoScreen({required this.profileBloc, super.key});

  @override
  State<ProfessionalInfoScreen> createState() => _ProfessionalInfoScreenState();
}

bool isEditModeMap = false;
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class _ProfessionalInfoScreenState extends State<ProfessionalInfoScreen> {
  @override
  void initState() {
    isEditModeMap = false;
    widget.profileBloc.add(UpdateSpecialtyDropdownValue(''));

    super.initState();
  }

  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        surfaceTintColor: svGetScaffoldColor(),
        title: Text('Professional Summary', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios)),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          if (widget.profileBloc.isMe)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MaterialButton(
                textColor: Colors.black,
                onPressed: () {
                  setState(() {
                    isEditModeMap = !isEditModeMap;
                  });
                },
                elevation: 6,
                color: Colors.white,
                minWidth: 40,
                shape: RoundedRectangleBorder(
                  borderRadius: radius(100),
                  side: const BorderSide(color: Colors.blue),
                ),
                animationDuration: const Duration(milliseconds: 300),
                focusColor: SVAppColorPrimary,
                hoverColor: SVAppColorPrimary,
                splashColor: SVAppColorPrimary,
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomImageView(
                      onTap: () {
                        setState(() {
                          isEditModeMap = !isEditModeMap;
                        });
                      },
                      color: Colors.blue,
                      imagePath: 'assets/icon/ic_vector.svg',
                      height: 15,
                      width: 15,
                      // margin: const EdgeInsets.only(bottom: 4),
                    ),
                    Text(
                      "Edit",
                      style:  TextStyle(fontFamily: 'Poppins-Light',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (isEditModeMap)
                  BlocBuilder<ProfileBloc, ProfileState>(
                      bloc: widget.profileBloc,
                      builder: (context, state) {
                        if (state is PaginationLoadedState) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (AppData.userType == "doctor")
                                const SizedBox(height: 10),
                              if (AppData.userType == "doctor")
                                Text(
                                  'Title and Specialization',
                                  style:  TextStyle(fontFamily: 'Poppins-Light',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (AppData.userType == "doctor")
                                CustomDropdownButtonFormField(
                                  items: state.specialtyDropdownValue,
                                  value: state.selectedSpecialtyDropdownValue,
                                  width: double.infinity,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 0,
                                  ),
                                  onChanged: (String? newValue) {
                                    print(newValue);
                                    print("Specialty $newValue");
                                    widget.profileBloc.specialtyName =
                                        newValue!;
                                    widget.profileBloc.userProfile?.user
                                        ?.specialty = newValue;
                                    widget.profileBloc.add(
                                        UpdateSpecialtyDropdownValue(newValue));
                                  },
                                ),
                              if (AppData.userType != "doctor")
                                const SizedBox(height: 10),
                              // if (AppData.userType!="doctor")
                              //   const SizedBox(height: 10),
                              // if (AppData.userType != "doctor" &&
                              //     state.selectedUniversityDropdownValue ==
                              //         'Add new University')
                            ],
                          );
                        } else {
                          return Text('No widget $state');
                        }
                      }),
                if (!isEditModeMap)
                  TextFieldEditWidget(
                    index: 0,
                    label: 'Title and Specialization',
                    value:
                        widget.profileBloc.userProfile?.user?.specialty ?? '',
                    onSave: (value) =>
                        widget.profileBloc.userProfile?.user?.specialty = value,
                  ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.location_on,
                  index: 1,
                  textInputAction: TextInputAction.newline,
                  textInputType: TextInputType.multiline,
                  focusNode: focusNode1,
                  hints: 'Name Hospital/Clinic/Organization/Private Practice',
                  label: 'Current Workplace',
                  value: widget.profileBloc.userProfile?.profile?.address ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.profile?.address = value,
                ),
                // const Divider(),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.account_circle,
                  index: 1,
                  textInputType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  hints: 'Years of experience',
                  focusNode: focusNode2,
                  label: 'Years of Experience',
                  value: widget.profileBloc.userProfile?.profile?.aboutMe ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.aboutMe = value,
                  maxLines: 1,
                ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.location_on,
                  index: 1,
                  textInputAction: TextInputAction.newline,
                  hints: 'e.g Doctor of the year',
                  focusNode: focusNode3,
                  label: 'Notable Achievements',
                  value:
                      widget.profileBloc.userProfile?.profile?.birthplace ?? '',
                  onSave: (value) => widget
                      .profileBloc.userProfile!.profile?.birthplace = value,
                  // maxLines: 1,
                  textInputType: TextInputType.multiline,
                ),
                // if (!isEditModeMap)   Divider(color: Colors.grey[300],indent: 10,endIndent: 10,),
                // TextFieldEditWidget(
                //   isEditModeMap: isEditModeMap,
                //   icon: Icons.sports,
                //   index: 1,
                //   hints: '',
                //   focusNode: focusNode4,
                //   textInputType: TextInputType.multiline,
                //   label: 'Medical Student',
                //   value: widget.profileBloc.userProfile?.profile?.hobbies ?? '',
                //   onSave: (value) =>
                //       widget.profileBloc.userProfile!.profile?.hobbies = value,
                //   maxLines: 3,
                // ),
                if (!isEditModeMap)
                  Divider(
                    color: Colors.grey[300],
                    indent: 10,
                    endIndent: 10,
                  ),
                TextFieldEditWidget(
                  isEditModeMap: isEditModeMap,
                  icon: Icons.live_help,
                  index: 1,
                  textInputAction: TextInputAction.newline,
                  textInputType: TextInputType.multiline,
                  focusNode: focusNode4,
                  hints: 'Enter location (e.g., KSA, UAE)',
                  label: 'Location',
                  value: widget.profileBloc.userProfile?.profile?.hobbies ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.hobbies = value,
                  maxLines: 1,
                ),
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
                        updateProfileSection: 2,
                        userProfile: widget.profileBloc.userProfile,
                        interestModel: widget.profileBloc.interestList,
                        workEducationModel:
                            widget.profileBloc.workEducationList,
                        userProfilePrivacyModel: UserProfilePrivacyModel(),
                      ));
                    },
                    text: 'Update',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
