import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';
import 'package:doctak_app/localization/app_localization.dart';

class CustomAlertDialog extends StatelessWidget {
  final VoidCallback callback;
  final VoidCallback? callbackNegative;
  final String title;
  final String? noButtonText;
  final String? yesButtonText;
  final String? mainTitle;

   const CustomAlertDialog(
      {Key? key, required this.title, required this.callback,this.callbackNegative,this.yesButtonText,this.noButtonText,this.mainTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: confirmationCustomAlertDialog(
        context,
        title,
        callback,
        yesButtonText ?? translation(context).lbl_delete,
        mainTitle ?? translation(context).lbl_delete_with_question,
        callbackNegative,
        noButtonText,
      ),
    );
  }
}

confirmationCustomAlertDialog(
    BuildContext context, String title, VoidCallback callBack,String yesButtonText,String mainTitle,VoidCallback? callbackNegative,noButtonText) {
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
                                child: Text(mainTitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        color: svGetBodyColor(),
                                        fontWeight: FontWeight.w500)),
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
                                fontSize: 13.sp, color: textPrimaryColor),
                            children: <TextSpan>[
                              // TextSpan(text: title),
                              TextSpan(
                                  text: title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
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
                              width: 30.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: MaterialButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true).pop('dialog');
                                  callbackNegative?.call();
                                },
                                child: Center(
                                  child: Text(
                                    noButtonText??translation(context).lbl_cancel,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                      fontSize: 14.sp,
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
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: MaterialButton(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true).pop('dialog');
                                  callBack();
                                },
                                child: Center(
                                  child: Text(
                                    yesButtonText,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.red,
                                      fontSize: 14.sp,
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
