import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
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
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/custom_text_form_field.dart';
import 'package:doctak_app/widgets/custome_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

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
      const SizedBox(height: 10),
      _buildRowinterested(
        onTap: (){
          WorkInfoScreen(profileBloc:profileBloc).launch(context);

        },
        context,
        imageOne: 'assets/icon/ic_calendar.svg',
        interested: "Work Information",
      ),
      const SizedBox(height: 10),
      _buildRowinterested(
        onTap: (){
          InterestedInfoScreen(profileBloc:profileBloc).launch(context);

        },
        context,
        imageOne: 'assets/icon/ic_person.svg',
        interested: "Interested Information",
      ),
      const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(top: 20),
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
              style: GoogleFonts.poppins(fontSize: 12.sp,fontWeight: FontWeight.w500,color: svGetBodyColor(),),
            ),
          ),
          const Spacer(),
           Icon(
            Icons.arrow_forward_ios_rounded,
            size: 25,
            color:svGetBodyColor(),
          )
        ],
      ),
    ),
  );
}

