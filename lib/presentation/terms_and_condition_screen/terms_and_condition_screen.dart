import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class TermsAndConditionScreen extends StatefulWidget {
   TermsAndConditionScreen({super.key});
  @override
  State<TermsAndConditionScreen> createState() =>
      _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).lbl_terms_and_conditions),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  ''''
                Terms of Service for DocTak.net

Last Updated: July 2024

Welcome to DocTak.net(“Terms”) govern your use of the App/web, which is developed and provided by “DocTak App developers”. By accessing or using the App, you agree to be bound by these Terms. If you do not agree to these Terms, do not use the App.

 1. Acceptance of Terms
By creating an account or otherwise using the App/web, you confirm that you have read, understood, and agree to these Terms and our Privacy Policy.

 2. Eligibility
The App/web is intended for use by licensed medical professionals, including doctors and other healthcare providers. By using the App/web, you represent and warrant that you are a licensed medical professional and have the right, authority, and capacity to enter into these Terms.

 3. User-Generated Content (UGC)
a. *Content Creation*: The App/web allows users to create, upload, and share content including profiles, posts, comments, case discussions, and more (“User-Generated Content” or “UGC”). 

b. *Responsibility for UGC*: You are solely responsible for the UGC you create and share. You agree not to post content that is defamatory, harmful, illegal, or otherwise objectionable.

c. *License to UGC*: By posting UGC, you grant us a non-exclusive, worldwide, royalty-free, perpetual license to use, modify, reproduce, distribute, and display such content in connection with the operation of the App/web.

d. *Prohibited Content and Behaviors*: You agree not to post content that:
   - Violates any applicable laws or regulations
   - Contains hate speech, harassment, or threats
   - Is obscene, pornographic, or offensive
   - Infringes on intellectual property rights
   - Contains false or misleading information
   - Promotes illegal activities

4. Terms of Use
a. *Account Security*: You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.

b. *Prohibited Activities*: You agree not to:
   - Use the App/web for any unlawful purpose
   - Attempt to gain unauthorized access to the App/web or other accounts
   - Engage in any activity that could harm or disrupt the App/web or its users

c. *Reporting Violations*: If you encounter any content or activity that violates these Terms, please report it to us using the reporting mechanisms provided within the App/web or by contacting info@DocTak.net.

 5. Jobs, Conferences, CME, and MOH Updates
a. *Job Listings*: The App/web may provide information on job opportunities for medical professionals. We are not responsible for the accuracy or legitimacy of job listings.

b. *Conferences and Events*: The App may feature information about medical conferences and events. We do not endorse or guarantee the quality or availability of these events.

c. *CME and MOH Updates*: The App/web may provide updates on Continuing Medical Education (CME) opportunities and Ministry of Health (MOH) updates. While we strive to provide accurate information, we do not guarantee the completeness or reliability of such updates.

 6. Case Discussions
The App/web allows for the discussion of medical cases among users. You agree to respect patient confidentiality and privacy at all times and to follow all applicable laws and regulations regarding patient information.

7. Termination
We reserve the right to suspend or terminate your account and access to the App/web if you violate these Terms or engage in conduct that we determine to be inappropriate or harmful.

8. Disclaimer of Warranties
The App/web is provided on an “as is” and “as available” basis. We do not warrant that the App/web will be uninterrupted, error-free, or free of harmful components. We disclaim all warranties, express or implied, including but not limited to the warranties of merchantability and fitness for a particular purpose.

9. Limitation of Liability
To the fullest extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses resulting from your use of the App/web.

 10. Indemnification
You agree to indemnify and hold us harmless from any claims, damages, liabilities, and expenses (including reasonable attorneys’ fees) arising out of or related to your use of the App/web, your violation of these Terms, or your violation of any rights of another.


 11. Changes to Terms
We may modify these Terms at any time. We may notify you of any changes by posting the new Terms within the App./web Your continued use of the App after the changes become effective constitutes your acceptance of the revised Terms.

12. Governing Law
These Terms shall be governed by and construed in accordance with the laws of [Your Country/State], without regard to its conflict of law principles.

13. Contact Us
If you have any questions about these Terms, please contact us at info@DocTak.net.

By using the App, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service''',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                Checkbox(
                  value: _isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value!;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    translation(context).lbl_agree_terms_conditions,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecked
                    ? ()  async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setBool('acceptTerms', true);
                        Navigator.pop(context);
                        // widget.accept!();
                        // LoginScreen().launch(context, isNewTask: true);
                      }
                    : null,
                child: Text(translation(context).lbl_accept),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
