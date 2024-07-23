import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/models/SVSearchModel.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nb_utils/nb_utils.dart';

import '../bloc/search_people_bloc.dart';

// class SVSearchCardComponent extends StatelessWidget {
//   final Data element;
//   Function onTap;
//   SearchPeopleBloc bloc;
//
//
//   SVSearchCardComponent({required this.element,required this.onTap,required this.bloc});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 1,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 element.profilePic ==''? Image.asset('images/socialv/faces/face_5.png', height: 56, width: 56, fit: BoxFit.cover).cornerRadiusWithClipRRect(8):
//                 Image.network('${AppData.imageUrl}${element.profilePic.validate()}', height: 56, width: 56, fit: BoxFit.cover).cornerRadiusWithClipRRect(8),
//                 20.width,
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(element.firstName.validate(), style: boldTextStyle()),
//                         6.width,
//                         element.isCurrentUser.validate()
//                             ? Image.asset('images/socialv/icons/ic_TickSquare.png', height: 14, width: 14, fit: BoxFit.cover)
//                             : Offstage(),
//                       ],
//                     ),
//                     6.height,
//                     Text(element.userType.validate(), style: secondaryTextStyle(color: svGetBodyColor())),
//                   ],
//                 ),
//               ],
//             ),
//            AppButton(
//               shapeBorder: RoundedRectangleBorder(borderRadius: radius(30)),
//               text:element.isFollowedByCurrentUser == true ? 'Unfollow':'Follow',
//               textStyle: boldTextStyle(color: Colors.white,size: 10),
//               onTap: onTap,
//               elevation: 0,
//               color: SVAppColorPrimary,
//             ),
//             //
//             //Image.asset(
//             //   'images/socialv/icons/ic_CloseSquare.png',
//             //   height: 20,
//             //   width: 20,
//             //   fit: BoxFit.cover,
//             //   color: context.iconColor,
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../bloc/search_people_bloc.dart';

class SVSearchCardComponent extends StatefulWidget {
  final Data element;
  final Function onTap;
  final SearchPeopleBloc bloc;

  SVSearchCardComponent(
      {required this.element, required this.onTap, required this.bloc});

  @override
  _SVSearchCardComponentState createState() => _SVSearchCardComponentState();
}

class _SVSearchCardComponentState extends State<SVSearchCardComponent> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Material(
        elevation: 2,
        color: context.cardColor,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        SVProfileFragment(userId: widget.element.id)
                            .launch(context);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: widget.element.profilePic == ''
                            ? Image.asset('images/socialv/faces/face_5.png',
                                    height: 56, width: 56, fit: BoxFit.cover)
                                .cornerRadiusWithClipRRect(8)
                                .cornerRadiusWithClipRRect(8)
                            : CachedNetworkImage(
                                    imageUrl:
                                        '${AppData.imageUrl}${widget.element.profilePic.validate()}',
                                    height: 56,
                                    width: 56,
                                    fit: BoxFit.cover)
                                .cornerRadiusWithClipRRect(30),
                      ),
                    ),
                    10.width,
                    GestureDetector(
                      onTap: () {
                        SVProfileFragment(userId: widget.element.id)
                            .launch(context);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                  width: 150,
                                  child: Text(
                                      "${widget.element.firstName.validate()} ${widget.element.lastName.validate()}",
                                      overflow: TextOverflow.clip,
                                      style: boldTextStyle())),
                              6.width,
                              widget.element.isCurrentUser.validate()
                                  ? Image.asset(
                                      'images/socialv/icons/ic_TickSquare.png',
                                      height: 14,
                                      width: 14,
                                      fit: BoxFit.cover)
                                  : const Offstage(),
                            ],
                          ),
                          Text(widget.element.userType.validate(),
                              style:
                                  secondaryTextStyle(color: svGetBodyColor())),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              isLoading
                  ? CircularProgressIndicator(
                      color: svGetBodyColor(),
                    )
                  : AppButton(
                      shapeBorder:
                          RoundedRectangleBorder(borderRadius: radius(10)),
                      text: widget.element.isFollowedByCurrentUser == true
                          ? 'Unfollow'
                          : 'Follow',
                      textStyle: boldTextStyle(
                          color: widget.element.isFollowedByCurrentUser != true
                              ? SVAppColorPrimary
                              : buttonUnSelectColor,
                          size: 10),
                      onTap: () async {
                        setState(() {
                          isLoading =
                              true; // Set loading state to true when button is clicked
                        });

                        // Perform API call
                        widget.onTap();

                        setState(() {
                          isLoading =
                              false; // Set loading state to false after API response
                        });
                      },
                      elevation: 0,
                      color: widget.element.isFollowedByCurrentUser == true
                          ? SVAppColorPrimary
                          : buttonUnSelectColor,
                    ),
              // ElevatedButton(
              //   // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              //   onPressed: () async {
              //     setState(() {
              //       isLoading = true; // Set loading state to true when button is clicked
              //     });
              //
              //     // Perform API call
              //     await widget.onTap();
              //
              //     setState(() {
              //       isLoading = false; // Set loading state to false after API response
              //     });
              //   },
              //   child: isLoading
              //       ? CircularProgressIndicator(color: svGetBodyColor(),) // Show progress indicator if loading
              //       : Text(widget.element.isFollowedByCurrentUser == true ? 'Unfollow' : 'Follow', style: boldTextStyle(color: Colors.white, size: 10)),
              //   style: ElevatedButton.styleFrom(
              //     // primary: Colors.blue, // Change button color as needed
              //     elevation: 0,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
