import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home_screen/utils/SVCommon.dart';

class AboutUsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: DoctakAppBar(
        title: translation(context).lbl_about_us,
        titleIcon: Icons.info_outline_rounded,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/header.svg', // Replace with your image
                    height: 100,
                  ),
                  Image.asset(
                    'assets/logo/logo.png',
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 120,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    translation(context).lbl_better_health_solutions,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translation(context).msg_health_mission,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // Collapsible Sections
            _buildCollapsibleSection(
              context: context,
              title: translation(context).lbl_our_mission,
              content: translation(context).html_our_mission,
              svg: 'assets/images/our_mission.svg',
            ),
            _buildCollapsibleSection(
              context: context,
              title: translation(context).lbl_who_we_are,
              content: translation(context).html_who_we_are,
              svg: 'assets/images/who_we_are.svg',
            ),
            _buildCollapsibleSection(
              context: context,
              title: translation(context).lbl_what_we_offer,
              content: translation(context).html_what_we_offer,
              svg: 'assets/images/offer.svg',
            ),
            _buildCollapsibleSection(
              context: context,
              title: translation(context).lbl_our_vision,
              content: translation(context).html_our_vision,
              svg: 'assets/images/our_vision.svg',
            ),
            _buildCollapsibleSection(
              context: context,
              title: translation(context).lbl_case_discussion_title,
              content: translation(context).html_case_discussion,
              image: 'assets/images/intestine.png',
            ),
            _buildCollapsibleSection(
              context: context,
              title: translation(context).lbl_our_values,
              content: translation(context).html_our_values,
              svg: 'assets/images/our_value.svg',
            ),
            _buildCollapsibleSection(
              context: context,
              title: translation(context).lbl_ai_diagnostic,
              content: translation(context).html_ai_diagnostic,
              image: 'assets/images/ai.png',
            ),
            _buildCollapsibleSection(
              context: context,
              title: translation(context).lbl_join_us,
              content: translation(context).html_join_us,
              svg: 'assets/images/join.svg',
              showContactInfo: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required BuildContext context,
    required String title,
    required String content,
    String? svg,
    String? image,
    bool showContactInfo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        shadowColor: Colors.black12,
        child: ExpansionTile(
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  svg != null
                      ? SvgPicture.asset(
                          svg,
                          height: 200,
                        )
                      : Image.asset(
                          image ?? '',
                          height: 200,
                        ),
                  const SizedBox(height: 10),
                  HtmlWidget(
                    textStyle: const TextStyle(
                      fontSize: 16,
                    ),
                    content,
                  ),
                  if (showContactInfo)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            translation(context).lbl_contact_follow_us,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                  onTap: () {
                                    PostUtils.launchURL(context,
                                        'https://www.facebook.com/profile.php?id=100090277690568&mibextid=ZbWKwL');
                                  },
                                  child: Image.asset('assets/icon/face_icon.png',
                                      height: 35, width: 35)),
                              const SizedBox(width: 10),
                              GestureDetector(
                                  onTap: () {
                                    PostUtils.launchURL(context,
                                        'https://www.linkedin.com/company/doctak-net/');
                                  },
                                  child: Image.asset('assets/icon/linkedin_icon.png',
                                      height: 35, width: 35)),
                              const SizedBox(width: 10),
                              GestureDetector(
                                  onTap: () {
                                    PostUtils.launchURL(
                                        context, 'https://wa.me/971504957572');
                                  },
                                  child: Image.asset('assets/icon/whats_icon.png',
                                      height: 35, width: 35)),
                              const SizedBox(width: 10),
                              GestureDetector(
                                  onTap: () {
                                    _sendEmail('Info@doctak.net');
                                  },
                                  child: Image.asset(
                                    'assets/icon/email.png',
                                    height: 35,
                                    width: 35,
                                  )),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          )
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendEmail(String email) async {
    final Uri emailLaunchUri =
        Uri(scheme: 'mailto', path: email, queryParameters: {'subject': ''});
    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not send email to $email';
    }
  }
}