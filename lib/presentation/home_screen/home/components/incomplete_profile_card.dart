import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/complete_profile/complete_profile_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/email_verification_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// OneUI 8.5 styled incomplete profile and email verification cards
/// Compact, modern design with proper theming support
class IncompleteProfileCard extends StatelessWidget {
  const IncompleteProfileCard(this.isEmailVerified, this.isInCompleteProfile, {super.key});

  final bool isEmailVerified;
  final bool isInCompleteProfile;

  Future<void> sendVerificationLink(String email, BuildContext context) {
    return requestEmailVerificationLink(context: context, email: email);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (isEmailVerified) _buildEmailVerificationCard(context), if (isInCompleteProfile) _buildCompleteProfileCard(context)]);
  }

  Widget _buildEmailVerificationCard(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(top: 8, left: 8, right: 8, bottom: isInCompleteProfile ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 0.5),
        boxShadow: theme.cardShadow,
      ),
      child: Row(
        children: [
          // Email icon with gradient background and shadow
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  theme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Center(child: SvgPicture.asset('assets/images/ic_mail.svg', height: 24, width: 24, colorFilter: ColorFilter.mode(theme.primary, BlendMode.srcIn))),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Text(
              translation(context).msg_verify_email_continue,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Poppins', color: theme.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          // Verify button
          Material(
            color: theme.primary,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => sendVerificationLink(AppData.email, context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  translation(context).lbl_verify_email,
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteProfileCard(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(top: isEmailVerified ? 8 : 8, left: 8, right: 8, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border, width: 0.5),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and button
          Row(
            children: [
              // Profile icon with shadow
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.warning.withValues(alpha: isDark ? 0.25 : 0.15),
                      theme.warning.withValues(alpha: isDark ? 0.15 : 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: theme.warning.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Icon(Icons.person_outline_rounded, color: theme.warning, size: 22),
              ),
              const SizedBox(width: 10),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translation(context).msg_profile_incomplete,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      translation(context).msg_complete_following,
                      style: TextStyle(fontSize: 11, fontFamily: 'Poppins', color: theme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Complete button
              Material(
                color: theme.primary,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => AppNavigator.push(context, const CompleteProfileScreen()),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Text(
                      translation(context).lbl_complete_profile,
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Icons row - compact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconChip(context, 'assets/images/ic_country.svg', translation(context).lbl_set_country, theme),
              _buildIconChip(context, 'assets/images/ic_state.svg', translation(context).lbl_set_state, theme),
              _buildIconChip(context, 'assets/images/ic_specialty.svg', translation(context).lbl_set_specialty, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconChip(BuildContext context, String iconPath, String label, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: theme.surfaceVariant.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(iconPath, height: 16, width: 16, colorFilter: ColorFilter.mode(theme.textSecondary, BlendMode.srcIn)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, fontFamily: 'Poppins', color: theme.textSecondary),
          ),
        ],
      ),
    );
  }
}
