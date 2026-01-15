import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../main.dart';

class ChatDeleteDialog extends StatelessWidget {
  final VoidCallback callback;
  final String title;

  const ChatDeleteDialog({super.key, required this.title, required this.callback});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: confirmationAlertDialog(context, title, callback),
    );
  }
}

Center confirmationAlertDialog(BuildContext context, String title, VoidCallback callBack) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80.w,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: appStore.isDarkMode ? Colors.blueGrey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 1),
            boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.08), blurRadius: 12, spreadRadius: 0, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 24, bottom: 16),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.red[600], size: 28),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  translation(context).lbl_delete_chat,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: appStore.isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: appStore.isDarkMode ? Colors.white70 : Colors.black.withValues(alpha: 0.7), height: 1.5),
                    children: <TextSpan>[
                      TextSpan(text: translation(context).msg_confirm_delete_chat),
                      TextSpan(
                        text: title,
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: appStore.isDarkMode ? Colors.blueGrey[900] : Colors.grey[50],
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                ),
                child: Row(
                  spacing: 12,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: appStore.isDarkMode ? Colors.blueGrey[700] : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                        ),
                        child: MaterialButton(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop('dialog');
                          },
                          child: Text(
                            translation(context).lbl_cancel_caps,
                            style: TextStyle(fontWeight: FontWeight.w600, color: appStore.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14, fontFamily: 'Poppins'),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.red[500]!, Colors.red[700]!]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), offset: const Offset(0, 4), blurRadius: 8, spreadRadius: 0)],
                        ),
                        child: MaterialButton(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          onPressed: callBack,
                          child: Text(
                            translation(context).lbl_delete_caps,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14, fontFamily: 'Poppins'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
