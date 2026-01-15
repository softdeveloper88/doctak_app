import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';

void showVerifyMessage(BuildContext context, onPress) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Icon
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.purple.shade400]),
                ),
                padding: const EdgeInsets.all(16.0),
                child: const Icon(Icons.verified_outlined, color: Colors.white, size: 48.0),
              ),
              const SizedBox(height: 16.0),

              // Title
              Text(
                translation(context).lbl_verify_your_account,
                style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8.0),

              // Content
              Text(
                translation(context).msg_verify_email_description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16.0, color: Colors.black54),
              ),
              const SizedBox(height: 24.0),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: onPress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    child: Text(translation(context).lbl_resend_link, style: const TextStyle(fontSize: 16.0)),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                      side: BorderSide(color: Colors.blue.shade600),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    child: Text(translation(context).lbl_close, style: const TextStyle(fontSize: 16.0)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
