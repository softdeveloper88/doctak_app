import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/complete_profile/complete_profile_screen.dart';
import 'package:doctak_app/widgets/email_verification_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IncompleteProfileCard extends StatelessWidget {
  IncompleteProfileCard(this.isEmailVerified, this.isInCompleteProfile, {super.key});
  bool isEmailVerified;
  bool isInCompleteProfile;
  Future<void> sendVerificationLink(String email, BuildContext context) {
    return requestEmailVerificationLink(context: context, email: email);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [
        // Email Verification Card
        if (isEmailVerified) _buildEmailVerificationCard(context),
        // Complete Profile Card
        if (isInCompleteProfile) _buildCompleteProfileCard(context),
      ],
    );
  }

  Widget _buildEmailVerificationCard(context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                sendVerificationLink(AppData.email, context);
              },
              child: Text(
                translation(context).lbl_verify_email,
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              translation(context).msg_profile_incomplete,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              translation(context).msg_complete_following,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                AppNavigator.push(context, const CompleteProfileScreen());
              },
              child: Text(
                translation(context).lbl_complete_profile,
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }
}
