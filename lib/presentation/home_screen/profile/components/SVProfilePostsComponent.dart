import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/core/utils/size_utils.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/interested_info_screen/interested_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/personal_info_screen/personal_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/privacy_info_screen/privacy_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/professional_info_screen/professional_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/work_info_screen/work_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/profile/components/my_post_component.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:doctak_app/widgets/custome_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../theme/app_decoration.dart';
import '../../../../widgets/custom_image_view.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Container(
                color: Colors.grey,
                width: 1,
                height: 20,
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
              : AboutWidget(profileBloc: widget.profileBloc,)
         // : EditProfileScreen(widget.profileBloc),
        ],
      ),
    );
  }
}

class AboutWidget extends StatelessWidget {
   AboutWidget({required this.profileBloc,super.key});
  ProfileBloc profileBloc;
  @override
  Widget build(BuildContext context) {
    return _buildScrollview(context,profileBloc);
  }
}

Widget _buildColumnlockone(BuildContext context,profileBloc) {
  return Column(
    children: [
      _buildRowinterested(
        onTap: (){
          PersonalInfoScreen(profileBloc:profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_lock.svg',
        interested: "Personal Information",
      ),
      const SizedBox(height: 10),
      _buildRowinterested(
        onTap: (){
          ProfessionalInfoScreen(profileBloc:profileBloc).launch(context);

        },
        context,
        imageOne: 'assets/icon/ic_frame.svg',
        interested: "Professional Information",
      ),
      SizedBox(height: 10),
      _buildRowinterested(
        onTap: (){
          WorkInfoScreen(profileBloc:profileBloc).launch(context);

        },
        context,
        imageOne: 'assets/icon/ic_calendar.svg',
        interested: "Work Information",
      ),
      SizedBox(height: 10),
      _buildRowinterested(
        onTap: (){
          InterestedInfoScreen(profileBloc:profileBloc).launch(context);

        },
        context,
        imageOne: 'assets/icon/ic_person.svg',
        interested: "Interested Information",
      ),
      SizedBox(height: 10),
      _buildRowinterested(
        onTap: (){
          PrivacyInfoScreen(profileBloc:profileBloc).launch(context);

        },
        context,
        imageOne: 'assets/icon/ic_privacy.svg',
        interested: "Privacy Information",
      ),
    ],
  );
}

/// Section Widget
Widget _buildScrollview(BuildContext context,profileBloc) {
  return SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.only(top: 20),
      child: Column(
        children: [_buildColumnlockone(context,profileBloc)],
      ),
    ),
  );
}

/// Common widget
Widget _buildRowinterested(
  BuildContext context, {
  required Function onTap,
  required String imageOne,
  required String interested,
}) {
  return GestureDetector(
    onTap: ()=>onTap(),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 18,
      ),
      decoration: AppDecoration.fillGray.copyWith(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImageView(
            color: Colors.black,
            imagePath: imageOne,
            height: 25,
            width: 25,
            margin: EdgeInsets.only(top: 4),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 15,
              top: 1,
            ),
            child: Text(
              interested,
              style: GoogleFonts.poppins(fontSize: 18),
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 25,
          )
        ],
      ),
    ),
  );
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
                  icon: Icons.person,
                  label: 'First Name',
                  value: widget.profileBloc.userProfile?.user?.firstName ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.firstName = value,
                ),
                _buildField(
                  icon: Icons.person,
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
                  icon: Icons.phone,
                  label: 'Phone',
                  value: widget.profileBloc.userProfile?.user?.phone ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.user?.phone = value,
                ),
                _buildDateField(
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
                _buildField(
                  icon: Icons.numbers_rounded,
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
                if (isEditModeMap[0]!)
                  BlocBuilder<ProfileBloc, ProfileState>(
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
                                  widget.profileBloc.country = newValue!;

                                  widget.profileBloc
                                      .add(UpdateFirstDropdownValue(newValue));
                                  // widget.profileBloc.add(UpdateSecondDropdownValues(newValue));
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
                                    widget.profileBloc.add(
                                        UpdateSpecialtyDropdownValue(
                                            newValue!));
                                  },
                                ),
                              if (AppData.userType != "doctor")
                                const SizedBox(height: 10),
                              if (AppData.userType != "doctor")
                                CustomDropdownButtonFormField(
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
              ],
            ),
            const Divider(
              color: Colors.grey,
            ),
            _buildCard(
              title: 'Professional Information',
              categoryIndex: 1,
              children: [
                _buildField(
                  icon: Icons.location_on,
                   index: 1,
                  label: 'Address',
                  value: widget.profileBloc.userProfile?.profile?.address ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile?.profile?.address = value,
                ),
                // const Divider(),
                _buildField(
                  icon: Icons.account_circle,
                  index: 1,
                  label: 'About Me',
                  value: widget.profileBloc.userProfile?.profile?.aboutMe ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.aboutMe = value,
                  maxLines: 3,
                ),
                // const Divider(),
                _buildField(
                  icon: Icons.location_on,
                  index: 1,
                  label: 'Birth Place',
                  value:
                      widget.profileBloc.userProfile?.profile?.birthplace ?? '',
                  onSave: (value) => widget
                      .profileBloc.userProfile!.profile?.birthplace = value,
                  maxLines: 3,
                ),
                // const Divider(),
                _buildField(
                  icon: Icons.sports,
                  index: 1,
                  label: 'Hobbies',
                  value: widget.profileBloc.userProfile?.profile?.hobbies ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.hobbies = value,
                  maxLines: 3,
                ),
                // const Divider(),
                _buildField(
                  icon: Icons.live_help,
                  index: 1,
                  label: 'Lives In',
                  value: widget.profileBloc.userProfile?.profile?.livesIn ?? '',
                  onSave: (value) =>
                      widget.profileBloc.userProfile!.profile?.livesIn = value,
                  maxLines: 3,
                ),
              ],
            ),
            const Divider(
              color: Colors.grey,
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
            const Divider(
              color: Colors.grey,
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
            const Divider(
              color: Colors.grey,
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
    return Container(
      margin: const EdgeInsets.only(top: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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

  Widget _buildField(
      {required int index,
      required String label,
      required String value,
      void Function(String)? onSave,
      int? maxLines,
      required IconData icon}) {
    return isEditModeMap[index]!
        ? Container(
            margin: const EdgeInsets.only(top: 4),
            child: CustomTextField(
                hintText: label,
                textInputType: TextInputType.text,
                prefix: Container(
                    margin: EdgeInsets.fromLTRB(24, 16, 16, 16),
                    child: Icon(
                      icon,
                      size: 24,
                      color: Colors.blueGrey,
                      // imagePath: Icon(Icons),
                      // height: 24,
                      // width: 24
                    )),
                prefixConstraints: BoxConstraints(maxHeight: 56),
                initialValue: value,
                maxLines: maxLines,
                onSaved: (v) {
                  onSave?.call(v);
                },
                contentPadding:
                    EdgeInsets.only(top: 18, right: 30, bottom: 18)),
          )
        // ?  TextFormField(
        //           initialValue: value,
        //           decoration: InputDecoration(
        //               labelText: label,
        //               labelStyle: const TextStyle(
        //                   color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        //           maxLines: maxLines,
        //           onSaved: (v) => onSave?.call(v!),
        //         )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${capitalizeWords(label)}:',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                capitalizeWords(value),
                style: const TextStyle(fontSize: 16),
              ),
            ],
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
                      icon: Icons.work,
                      index: 2,
                      label: 'Company Name',
                      value: entry.name ?? '',
                      onSave: (value) => entry.name = value,
                    ),
                    _buildField(
                      icon: Icons.type_specimen,
                      index: 2,
                      label: 'Position',
                      value: entry.position ?? "",
                      onSave: (value) => entry.position = value,
                    ),
                    _buildField(
                      icon: Icons.location_on,
                      index: 2,
                      label: 'Address',
                      value: entry.address ?? "",
                      onSave: (value) => entry.address = value,
                    ),
                    _buildField(
                      icon: Icons.description,
                      index: 2,
                      label: 'Degree',
                      value: entry.degree ?? "",
                      onSave: (value) => entry.degree = value,
                    ),
                    _buildField(
                      icon: Icons.book,
                      index: 2,
                      label: 'Courses',
                      value: entry.courses ?? "",
                      onSave: (value) => entry.courses = value,
                    ),
                    _buildField(
                      icon: Icons.book,
                      index: 2,
                      label: 'Work Type',
                      value: entry.workType ?? "",
                      onSave: (value) => entry.workType = value,
                    ),
                    _buildField(
                        icon: Icons.description,
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
                      icon: Icons.description,
                      index: 2,
                      label: 'Interest Type',
                      value: entry.interestType ?? '',
                      onSave: (value) => entry.interestType = value,
                    ),
                    _buildField(
                      icon: Icons.description,
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
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${capitalizeWords(label)}:',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                capitalizeWords(value),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          );
  }

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
    // Create a TextEditingController for the text field
    TextEditingController textEditingController =
        TextEditingController(text: value);

    return isEditModeMap[index]!
        ? Container(
            margin: const EdgeInsets.only(top: 4),
            child: CustomTextFormField(
              hintText: label,
              isReadOnly: true,
              textInputType: TextInputType.datetime,
              controller: textEditingController,
              // Pass the controller here
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  print(pickedDate);
                  DateTime dateTime =
                      DateTime.parse(pickedDate.toIso8601String());

// Format the DateTime object to display only the date portion
                  String formattedDate =
                      "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";

                  // Update the text field value when a date is selected
                  textEditingController.text = formattedDate;
                  // Call onSave if provided

                  onSave?.call(formattedDate);
                }
              },
              prefix: Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                child: Icon(
                  Icons.date_range_outlined,
                  size: 24,
                  color: Colors.blueGrey,
                ),
              ),
              prefixConstraints: BoxConstraints(maxHeight: 56),
              validator: (value) {
                return null;
              },
              contentPadding:
                  EdgeInsets.only(top: 18, right: 30, bottom: 18),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${capitalizeWords(label)}:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                capitalizeWords(value),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          );
  }

  // Widget _buildDateField({
  //   required int index,
  //   required String label,
  //   required String value,
  //   void Function(String)? onSave,
  // }) {
  //   return isEditModeMap[index]!
  //       ? Container(
  //           margin: const EdgeInsets.only(top: 4),
  //           child: CustomTextFormField(
  //               hintText: label,
  //               textInputType: TextInputType.datetime,
  //               isReadOnly: true,
  //               initialValue: value,
  //               onTap: () async {
  //                 final pickedDate = await showDatePicker(
  //                   context: context,
  //                   initialDate: DateTime.now(),
  //                   firstDate: DateTime(1900),
  //                   lastDate: DateTime(2101),
  //                 );
  //
  //                 if (pickedDate != null) {
  //                   print(pickedDate);
  //                   setState(() {
  //
  //                   onSave?.call(pickedDate.toIso8601String().toString());
  //                   });
  //
  //                 }
  //               },
  //               onSaved: (v) => onSave!.call(v),
  //               prefix: Container(
  //                   margin: EdgeInsets.fromLTRB(24, 16.v, 16, 16),
  //                   child: Icon(
  //                     Icons.date_range_outlined,
  //                     size: 24,
  //                     color: Colors.blueGrey,
  //                     // imagePath: Icon(Icons),
  //                     // height: 24,
  //                     // width: 24
  //                   )),
  //               prefixConstraints: BoxConstraints(maxHeight: 56),
  //               validator: (value) {
  //                 // if (value == null ||
  //                 //     (!isValidEmail(value,
  //                 //         isRequired: true))) {
  //                 //   return translation(context)
  //                 //       .err_msg_please_enter_valid_email;
  //                 // }
  //                 return null;
  //               },
  //               contentPadding: EdgeInsets.only(top: 18.v, right: 30, bottom: 18)),
  //         )
  //       :  Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Text(
  //         '${capitalizeWords(label)}:',
  //         style:
  //         const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //       ),
  //       Text(
  //         capitalizeWords(value),
  //         style: const TextStyle(fontSize: 16),
  //       ),
  //     ],
  //   );
  // }

// Function to print updated information
  void printUpdatedInformation() {
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
