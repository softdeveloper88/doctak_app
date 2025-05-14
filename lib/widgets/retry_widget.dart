// retry_widget.dart
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:doctak_app/localization/app_localization.dart';

class RetryWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const RetryWidget({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            MaterialButton(
              onPressed: onRetry,
              color: appButtonBackgroundColorGlobal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 36,
                vertical: 12,
              ),
              elevation: 5,
              child: Text(
                translation(context).lbl_retry,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // GestureDetector(
            //   onTap: () {
            //     // launchUrl(Url'https://example.com/help'); // Navigate to a help page
            //   },
            //   child: Text(
            //     'Need Help?',
            //     style: TextStyle(
            //       color: Colors.blueAccent,
            //       fontSize: 14,
            //       decoration: TextDecoration.underline,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
