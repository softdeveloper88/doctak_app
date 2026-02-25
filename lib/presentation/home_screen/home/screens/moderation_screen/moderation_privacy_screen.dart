import 'package:doctak_app/data/apiClient/services/moderation_api_service.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/moderation_screen/blocked_users_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/moderation_screen/report_history_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Main Moderation & Privacy screen — hub for blocked users, reports, and privacy settings
class ModerationPrivacyScreen extends StatefulWidget {
  const ModerationPrivacyScreen({super.key});

  @override
  State<ModerationPrivacyScreen> createState() => _ModerationPrivacyScreenState();
}

class _ModerationPrivacyScreenState extends State<ModerationPrivacyScreen> {
  final ModerationApiService _moderationService = ModerationApiService();
  int _blockedCount = 0;
  int _reportCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);

    // Load blocked users count and report count in parallel
    final futures = await Future.wait([
      _moderationService.getBlockedUsers(),
      _moderationService.getMyReports(page: 1),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
        final blockedResult = futures[0];
        final reportResult = futures[1];

        if (blockedResult.success && blockedResult.data != null) {
          _blockedCount = (blockedResult.data as List).length;
        }
        if (reportResult.success && reportResult.data != null) {
          _reportCount = (reportResult.data as ReportHistoryResponse).total;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Moderation & Privacy',
        titleIcon: Icons.shield_outlined,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        color: theme.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Header info card
            _buildInfoCard(theme),
            const SizedBox(height: 20),

            // Section title
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'MANAGE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: theme.textSecondary,
                ),
              ),
            ),

            // Blocked Users tile
            _buildMenuTile(
              theme: theme,
              icon: Icons.block_rounded,
              iconColor: Colors.red,
              title: 'Blocked Users',
              subtitle: _isLoading
                  ? 'Loading...'
                  : '$_blockedCount user${_blockedCount == 1 ? '' : 's'} blocked',
              onTap: () async {
                HapticFeedback.lightImpact();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                );
                _loadCounts(); // Refresh counts after returning
              },
            ),
            const SizedBox(height: 10),

            // Report History tile
            _buildMenuTile(
              theme: theme,
              icon: Icons.flag_rounded,
              iconColor: Colors.orange,
              title: 'My Reports',
              subtitle: _isLoading
                  ? 'Loading...'
                  : '$_reportCount report${_reportCount == 1 ? '' : 's'} submitted',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportHistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // Section title
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'ABOUT MODERATION',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: theme.textSecondary,
                ),
              ),
            ),

            // Info tiles
            _buildInfoTile(
              theme: theme,
              icon: Icons.schedule_rounded,
              title: '24-Hour Response',
              description:
                  'Our moderation team reviews all reports within 24 hours. You\'ll see the status update in your report history.',
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
              theme: theme,
              icon: Icons.visibility_off_rounded,
              title: 'Blocked Users Can\'t See You',
              description:
                  'Blocked users cannot see your posts, send you messages, or call you. This works both ways.',
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
              theme: theme,
              icon: Icons.security_rounded,
              title: 'Your Safety Matters',
              description:
                  'If you encounter harmful or inappropriate content, please report it immediately. All reports are confidential.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(OneUITheme theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary,
            theme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Content Safety',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage who can interact with you and track your content reports.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required OneUITheme theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.isDark ? theme.surfaceVariant : Colors.transparent,
            ),
            boxShadow: theme.isDark ? [] : theme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required OneUITheme theme,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.isDark ? theme.surfaceVariant : Colors.transparent,
        ),
        boxShadow: theme.isDark ? [] : theme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: theme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: theme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
