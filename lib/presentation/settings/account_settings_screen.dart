import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/app_setting_screen/app_setting_screen.dart';
import 'package:doctak_app/presentation/settings/ai_data_usage_screen.dart';
import 'package:doctak_app/presentation/settings/delete_account_screen.dart';
import 'package:doctak_app/presentation/settings/devices_sessions_screen.dart';
import 'package:doctak_app/presentation/settings/notifications_settings_screen.dart';
import 'package:doctak_app/presentation/settings/security_account_screen.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Mobile account settings hub — mirrors website settings sections.
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final email = AppData.email.trim();
    final name = AppData.name.trim();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(
        title: 'Account Settings',
        titleIcon: Icons.manage_accounts_rounded,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          AppSurfaceCard(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.primary.withValues(alpha: 0.12),
                  backgroundImage: AppData.profilePicUrl.isNotEmpty
                      ? NetworkImage(AppData.profilePicUrl)
                      : null,
                  child: AppData.profilePicUrl.isEmpty
                      ? Icon(Icons.person_rounded, color: theme.primary, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Your account',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SectionLabel(theme: theme, label: 'Account'),
          _SettingsTile(
            theme: theme,
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF0F766E),
            title: 'Security',
            subtitle: 'Password and two-factor authentication',
            onTap: () => AppNavigator.push(context, const SecurityAccountScreen()),
          ),
          _SettingsTile(
            theme: theme,
            icon: Icons.devices_rounded,
            iconColor: const Color(0xFF1D4ED8),
            title: 'Devices & sessions',
            subtitle: 'Active logins on phones, tablets, and web',
            onTap: () => AppNavigator.push(context, const DevicesSessionsScreen()),
          ),
          _SettingsTile(
            theme: theme,
            icon: Icons.workspace_premium_rounded,
            iconColor: const Color(0xFFB45309),
            title: 'Subscription',
            subtitle: 'Plan, billing, and premium access',
            onTap: () => const SubscriptionScreen().launch(context),
          ),
          const SizedBox(height: 8),
          _SectionLabel(theme: theme, label: 'Preferences'),
          _SettingsTile(
            theme: theme,
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'Notifications',
            subtitle: 'Push permission and alert preferences',
            onTap: () => AppNavigator.push(context, const NotificationsSettingsScreen()),
          ),
          _SettingsTile(
            theme: theme,
            icon: Icons.auto_awesome_rounded,
            iconColor: const Color(0xFF0891B2),
            title: 'AI & data usage',
            subtitle: 'Daily and monthly AI quota by feature',
            onTap: () => AppNavigator.push(context, const AiDataUsageScreen()),
          ),
          _SettingsTile(
            theme: theme,
            icon: Icons.palette_rounded,
            iconColor: theme.primary,
            title: 'Appearance & language',
            subtitle: 'Theme, language, and app preferences',
            onTap: () => AppNavigator.push(context, const AppSettingScreen()),
          ),
          const SizedBox(height: 8),
          _SectionLabel(theme: theme, label: 'Danger zone'),
          _SettingsTile(
            theme: theme,
            icon: Icons.delete_outline_rounded,
            iconColor: Colors.red,
            title: 'Delete account',
            subtitle: 'Schedule permanent account removal',
            danger: true,
            onTap: () => AppNavigator.push(context, const DeleteAccountScreen()),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.theme, required this.label});

  final OneUITheme theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: theme.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final OneUITheme theme;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderColor: danger ? Colors.red.withValues(alpha: 0.25) : null,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: danger ? Colors.red.shade700 : theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    height: 1.35,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: theme.textSecondary),
        ],
      ),
    );
  }
}
