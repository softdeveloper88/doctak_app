import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/profile/components/my_post_component.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../fragments/profile_screen/bloc/profile_state.dart';
import '../../utils/SVColors.dart';

class SVProfilePostsComponent extends StatefulWidget {
  ProfileBloc profileBloc;

  SVProfilePostsComponent(this.profileBloc, {Key? key}) : super(key: key);

  @override
  State<SVProfilePostsComponent> createState() =>
      _SVProfilePostsComponentState();
}

class _SVProfilePostsComponentState extends State<SVProfilePostsComponent> {
  int selectedIndex = 0;

  List<String> allPostList = [
    'images/socialv/posts/post_one.png',
    'images/socialv/posts/post_two.png',
    'images/socialv/posts/post_three.png',
    'images/socialv/posts/post_one.png',
    'images/socialv/posts/post_two.png',
    'images/socialv/posts/post_three.png',
    'images/socialv/posts/post_one.png',
    'images/socialv/posts/post_two.png',
    'images/socialv/posts/post_three.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: context.cardColor, borderRadius: radius(SVAppContainerRadius)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  TextButton(
                    onPressed: () {
                      selectedIndex = 0;
                      setState(() {});
                    },
                    child: Text(
                      'All Post',
                      style: TextStyle(
                        color: SVAppColorPrimary,
                        fontSize: 14,
                        fontWeight: selectedIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Container(
                    height: 2,
                    width: context.width() / 2 - 32,
                    color: selectedIndex == 0
                        ? SVAppColorPrimary
                        : SVAppColorPrimary.withOpacity(0.5),
                  ),
                ],
              ),
              Column(
                children: [
                  TextButton(
                    onPressed: () {
                      selectedIndex = 1;
                      setState(() {});
                    },
                    child: Text(
                      'About',
                      style: TextStyle(
                        color: SVAppColorPrimary,
                        fontSize: 14,
                        fontWeight: selectedIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Container(
                    height: 2,
                    width: context.width() / 2 - 32,
                    color: selectedIndex == 1
                        ? SVAppColorPrimary
                        : SVAppColorPrimary.withOpacity(0.5),
                  ),
                ],
              ),
              16.height,
            ],
          ),
          16.height,
          selectedIndex == 0
              ? MyPostComponent(widget.profileBloc)
              // GridView.builder(
              //         itemCount: allPostList.length,
              //         shrinkWrap: true,
              //         physics: const NeverScrollableScrollPhysics(),
              //         itemBuilder: (BuildContext context, int index) {
              //           return Image.asset(allPostList[index],
              //                   height: 100, fit: BoxFit.cover)
              //               .cornerRadiusWithClipRRect(8);
              //         },
              //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              //           crossAxisCount: 3,
              //           crossAxisSpacing: 16,
              //           mainAxisSpacing: 16,
              //           childAspectRatio: 1,
              //         ),
              //       )
              : EditProfileScreen(widget.profileBloc),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  ProfileBloc profileBloc;

  EditProfileScreen(this.profileBloc);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // UserProfile userProfile = UserProfile();
  Map<int, bool> isEditModeMap = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false, // Privacy Information
  };

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              title: 'Personal Information',
              categoryIndex: 0,
              children: [
                _buildField(
                  index: 0,
                  label: 'First Name',
                  value: widget.profileBloc.userProfile?.user?.firstName ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.firstName = value,
                ),
                _buildField(
                  index: 0,
                  label: 'Last Name',
                  value: widget.profileBloc.userProfile?.user?.lastName ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.lastName = value,
                ),
                // _buildField(
                //   index: 0,
                //   label: 'Speciality',
                //   value: widget.profileBloc.userProfile?.user?.specialty ?? '',
                //   onSave: (value) =>
                //       widget.profileBloc.userProfile?.user?.specialty = value,
                // ),
                _buildField(
                  index: 0,
                  label: 'Phone',
                  value: widget.profileBloc.userProfile?.user?.phone ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.phone = value,
                ),
                _buildField(
                  index: 0,
                  label: 'Date of Birth',
                  value: widget.profileBloc.userProfile?.user?.dob ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.dob = value,
                ),
                _buildField(
                  index: 0,
                  label: 'License No',
                  value: widget.profileBloc.userProfile?.user?.licenseNo ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.licenseNo = value,
                ),
                // _buildField(
                //   index: 0,
                //   label: 'Country',
                //   value: widget.profileBloc.userProfile?.user?.country ?? '',
                //   onSave: (value) =>
                //       widget.profileBloc.userProfile?.user?.country = value,
                // ),
                // _buildField(
                //   index: 0,
                //   label: 'City',
                //   value: widget.profileBloc.userProfile?.user?.city ?? '',
                //   onSave: (value) =>
                //       widget.profileBloc.userProfile?.user?.city = value,
                // ),
                if (isEditModeMap[0]!)BlocBuilder<ProfileBloc, ProfileState>(
                    bloc: widget.profileBloc,
                    builder: (context, state) {
                      if (state is PaginationLoadedState) {
                        return Column(
                          children: [
                            const SizedBox(height: 10),
                            CustomDropdownButtonFormField(
                              items: state.firstDropdownValues,
                              value: state.selectedFirstDropdownValue,
                              width: double.infinity,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              onChanged: (String? newValue) {
                                widget.profileBloc.country=newValue!;

                                widget.profileBloc.add(UpdateFirstDropdownValue(newValue!));
                              },
                            ),
                            const SizedBox(height: 10),
                            CustomDropdownButtonFormField(
                              items: state.secondDropdownValues,
                              value: state.selectedSecondDropdownValue,
                              width: double.infinity,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              onChanged: (String? newValue) {
                                widget.profileBloc.stateName=newValue!;
                                widget.profileBloc.add(UpdateSpecialtyDropdownValue(state.selectedSecondDropdownValue));
                                widget.profileBloc.add(UpdateUniversityDropdownValues(newValue!));
                              },
                            ),
                            if (AppData.userType == "doctor")
                              const SizedBox(height: 10),
                            if (AppData.userType == "doctor")
                              CustomDropdownButtonFormField(
                                items: state.specialtyDropdownValue,
                                value: state.selectedSpecialtyDropdownValue,
                                width: double.infinity,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                onChanged:(String? newValue) {
                                  print(newValue);
                                  print("Specialty $newValue");
                                  widget.profileBloc.specialtyName=newValue!;
                                 widget.profileBloc.add(UpdateSpecialtyDropdownValue(newValue!));
                                },
                              ),
                            if (AppData.userType != "doctor")
                              const SizedBox(height: 10),
                            if (AppData.userType != "doctor")
                              CustomDropdownButtonFormField(
                                items: state.universityDropdownValue,
                                value: state.selectedUniversityDropdownValue == ''
                                        ? null
                                        : state.selectedUniversityDropdownValue,
                                width: double.infinity,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                onChanged: (String? newValue) {
                                  print(newValue);
                                  widget.profileBloc.university=newValue!;
                                  // selectedNewUniversity=newValue;
                                  widget.profileBloc.add(
                                      UpdateUniversityDropdownValues(
                                          newValue!));
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
              ],
            ),
            _buildCard(
              title: 'Professional Information',
              categoryIndex: 1,
              children: [
                _buildField(
                  index: 1,
                  label: 'Address',
                  value: widget.profileBloc.userProfile?.profile?.address ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.profile?.address = value,
                ),
                const Divider(),
                _buildField(
                  index: 1,
                  label: 'About Me',
                  value: widget.profileBloc.userProfile?.profile?.aboutMe ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.aboutMe = value,
                  maxLines: 3,
                ),
                const Divider(),
                _buildField(
                  index: 1,
                  label: 'Birth Place',
                  value:
                      widget.profileBloc.userProfile?.profile?.birthplace ?? '',
                  onSave: (value) => widget
                      .profileBloc.userProfile!.profile?.birthplace = value,
                  maxLines: 3,
                ),
                const Divider(),
                _buildField(
                  index: 1,
                  label: 'Hobbies',
                  value: widget.profileBloc.userProfile?.profile?.hobbies ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.hobbies = value,
                  maxLines: 3,
                ),
                const Divider(),
                _buildField(
                  index: 1,
                  label: 'Lives In',
                  value: widget.profileBloc.userProfile?.profile?.livesIn ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.livesIn = value,
                  maxLines: 3,
                ),
              ],
            ),
            _buildCard(
              title: 'Work Information',
              categoryIndex: 2,
              children: [
                _buildWorkInfoFields(),
                if (isEditModeMap[2]!)
                  _buildElevatedButton(
                    onPressed: () {
                      setState(() {
                        widget.profileBloc.workEducationList!
                            .add(WorkEducationModel());
                        // userProfile.workInfoList.add(WorkInfo());
                      });
                    },
                    label: 'Add Work Info',
                  ),
              ],
            ),
            _buildCard(
              title: 'Interested Information',
              categoryIndex: 2,
              children: [
                _buildInterestedInfoFields(),
                if (isEditModeMap[2]!)
                  _buildElevatedButton(
                    onPressed: () {
                      setState(() {
                        widget.profileBloc.interestList!.add(InterestModel());
                      });
                    },
                    label: 'Add Interest Info',
                  ),
              ],
            ),
            // _buildCard(
            //   title: 'Additional Information',
            //   categoryIndex: 3,
            //   children: [
            //     _buildField(
            //       index: 3,
            //       label: 'Lives In',
            //       value: widget.profileBloc.userProfile?.profile.livesIn ?? '',
            //       onSave: (value) =>
            //       widget.profileBloc.userProfile?.profile.livesIn = value,
            //     ),
            //     _buildField(
            //       index: 3,
            //       label: 'Address',
            //       value: widget.profileBloc.userProfile?.profile.address ?? '',
            //       onSave: (value) =>
            //       widget.profileBloc.userProfile?.profile.address = value,
            //     ),
            //   ],
            // ),
            _buildCard(
              title: 'Privacy Information',
              categoryIndex: 4,
              children: [
                _buildPrivacyInfoFields(),
              ],
            ),
            const SizedBox(height: 20),
            if (isEditModeMap.values.any((value) => value)) _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required int categoryIndex,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.profileBloc.isMe) _buildEditIcon(categoryIndex),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required int index,
    required String label,
    required String value,
    void Function(String)? onSave,
    int? maxLines,
  }) {
    return isEditModeMap[index]!
        ? TextFormField(
            initialValue: value,
            decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                    color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            maxLines: maxLines,
            onSaved: (v) => onSave?.call(v!),
          )
        : Text(
            '$label: $value',
            style: const TextStyle(fontSize: 16),
          );
  }

  Widget _buildWorkInfoFields() {
    return Column(
      children: widget.profileBloc.workEducationList!
          .map(
            (entry) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Work Experience ${1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      index: 2,
                      label: 'Company Name',
                      value: entry.name ?? '',
                      onSave: (value) => entry.name = value,
                    ),
                    _buildField(
                      index: 2,
                      label: 'Position',
                      value: entry.position ?? "",
                      onSave: (value) => entry.position = value,
                    ),
                    _buildField(
                      index: 2,
                      label: 'Address',
                      value: entry.address ?? "",
                      onSave: (value) => entry.address = value,
                    ),
                    _buildField(
                      index: 2,
                      label: 'Degree',
                      value: entry.degree ?? "",
                      onSave: (value) => entry.degree = value,
                    ),
                    _buildField(
                      index: 2,
                      label: 'Courses',
                      value: entry.courses ?? "",
                      onSave: (value) => entry.courses = value,
                    ),
                    _buildField(
                      index: 2,
                      label: 'Work Type',
                      value: entry.workType ?? "",
                      onSave: (value) => entry.workType = value,
                    ),
                    _buildField(
                        index: 2,
                        label: 'Description',
                        value: entry.description ?? "",
                        onSave: (value) => entry.description = value,
                        maxLines: 3),
                    _buildDateField(
                      index: 2,
                      label: 'Start Date',
                      value: entry.startDate ?? '',
                      onSave: (value) => entry.startDate = value,
                    ),
                    _buildDateField(
                      index: 2,
                      label: 'End Date',
                      value: entry.endDate ?? '',
                      onSave: (value) => entry.endDate = value,
                    ),
                    const SizedBox(height: 10),
                    _buildElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.profileBloc.workEducationList!.remove(entry);
                        });
                      },
                      label: 'Remove Work Info',
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInterestedInfoFields() {
    int i = 1;
    return Column(
      children: widget.profileBloc.interestList!
          .map(
            (entry) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Interest',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      index: 2,
                      label: 'Interest Type',
                      value: entry.interestType ?? '',
                      onSave: (value) => entry.interestType = value,
                    ),
                    _buildField(
                      index: 2,
                      label: 'Interest Details',
                      value: entry.interestDetails ?? "",
                      onSave: (value) => entry.interestDetails = value,
                    ),
                    const SizedBox(height: 10),
                    _buildElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.profileBloc.interestList!.remove(entry);
                        });
                      },
                      label: 'Remove Interest Info',
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  UserProfilePrivacyModel userProfile = UserProfilePrivacyModel();

  Widget _buildPrivacyInfoFields() {
    // return Column(
    //   children: [
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'About me privacy',
    //       value: userProfile.aboutMePrivacy??'lock',
    //       onSave: (value) => userProfile.aboutMePrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Address privacy',
    //       value: userProfile.addressPrivacy??'lock',
    //       onSave: (value) => userProfile.addressPrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Birth place privacy',
    //       value: userProfile.birthPlacePrivacy??'lock',
    //       onSave: (value) => userProfile.birthPlacePrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Language privacy',
    //       value: userProfile.languagePrivacy??'lock',
    //       onSave: (value) => userProfile.languagePrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Live in privacy',
    //       value: userProfile.liveInPrivacy??'lock',
    //       onSave: (value) => userProfile.liveInPrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Email privacy',
    //       value: userProfile.emailPrivacy??'lock',
    //       onSave: (value) => userProfile.emailPrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Gender Privacy',
    //       value: userProfile.genderPrivacy??'lock',
    //       onSave: (value) => userProfile.genderPrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Phone Privacy',
    //       value: userProfile.phonePrivacy??'lock',
    //       onSave: (value) => userProfile.phonePrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'License number Privacy',
    //       value: userProfile.licenseNumberPrivacy??'lock',
    //       onSave: (value) => userProfile.licenseNumberPrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Specialty Privacy',
    //       value: userProfile.specialtyPrivacy??'lock',
    //       onSave: (value) => userProfile.specialtyPrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Country Privacy',
    //       value: userProfile.countryPrivacy??'lock',
    //       onSave: (value) => userProfile.countryPrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'City Privacy',
    //       value: userProfile.cityPrivacy??'lock',
    //       onSave: (value) => userProfile.cityPrivacy = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //     _buildDropdownField(
    //       index: 4,
    //       label: 'Country Origin Privacy',
    //       value: userProfile.countryOrigin??'lock',
    //       onSave: (value) => userProfile.countryOrigin = value,
    //       options: ['lock', 'group', 'globe'],
    //     ),
    //   ],
    // );
    return Column(
      children: widget.profileBloc.userProfile!.privacySetting!.map((item) {
        // if(item.visibility!='crickete update d') {
        return _buildDropdownField(
          index: 4,
          label: '${item.recordType} privacy',
          value:
              item.visibility == null || item.visibility == 'crickete update d'
                  ? 'lock'
                  : item.visibility ?? 'lock',
          onSave: (value) => item.visibility = value,
          options: ['lock', 'group', 'globe'],
        );
        // }else{
        //   return Container();
        // }
      }).toList(),
    );
  }

  Widget _buildDropdownField({
    required int index,
    required String label,
    required String value,
    void Function(String)? onSave,
    required List<String> options,
  }) {
    // Filter out 'crickete update d.' if it exists
    options = options.where((opt) => opt != 'crickete update d.').toList();

    return isEditModeMap[index]!
        ? DropdownButtonFormField<String>(
            value: value,
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (selectedValue) {
              if (selectedValue != value) {
                onSave?.call(selectedValue!);
              }
            },
            decoration: InputDecoration(labelText: label),
          )
        : Text(
            '$label: $value',
            style: const TextStyle(fontSize: 16),
          );
  }

  // Widget _buildDropdownField({
  //   required int index,
  //   required String label,
  //   required String value,
  //   void Function(String)? onSave,
  //   required List<String> options,
  // }) {
  //   return isEditModeMap[index]!
  //       ? DropdownButtonFormField<String>(
  //     value: value,
  //     items: options.map((option) {
  //       return DropdownMenuItem<String>(
  //         value: option,
  //         child: Text(option),
  //       );
  //     }).toList(),
  //     onChanged: (selectedValue) {
  //       if (selectedValue != value) {
  //         // Check if the selected value is different
  //         onSave?.call(selectedValue!);
  //       }
  //     },
  //     decoration: InputDecoration(labelText: label),
  //   )
  //       : Text(
  //     '$label: $value',
  //     style: const TextStyle(fontSize: 16),
  //   );
  // }
  // Widget _buildDropdownField({
  //   required int index,
  //   required String label,
  //   required String value,
  //   void Function(String)? onSave,
  //   required List<String> options,
  // }) {
  //   return isEditModeMap[index]!
  //       ? DropdownButtonFormField<String>(
  //     value: value,
  //     items: options.map((option) {
  //       return DropdownMenuItem<String>(
  //         value: option,
  //         child: Text(option),
  //       );
  //     }).toList(),
  //     onChanged: (selectedValue) {
  //       onSave?.call(selectedValue!);
  //     },
  //     decoration: InputDecoration(labelText: label),
  //   )
  //       : Text(
  //     '$label: $value',
  //     style: const TextStyle(fontSize: 16),
  //   );
  // }

  Widget _buildEditIcon(int categoryIndex) {
    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () {
        setState(() {
          isEditModeMap[categoryIndex] = !isEditModeMap[categoryIndex]!;
        });
      },
      tooltip: 'Edit',
    );
  }

  Widget _buildElevatedButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          printUpdatedInformation();
          setState(() {
            isEditModeMap.forEach((key, value) {
              isEditModeMap[key] = false;
            });
          });
        }
      },
      child: const Text('Save'),
    );
  }

  Widget _buildDateField({
    required int index,
    required String label,
    required String value,
    void Function(String)? onSave,
  }) {
    return isEditModeMap[index]!
        ? TextFormField(
            readOnly: true,
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2101),
              );

              if (pickedDate != null) {
                setState(() {});
                onSave?.call(pickedDate.toIso8601String().toString());
              }
            },
            decoration: InputDecoration(labelText: label),
            controller: TextEditingController(text: value),
          )
        : Text(
            '$label: $value',
            style: const TextStyle(fontSize: 16),
          );
  }

// Function to print updated information
  void printUpdatedInformation() {
    print('Updated User Profile Information:');
    print('First Name: ${widget.profileBloc.userProfile?.user?.firstName}');
    print('Last Name: ${widget.profileBloc.userProfile?.user?.lastName}');
    // Add similar print statements for other fields you want to track
    // ...
    widget.profileBloc.add(UpdateProfileEvent(
      userProfile: widget.profileBloc.userProfile,
      interestModel: widget.profileBloc.interestList,
      workEducationModel: widget.profileBloc.workEducationList,
      userProfilePrivacyModel: userProfile,
    ));
    // print(
    //     "privacy ${widget.profileBloc.userProfile!.privacySetting![0].visibility!}");
    // // Print work info
    print('Work Information:');
    for (var workInfo in widget.profileBloc.workEducationList!) {
      print('Company Name: ${workInfo.name}');
      print('Company degree: ${workInfo.degree}');
      print('Position: ${workInfo.position}');
      print('Start Date: ${workInfo.startDate}');
      print('End Date: ${workInfo.endDate}');
      // Add similar print statements for other work info fields you want to track
      // ...
    }

    // Print interest info
    print('Interest Information:');
    for (var interestInfo in widget.profileBloc.interestList!) {
      print('Interest Type: ${interestInfo.interestType}');
      print('Interest Details: ${interestInfo.interestDetails}');
    }
  }
}
