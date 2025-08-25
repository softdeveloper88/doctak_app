import 'package:doctak_app/core/utils/app/AppData.dart';
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
import 'package:doctak_app/localization/app_localization.dart';

import '../../../../theme/app_decoration.dart';
import '../../../../widgets/custom_image_view.dart';

class SVProfilePostsComponent extends StatefulWidget {
  ProfileBloc profileBloc;

  SVProfilePostsComponent(this.profileBloc, {Key? key}) : super(key: key);

  @override
  State<SVProfilePostsComponent> createState() =>
      _SVProfilePostsComponentState();
}

class _SVProfilePostsComponentState extends State<SVProfilePostsComponent> with SingleTickerProviderStateMixin {
  int selectedIndex = 0;

  // Animation controller for tab transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
      ),
      child: Column(
        children: [
          // Improved tab selector
          Container(
            color: svGetScaffoldColor(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1.5),
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Posts tab
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        _animationController.reset();
                        setState(() {
                          selectedIndex = 0;
                        });
                        _animationController.forward();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedIndex == 0
                              ? Colors.blue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_rounded,
                              size: 18,
                              color: selectedIndex == 0 ? Colors.white : Colors.blue,
                            ),
                            8.width,
                            Text(
                              translation(context).lbl_posts,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: selectedIndex == 0 ? Colors.white : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // About tab
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        _animationController.reset();
                        setState(() {
                          selectedIndex = 1;
                        });
                        _animationController.forward();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedIndex == 1
                              ? Colors.blue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: selectedIndex == 1 ? Colors.white : Colors.blue,
                            ),
                            8.width,
                            Text(
                              translation(context).lbl_about,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: selectedIndex == 1 ? Colors.white : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab content with fade animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: selectedIndex == 0
                ? MyPostComponent(widget.profileBloc)
                : AboutWidget(profileBloc: widget.profileBloc),
          )
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
      // Personal Information card
      _buildRowinterested(
        onTap: () {
          PersonalInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_lock.svg',
        interested: translation(context).lbl_personal_information,
        iconColor: Colors.blue[700]!,
        backgroundColor: Colors.blue.withOpacity(0.08),
      ),
      const SizedBox(height: 12),

      // Professional Summary card
      _buildRowinterested(
        onTap: () {
          ProfessionalInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_frame.svg',
        interested: translation(context).lbl_professional_summary,
        iconColor: Colors.orange[700]!,
        backgroundColor: Colors.orange.withOpacity(0.08),
      ),
      const SizedBox(height: 12),

      // Professional Experience card
      _buildRowinterested(
        onTap: () {
          WorkInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_calendar.svg',
        interested: translation(context).lbl_professional_experience,
        iconColor: Colors.green[700]!,
        backgroundColor: Colors.green.withOpacity(0.08),
      ),
      const SizedBox(height: 12),

      // Interest Information card
      _buildRowinterested(
        onTap: () {
          InterestedInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_person.svg',
        interested: translation(context).lbl_interest_information,
        iconColor: Colors.purple[700]!,
        backgroundColor: Colors.purple.withOpacity(0.08),
      ),
      const SizedBox(height: 12),

      // Privacy Information card
    if(profileBloc.isMe)  _buildRowinterested(
        onTap: () {
          PrivacyInfoScreen(profileBloc: profileBloc).launch(context);
        },
        context,
        imageOne: 'assets/icon/ic_privacy.svg',
        interested: translation(context).lbl_privacy_information,
        iconColor: Colors.red[700]!,
        backgroundColor: Colors.red.withOpacity(0.08),
      ),
    ],
  );
}

/// Section Widget
Widget _buildScrollview(BuildContext context, profileBloc) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [_buildColumnlockone(context, profileBloc)],
    ),
  );
}

/// Common widget with improved styling
Widget _buildRowinterested(
    BuildContext context, {
      required Function onTap,
      required String imageOne,
      required String interested,
      required Color iconColor,
      required Color backgroundColor,
    }) {
  return GestureDetector(
    onTap: () => onTap(),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CustomImageView(
              color: iconColor,
              imagePath: imageOne,
              height: 22,
              width: 22,
            ),
          ),

          // Section title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                interested,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // Arrow icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[700],
            ),
          )
        ],
      ),
    ),
  );
}