import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/interested_info_screen/interested_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/personal_info_screen/personal_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/privacy_info_screen/privacy_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/professional_info_screen/professional_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/work_info_screen/work_info_screen.dart';
import 'package:doctak_app/presentation/home_screen/profile/components/my_post_component.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../../../theme/app_decoration.dart';
import '../../../../widgets/custom_image_view.dart';

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
      // padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
      ),
      child: Column(
        children: [
          Container(
            color: svGetScaffoldColor(),
            padding: const EdgeInsets.all(8.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
              width: 500,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(8))),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selectedIndex = 0;
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        // width: 210,
                        height: 40,
                        decoration: BoxDecoration(
                            color: selectedIndex == 1
                                ? Colors.white
                                : Colors.blue,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(6))),
                        child: Center(
                            child: Text(
                          "All Post",
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color:
                                  selectedIndex == 0 ? Colors.white : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          // style: CustomTextStyles
                          //     .titleMediumOnPrimaryContainer,
                        )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        selectedIndex = 1;
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        // width: 200,
                        height: 40,
                        decoration: BoxDecoration(
                            color:
                                selectedIndex == 0 ? Colors.white : Colors.blue,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(6))),
                        child: Center(
                            child: Text(
                          "About",
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color:selectedIndex == 1
                                  ? Colors.white
                                  : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          // style: CustomTextStyles
                          //     .titleMediumOnPrimaryContainer,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          selectedIndex == 0
              ? MyPostComponent(widget.profileBloc)
              : AboutWidget(
                  profileBloc: widget.profileBloc,
                )
          // : EditProfileScreen(widget.profileBloc),
        ],
      ),
    );
  }
}

class AboutWidget extends StatelessWidget {
  AboutWidget({required this.profileBloc, super.key});

  ProfileBloc profileBloc;

  @override
  Widget build(BuildContext context) {
    return _buildScrollview(context, profileBloc);
  }
}

Widget _buildColumnlockone(BuildContext context, profileBloc) {
  return Column(
    children: [
      _buildRowinterested(
        onTap: () {
          PersonalInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_lock.svg',
        interested: "Personal Information",
      ),
      const SizedBox(height: 10),
      _buildRowinterested(
        onTap: () {
          ProfessionalInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_frame.svg',
        interested: "Professional Summary",
      ),
      const SizedBox(height: 10),
      _buildRowinterested(
        onTap: () {
          WorkInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_calendar.svg',
        interested: "Professional Experience",
      ),
      const SizedBox(height: 10),
      _buildRowinterested(
        onTap: () {
          InterestedInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_person.svg',
        interested: "Interested Information",
      ),
      const SizedBox(height: 10),
      _buildRowinterested(
        onTap: () {
          PrivacyInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_privacy.svg',
        interested: "Privacy Information",
      ),
    ],
  );
}

/// Section Widget
Widget _buildScrollview(BuildContext context, profileBloc) {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [_buildColumnlockone(context, profileBloc)],
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
    onTap: () => onTap(),
    child: Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
      padding: const EdgeInsets.symmetric(
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
            color: svGetBodyColor(),
            imagePath: imageOne,
            height: 25,
            width: 25,
            margin: const EdgeInsets.only(top: 4),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 15,
              top: 1,
            ),
            child: Text(
              interested,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: svGetBodyColor(),
              ),
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 25,
            color: svGetBodyColor(),
          )
        ],
      ),
    ),
  );
}
