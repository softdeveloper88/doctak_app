import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/common_navigator.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/complete_profile/complete_profile_screen.dart';
import 'package:doctak_app/widgets/show_loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:doctak_app/l10n/app_localizations.dart';

class IncompleteProfileCard extends StatelessWidget {
   IncompleteProfileCard(this.isEmailVerified,this.isInCompleteProfile,{Key? key}) : super(key: key);
  bool isEmailVerified;
   bool isInCompleteProfile;
   Future<void> sendVerificationLink(String email, BuildContext context) async {
     showLoadingDialog(context);
     // Show the loading dialog
     // showDialog(
     //   context: context,
     //   barrierDismissible: false, // Disallow dismissing while loading
     //   builder: (BuildContext context) {
     //     return SimpleDialog(
     //       title: const Text('Sending Verification Link'),
     //       children: [
     //         Center(
     //           child: CircularProgressIndicator(
     //             color: svGetBodyColor(),
     //           ),
     //         ),
     //       ],
     //     );
     //   },
     // );
     try {
       final response = await http.post(
         Uri.parse('${AppData.remoteUrl}/send-verification-link'),
         body: {'email': email},
       );

       // Close the loading dialog
       Navigator.of(context).pop();

       if (response.statusCode == 200) {
         // Successful API call, handle the response if needed
         // Show success Snackbar
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(translation(context).msg_verification_link_sent_success),
             duration: const Duration(seconds: 2),
           ),
         );
       } else if (response.statusCode == 422) {
         // Validation error or user email not found
         // Show error Snackbar
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(translation(context).msg_validation_error),
             duration: const Duration(seconds: 2),
           ),
         );
       } else if (response.statusCode == 404) {
         // User already verified
         // Show info Snackbar
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(translation(context).msg_user_already_verified),
             duration: const Duration(seconds: 2),
           ),
         );
       } else {
         // Something went wrong
         // Show error Snackbar
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(translation(context).msg_something_went_wrong),
             duration: const Duration(seconds: 2),
           ),
         );
       }
     } catch (e) {
       // Handle network errors or other exceptions
       // Close the loading dialog
       Navigator.of(context).pop();

       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(translation(context).msg_something_went_wrong),
           duration: const Duration(seconds: 2),
         ),
       );
     }
   }

   @override
  Widget build(BuildContext context) {
    return  Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          // Email Verification Card
         if(isEmailVerified)_buildEmailVerificationCard(context),
          // Complete Profile Card
        if(isInCompleteProfile)_buildCompleteProfileCard(context),
        ],
    );
  }
  Widget _buildEmailVerificationCard(context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/ic_mail.svg', // Replace with your SVG path
              height: 80,
            ),
            const SizedBox(height: 16),
            Text(
              translation(context).msg_verify_email_continue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                sendVerificationLink(AppData.email,context);
              },
              child: Text(
                translation(context).lbl_verify_email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteProfileCard(context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              translation(context).msg_profile_incomplete,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              translation(context).msg_complete_following,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconWithText('assets/images/ic_country.svg', translation(context).lbl_set_country),
                _buildIconWithText('assets/images/ic_state.svg', translation(context).lbl_set_state),
                _buildIconWithText('assets/images/ic_specialty.svg', translation(context).lbl_set_specialty),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {

                launchScreen(context, const CompleteProfileScreen(),);

              },
              child: Text(
                translation(context).lbl_complete_profile,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithText(String iconPath, String label) {
    return Column(
      children: [
        SvgPicture.asset(
          iconPath, // Replace with your SVG path
          height: 40,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
