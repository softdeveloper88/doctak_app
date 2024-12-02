import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../presentation/home_screen/utils/SVCommon.dart';

void showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing while loading
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated Loading Icon
              SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4.0,
                  valueColor: AlwaysStoppedAnimation<Color>(svGetBodyColor()),
                ),
              ),
              const SizedBox(height: 20.0),

              // Title
              const Text(
                'Sending Verification Link',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10.0),

              // Subtitle/Message
              const Text(
                'Please wait while we send a verification link to your email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
