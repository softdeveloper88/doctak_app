import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

class MeetingJoinRejectDialog extends StatelessWidget {
  final VoidCallback callback;
  final VoidCallback? callbackNegative;
  final String title;
  final String? noButtonText;
  final String? yesButtonText;
  final String? joinName;
  final String? profilePic;

  MeetingJoinRejectDialog(
      {Key? key,
      required this.title,
      required this.callback,
      this.callbackNegative,
      this.yesButtonText,
      this.noButtonText,
      this.joinName,
      this.profilePic})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: confirmationMeetingJoinRejectDialog(
          context,
          title,
          callback,
          yesButtonText ?? translation(context).lbl_delete,
          joinName ?? translation(context).msg_confirm_delete,
          callbackNegative,
          noButtonText,
          profilePic),
    );
  }
}

confirmationMeetingJoinRejectDialog(
    BuildContext context,
    String title,
    VoidCallback callBack,
    String yesButtonText,
    String joinName,
    VoidCallback? callbackNegative,
    noButtonText,
    profilePic) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80.w,
          child: StatefulBuilder(
            builder: (context, snapshot) {
              return Card(
                color: const Color(0xFF263238),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0, bottom: 10.0, left: 16.0, right: 16.0),
                        child: Row(
                          spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: CustomImageView(
                                  height: 50,
                                  width: 50,
                                  imagePath: profilePic,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: RichText(
                                       softWrap: true,
                                        text: TextSpan(
                                            text: joinName,
                                            style: TextStyle(
                                                fontSize: 10.sp,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500),
                                            children: <TextSpan>[
                                          TextSpan(
                                              text: '  $title',
                                              style: const TextStyle(fontSize: 14,color: Colors.grey)),
                                        ]))),
                              ),
                            ]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              width: 30.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade500,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: MaterialButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                onPressed: () => callbackNegative != null
                                    ? () {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .pop('dialog');
                                      }
                                    : callbackNegative,
                                child: Center(
                                  child: Text(
                                    noButtonText ?? translation(context).lbl_cancel,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: 30.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: MaterialButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                onPressed: callBack,
                                child: Center(
                                  child: Text(
                                    yesButtonText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
