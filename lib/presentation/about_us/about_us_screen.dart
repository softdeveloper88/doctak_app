import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_about_us,
        titleIcon: Icons.info_outline_rounded,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primary.withOpacity(0.08),
                    theme.secondary.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primary.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/header.svg',
                    height: 80,
                    colorFilter: theme.isDark
                        ? ColorFilter.mode(
                            theme.primary.withOpacity(0.8),
                            BlendMode.srcIn,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/logo/logo.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    translation(context).lbl_better_health_solutions,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    translation(context).msg_health_mission,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: theme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Collapsible Sections
            _buildCollapsibleSection(
              context: context,
              theme: theme,
              title: translation(context).lbl_our_mission,
              content: translation(context).html_our_mission,
              svg: 'assets/images/our_mission.svg',
              icon: Icons.flag_rounded,
            ),
            _buildCollapsibleSection(
              context: context,
              theme: theme,
              title: translation(context).lbl_who_we_are,
              content: translation(context).html_who_we_are,
              svg: 'assets/images/who_we_are.svg',
              icon: Icons.people_alt_rounded,
            ),
            _buildCollapsibleSection(
              context: context,
              theme: theme,
              title: translation(context).lbl_what_we_offer,
              content: translation(context).html_what_we_offer,
              svg: 'assets/images/offer.svg',
              icon: Icons.card_giftcard_rounded,
            ),
            _buildCollapsibleSection(
              context: context,
              theme: theme,
              title: translation(context).lbl_our_vision,
              content: translation(context).html_our_vision,
              svg: 'assets/images/our_vision.svg',
              icon: Icons.visibility_rounded,
            ),
            _buildCollapsibleSection(
              context: context,
              theme: theme,
              title: translation(context).lbl_case_discussion_title,
              content: translation(context).html_case_discussion,
              image: 'assets/images/intestine.png',
              icon: Icons.medical_services_rounded,
            ),
            _buildCollapsibleSection(
              context: context,
              theme: theme,
              title: translation(context).lbl_our_values,
              content: translation(context).html_our_values,
              svg: 'assets/images/our_value.svg',
              icon: Icons.diamond_rounded,
            ),
            _buildCollapsibleSection(
              context: context,
              theme: theme,
              title: translation(context).lbl_ai_diagnostic,
              content: translation(context).html_ai_diagnostic,
              image: 'assets/images/ai.png',
              icon: Icons.psychology_rounded,
            ),
            _buildCollapsibleSection(
              context: context,
              theme: theme,
              title: translation(context).lbl_join_us,
              content: translation(context).html_join_us,
              svg: 'assets/images/join.svg',
              icon: Icons.group_add_rounded,
              showContactInfo: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required BuildContext context,
    required OneUITheme theme,
    required String title,
    required String content,
    required IconData icon,
    String? svg,
    String? image,
    bool showContactInfo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.isDark ? theme.surfaceVariant : Colors.transparent,
          ),
          boxShadow: theme.isDark ? [] : theme.cardShadow,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: theme.primary.withOpacity(0.1),
            highlightColor: theme.primary.withOpacity(0.05),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primary, size: 22),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                fontFamily: 'Poppins',
                color: theme.textPrimary,
              ),
            ),
            iconColor: theme.primary,
            collapsedIconColor: theme.textSecondary,
            children: [
              Divider(
                height: 1,
                color: theme.divider,
                indent: 16,
                endIndent: 16,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Image/SVG
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: svg != null
                          ? SvgPicture.asset(
                              svg,
                              height: 180,
                              colorFilter: theme.isDark
                                  ? ColorFilter.mode(
                                      theme.primary.withOpacity(0.7),
                                      BlendMode.srcIn,
                                    )
                                  : null,
                            )
                          : Image.asset(image ?? '', height: 180),
                    ),
                    const SizedBox(height: 16),

                    // HTML Content
                    HtmlWidget(
                      content,
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color: theme.textSecondary,
                        height: 1.6,
                      ),
                    ),

                    // Contact Info
                    if (showContactInfo)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              translation(context).lbl_contact_follow_us,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: theme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  context: context,
                                  theme: theme,
                                  icon: 'assets/icon/face_icon.png',
                                  onTap: () => PostUtils.launchURL(
                                    context,
                                    'https://www.facebook.com/profile.php?id=100090277690568&mibextid=ZbWKwL',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildSocialButton(
                                  context: context,
                                  theme: theme,
                                  icon: 'assets/icon/linkedin_icon.png',
                                  onTap: () => PostUtils.launchURL(
                                    context,
                                    'https://www.linkedin.com/company/doctak-net/',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildSocialButton(
                                  context: context,
                                  theme: theme,
                                  icon: 'assets/icon/whats_icon.png',
                                  onTap: () => PostUtils.launchURL(
                                    context,
                                    'https://wa.me/971504957572',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildSocialButton(
                                  context: context,
                                  theme: theme,
                                  icon: 'assets/icon/email.png',
                                  onTap: () => _sendEmail('Info@doctak.net'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required OneUITheme theme,
    required String icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border),
            boxShadow: theme.isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Image.asset(icon, height: 28, width: 28),
        ),
      ),
    );
  }

  void _sendEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': ''},
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}
