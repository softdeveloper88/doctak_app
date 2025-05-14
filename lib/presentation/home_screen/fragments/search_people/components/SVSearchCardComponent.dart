import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/profile_header_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../bloc/search_people_bloc.dart';

class SVSearchCardComponent extends StatefulWidget {
  final Data element;
  final Function onTap;
  final SearchPeopleBloc bloc;

  SVSearchCardComponent({
    required this.element,
    required this.onTap,
    required this.bloc,
  });

  @override
  _SVSearchCardComponentState createState() => _SVSearchCardComponentState();
}

class _SVSearchCardComponentState extends State<SVSearchCardComponent> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery for dynamic padding and scaling
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 15.0),
      child: Material(
        elevation: 0,
        color: context.cardColor,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          child:
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Profile Picture and Name Section
              // Row(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     GestureDetector(
              //       onTap: () {
              //         SVProfileFragment(userId: widget.element.id).launch(context);
              //       },
              //       child: Container(
              //         width: 50,
              //         height: 50,
              //         decoration: BoxDecoration(
              //           shape: BoxShape.circle,
              //           boxShadow: [
              //             BoxShadow(
              //               color: Colors.grey.withOpacity(0.3),
              //               spreadRadius: 1,
              //               blurRadius: 3,
              //               offset: Offset(0, 3),
              //             ),
              //           ],
              //         ),
              //         child: widget.element.profilePic?.isEmpty??true
              //             ? Image.asset(
              //           'images/socialv/faces/face_5.png',
              //           height: 50,
              //           width: 50,
              //           fit: BoxFit.cover,
              //         ).cornerRadiusWithClipRRect(25)
              //             : CachedNetworkImage(
              //           imageUrl:
              //           '${AppData.imageUrl}${widget.element.profilePic.validate()}',
              //           height: 50,
              //           width: 50,
              //           fit: BoxFit.cover,
              //         ).cornerRadiusWithClipRRect(25),
              //       ),
              //     ),
              //     10.width,
              //     GestureDetector(
              //       onTap: () {
              //         SVProfileFragment(userId: widget.element.id).launch(context);
              //       },
              //       child: SizedBox(
              //         width: width * 0.5, // Responsive width for text content
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Wrap(
              //               crossAxisAlignment: WrapCrossAlignment.center,
              //               // crossAxisAlignment: CrossAxisAlignment.center,
              //               children: [
              //                 Expanded(
              //                   child: Text(
              //                     "${widget.element.firstName.validate()} ${widget.element.lastName.validate()}",
              //                     maxLines: 2,
              //                     overflow: TextOverflow.ellipsis,
              //                     style: boldTextStyle(),
              //                   ),
              //                 ),
              //                 // if (widget.element.isCurrentUser.validate())
              //                   6.width,
              //                 // if (widget.element.isCurrentUser.validate())
              //                   Image.asset(
              //                     'images/socialv/icons/ic_TickSquare.png',
              //                     height: 14,
              //                     width: 14,
              //                     fit: BoxFit.cover,
              //                   ),
              //               ],
              //             ),
              //             4.height,
              //             Text(
              //               capitalizeWords(
              //                 widget.element.specialty ??
              //                     widget.element.userType ??
              //                     "Doctor",
              //               ),
              //               maxLines: 1,
              //               overflow: TextOverflow.ellipsis,
              //               style: secondaryTextStyle(color: svGetBodyColor(),size: 16),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              ProfileHeaderWidget(
                profilePicUrl: '${AppData.imageUrl}${widget.element.profilePic.validate()}',
                userName:  "${widget.element.firstName??''} ${widget.element.lastName??''}",
                specialty: capitalizeWords(widget.element.specialty??"Doctor"),
                onProfileTap: (){
                  SVProfileFragment(userId:widget.element.id).launch(context,pageRouteAnimation: PageRouteAnimation.Slide);
                },
                onDeleteTap:()=>(){},
                isCurrentUser:false, // Adjust based on your logic
              ),
              // Follow/Unfollow Button
              MaterialButton(
                height: 30,
                minWidth: 15.w,
                onPressed: () async {
                  setState(() {
                    isLoading = true; // Set loading state
                  });
                  // Perform API call
                  await widget.onTap();
                  setState(() {
                    isLoading = false; // Unset loading state
                  });
                },
                elevation: 0,
                color: widget.element.isFollowedByCurrentUser == true
                    ? SVAppColorPrimary
                    : buttonUnSelectColor,
                shape: RoundedRectangleBorder(borderRadius: radius(8)),
                // shapeBorder: RoundedRectangleBorder(borderRadius: radius(8)),
                child:Text(widget.element.isFollowedByCurrentUser == true
                    ? translation(context).lbl_unfollow
                    : translation(context).lbl_follow,
                style: boldTextStyle(
                  color: widget.element.isFollowedByCurrentUser != true
                      ? SVAppColorPrimary
                      : buttonUnSelectColor,
                  size: 10,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
