import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

class ChatDeleteDialog extends StatelessWidget {
  final VoidCallback callback;
  final String title;

  const ChatDeleteDialog(
      {Key? key, required this.title, required this.callback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: confirmationAlertDialog(context, title, callback),
    );
  }
}

confirmationAlertDialog(
    BuildContext context, String title, VoidCallback callBack) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80.w,
          child: StatefulBuilder(
            builder: (context, snapshot) {
              return Card(
                color: context.cardColor,
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
                            top: 20.0, bottom: 10.0, left: 40.0, right: 40.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(translation(context).lbl_delete_chat,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 10.sp,
                                        color: svGetBodyColor(),
                                        fontWeight: FontWeight.w600)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 10.sp, color: svGetBodyColor()),
                            children: <TextSpan>[
                              TextSpan(
                                  text: translation(context).msg_confirm_delete_chat),
                              TextSpan(
                                  text: title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)),
                            ],
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              // margin: const EdgeInsets.all(20),
                              width: 30.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: MaterialButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true)
                                      .pop('dialog');
                                },
                                child: Center(
                                  child: Text(
                                    translation(context).lbl_cancel_caps,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                      fontSize: 12.sp,
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
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: MaterialButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                onPressed: callBack,
                                child: Center(
                                  child: Text(
                                    translation(context).lbl_delete_caps,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.red,
                                      fontSize: 12.sp,
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
