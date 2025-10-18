import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';

class TermsAndConditionScreen extends StatefulWidget {
  const TermsAndConditionScreen({super.key});

  @override
  State<TermsAndConditionScreen> createState() =>
      _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      body: Column(
        children: [
          // Custom App Bar with DoctakAppBar
          DoctakAppBar(
            title: translation(context).lbl_terms_and_conditions,
            titleIcon: Icons.description_outlined,
          ),

          // Content
          Expanded(
            child: Container(
              color: svGetScaffoldColor(),
              child: Column(
                children: [
                  // Terms Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withAlpha(13),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.blue.withAlpha(26),
                          width: 1,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Terms of Service',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue[800],
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Terms Content
                            Text(
                              '''Terms of Service for DocTak.net

Last Updated: July 2024

Welcome to DocTak.net("Terms") govern your use of the App/web, which is developed and provided by "DocTak App developers". By accessing or using the App, you agree to be bound by these Terms. If you do not agree to these Terms, do not use the App.

1. Acceptance of Terms
By creating an account or otherwise using the App/web, you confirm that you have read, understood, and agree to these Terms and our Privacy Policy.

2. Eligibility
The App/web is intended for use by licensed medical professionals, including doctors and other healthcare providers. By using the App/web, you represent and warrant that you are a licensed medical professional and have the right, authority, and capacity to enter into these Terms.

3. User-Generated Content (UGC)
a. Content Creation: The App/web allows users to create, upload, and share content including profiles, posts, comments, case discussions, and more ("User-Generated Content" or "UGC"). 

b. Responsibility for UGC: You are solely responsible for the UGC you create and share. You agree not to post content that is defamatory, harmful, illegal, or otherwise objectionable.

c. License to UGC: By posting UGC, you grant us a non-exclusive, worldwide, royalty-free, perpetual license to use, modify, reproduce, distribute, and display such content in connection with the operation of the App/web.

d. Prohibited Content and Behaviors: You agree not to post content that:
   - Violates any applicable laws or regulations
   - Contains hate speech, harassment, or threats
   - Is obscene, pornographic, or offensive
   - Infringes on intellectual property rights
   - Contains false or misleading information
   - Promotes illegal activities

4. Terms of Use
a. Account Security: You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.

b. Prohibited Activities: You agree not to:
   - Use the App/web for any unlawful purpose
   - Attempt to gain unauthorized access to the App/web or other accounts
   - Engage in any activity that could harm or disrupt the App/web or its users

c. Reporting Violations: If you encounter any content or activity that violates these Terms, please report it to us using the reporting mechanisms provided within the App/web or by contacting info@DocTak.net.

5. Jobs, Conferences, CME, and MOH Updates
a. Job Listings: The App/web may provide information on job opportunities for medical professionals. We are not responsible for the accuracy or legitimacy of job listings.

b. Conferences and Events: The App may feature information about medical conferences and events. We do not endorse or guarantee the quality or availability of these events.

c. CME and MOH Updates: The App/web may provide updates on Continuing Medical Education (CME) opportunities and Ministry of Health (MOH) updates. While we strive to provide accurate information, we do not guarantee the completeness or reliability of such updates.

6. Case Discussions
The App/web allows for the discussion of medical cases among users. You agree to respect patient confidentiality and privacy at all times and to follow all applicable laws and regulations regarding patient information.

7. Termination
We reserve the right to suspend or terminate your account and access to the App/web if you violate these Terms or engage in conduct that we determine to be inappropriate or harmful.

8. Disclaimer of Warranties
The App/web is provided on an "as is" and "as available" basis. We do not warrant that the App/web will be uninterrupted, error-free, or free of harmful components. We disclaim all warranties, express or implied, including but not limited to the warranties of merchantability and fitness for a particular purpose.

9. Limitation of Liability
To the fullest extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses resulting from your use of the App/web.

10. Indemnification
You agree to indemnify and hold us harmless from any claims, damages, liabilities, and expenses (including reasonable attorneys' fees) arising out of or related to your use of the App/web, your violation of these Terms, or your violation of any rights of another.

11. Changes to Terms
We may modify these Terms at any time. We may notify you of any changes by posting the new Terms within the App./web Your continued use of the App after the changes become effective constitutes your acceptance of the revised Terms.

12. Governing Law
These Terms shall be governed by and construed in accordance with the laws of [Your Country/State], without regard to its conflict of law principles.

13. Contact Us
If you have any questions about these Terms, please contact us at info@DocTak.net.

By using the App, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service''',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                fontFamily: 'Poppins',
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Agreement Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: svGetScaffoldColor(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(13),
                          offset: const Offset(0, -3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Checkbox Row
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isChecked
                                  ? Colors.blue.withAlpha(100)
                                  : Colors.grey.withAlpha(50),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: _isChecked
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Checkbox(
                                  value: _isChecked,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  activeColor: Colors.blue[600],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isChecked = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  translation(
                                    context,
                                  ).lbl_agree_terms_conditions,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                    color: _isChecked
                                        ? Colors.blue[800]
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Accept Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isChecked
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: ElevatedButton(
                            onPressed: _isChecked
                                ? () async {
                                    final prefs = SecureStorageService.instance;
                                    await prefs.initialize();
                                    await prefs.setBool('acceptTerms', true);
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isChecked
                                  ? Colors.blue[600]
                                  : Colors.grey[300],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isChecked
                                      ? Icons.check_circle_outline
                                      : Icons.radio_button_unchecked,
                                  size: 20,
                                  color: _isChecked
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  translation(context).lbl_accept,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: _isChecked
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
