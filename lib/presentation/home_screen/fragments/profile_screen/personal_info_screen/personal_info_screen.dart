import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_date_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/component/profile_widget.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';

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

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        title: Text('Personal Information', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios)),
        iconTheme: IconThemeData(color: context.iconColor),
        actions: [
          CustomImageView(
            onTap: () {
              setState(() {
                isEditModeMap =!isEditModeMap;
              });
            },
            color: Colors.black,
            imagePath: 'assets/icon/ic_vector.svg',
            height: 25.adaptSize,
            width: 25.adaptSize,
            margin: EdgeInsets.only(top: 4.v, right: 4.v),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileWidget(
                isEditModeMap: isEditModeMap,
                index: 0,
                icon: Icons.person,
                label: 'First Name',
                value: widget.profileBloc.userProfile?.user?.firstName ?? '',
                onSave: (value) =>
                    widget.profileBloc.userProfile?.user?.firstName = value,
              ),
              if(!isEditModeMap)  const Divider(color: Colors.grey,),
              ProfileWidget(
                isEditModeMap: isEditModeMap,
          
                index: 0,
                icon: Icons.person,
                label: 'Last Name',
                value: widget.profileBloc.userProfile?.user?.lastName ?? '',
                onSave: (value) =>
                    widget.profileBloc.userProfile?.user?.lastName = value,
              ),
              if(!isEditModeMap)  const Divider(color: Colors.grey,),
              ProfileWidget(
                isEditModeMap: isEditModeMap,
                index: 0,
                icon: Icons.person,
                label: 'Phone Number',
                value: widget.profileBloc.userProfile?.user?.phone ?? '',
                onSave: (value) =>
                    widget.profileBloc.userProfile?.user?.phone = value,
              ),
              if(!isEditModeMap) const Divider(color: Colors.grey,),
              ProfileDateWidget(
                isEditModeMap: isEditModeMap,
                index: 0,
                label: 'Date of Birth',
                value: widget.profileBloc.userProfile?.user?.dob ?? '',
                onSave: (value) {
                  setState(() {
                    print(value);
                    widget.profileBloc.userProfile?.user?.dob = value;
                  });
                },
              ),
              if(!isEditModeMap) Divider(color: Colors.grey,),
              ProfileWidget(
                isEditModeMap: isEditModeMap,
                icon: Icons.numbers_rounded,
                index: 0,
                label: 'License No',
                value: widget.profileBloc.userProfile?.user?.licenseNo ?? '',
                onSave: (value) =>
                widget.profileBloc.userProfile?.user?.licenseNo = value,
              ),
              if(!isEditModeMap) Divider(color: Colors.grey,),
              if (!isEditModeMap) ProfileWidget(
                index: 0,
                label: 'Country',
                value: widget.profileBloc.userProfile?.user?.country ?? '',
                onSave: (value) =>
                    widget.profileBloc.userProfile?.user?.country = value,
              ),
              if(!isEditModeMap) Divider(color: Colors.grey,),
              if (!isEditModeMap) ProfileWidget(
                index: 0,
                label: 'City',
                value: widget.profileBloc.userProfile?.user?.city ?? '',
                onSave: (value) =>
                    widget.profileBloc.userProfile?.user?.city = value,
              ),
             if(!isEditModeMap) Divider(color: Colors.grey,),
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
                              'Country',
                              style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500,),
                            ),
                            CustomDropdownButtonFormField(
                              items: state.firstDropdownValues,
                              value: state.selectedFirstDropdownValue,
                              width: double.infinity,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              onChanged: (String? newValue) {
                                widget.profileBloc.country = newValue!;
          
                                widget.profileBloc
                                    .add(UpdateFirstDropdownValue(newValue));
                                // widget.profileBloc.add(UpdateSecondDropdownValues(newValue));
                              },
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'State',
                              style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500,),
                            ),
                            CustomDropdownButtonFormField(
                              items: state.secondDropdownValues,
                              value: state.selectedSecondDropdownValue,
                              width: double.infinity,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              onChanged: (String? newValue) {
                                widget.profileBloc.stateName = newValue!;
                                widget.profileBloc.add(
                                    UpdateSpecialtyDropdownValue(
                                        state.selectedSecondDropdownValue));
                                widget.profileBloc.add(
                                    UpdateUniversityDropdownValues(newValue));
                              },
                            ),
                            if (AppData.userType == "doctor")
                              const SizedBox(height: 10),
                            if (AppData.userType == "doctor")
                              Text(
                                'Specialty',
                                style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500,),
                              ),
                            if (AppData.userType == "doctor") CustomDropdownButtonFormField(
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
                                  widget.profileBloc.add(
                                      UpdateSpecialtyDropdownValue(
                                          newValue!));
                                },
                              ),
                            if (AppData.userType != "doctor")
                              const SizedBox(height: 10),
                            if (AppData.userType != "doctor")
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'University',
                                  style: GoogleFonts.poppins(fontSize:16,fontWeight:FontWeight.w500,),
                                ),
                              ),
                            if (AppData.userType != "doctor")  CustomDropdownButtonFormField(
                                items: state.universityDropdownValue,
                                value:
                                state.selectedUniversityDropdownValue ==
                                    ''
                                    ? null
                                    : state
                                    .selectedUniversityDropdownValue,
                                width: double.infinity,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                onChanged: (String? newValue) {
                                  print(newValue);
                                  widget.profileBloc.university = newValue!;
                                  // selectedNewUniversity=newValue;
                                  widget.profileBloc.add(
                                      UpdateUniversityDropdownValues(
                                          newValue));
                                },
                              ),
                            // if (AppData.userType!="doctor")
                            //   const SizedBox(height: 10),
                            // if (AppData.userType != "doctor" &&
                            //     state.selectedUniversityDropdownValue ==
                            //         'Add new University')
                          ],
                        );
                      } else {
                        return Container(
                          child: Text('No widget $state'),
                        );
                      }
                    }),
              10.height,
              if(isEditModeMap)svAppButton(
                context: context,
                // style: svAppButton(text: text, onTap: onTap, context: context),
                onTap: () async {

                },
                text: 'Update',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

