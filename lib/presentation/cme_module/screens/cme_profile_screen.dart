import 'package:doctak_app/data/models/cme/cme_profile_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_profile_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_profile_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_profile_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class CmeProfileScreen extends StatelessWidget {
  const CmeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeProfileBloc()
        ..add(CmeLoadProfileEvent())
        ..add(CmeLoadTranscriptEvent())
        ..add(CmeLoadAchievementsEvent()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: const Text('CME Profile',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
      ),
      body: BlocBuilder<CmeProfileBloc, CmeProfileState>(
        builder: (context, state) {
          final bloc = context.read<CmeProfileBloc>();

          if (state is CmeProfileLoadingState && bloc.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Profile header
              if (bloc.profile != null) _buildProfileHeader(theme, bloc.profile!),
              // Tabs
              Container(
                color: theme.cardBackground,
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.primary,
                  unselectedLabelColor: theme.textTertiary,
                  indicatorColor: theme.primary,
                  labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Credits'),
                    Tab(text: 'Transcript'),
                    Tab(text: 'Achievements'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCreditsTab(theme, bloc),
                    _buildTranscriptTab(theme, bloc),
                    _buildAchievementsTab(theme, bloc),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(OneUITheme theme, CmeProfileData profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.cardBackground,
      child: Column(
        children: [
          // Cycle progress ring
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: profile.cycleProgress,
                    strokeWidth: 8,
                    backgroundColor: theme.divider,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(theme.primary),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(profile.cycleProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.primary,
                      ),
                    ),
                    Text('Cycle', style: theme.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Credit stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _creditStat(theme, '${profile.totalCredits ?? 0}',
                  'Total', theme.primary),
              _creditStat(theme, '${profile.requiredCredits ?? 0}',
                  'Required', const Color(0xFFFF9500)),
              _creditStat(theme, '${((profile.requiredCredits ?? 0) - (profile.creditsThisCycle ?? 0)).clamp(0, 99999)}',
                  'Remaining', const Color(0xFFFF3B30)),
              _creditStat(theme, '${profile.creditsThisCycle ?? 0}',
                  'This Cycle', const Color(0xFF34C759)),
            ],
          ),
          if (profile.cycleEndDate != null) ...[
            const SizedBox(height: 10),
            Text(
              'Cycle ends: ${_formatDate(profile.cycleEndDate!)}',
              style: theme.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _creditStat(
      OneUITheme theme, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: theme.caption),
      ],
    );
  }

  Widget _buildCreditsTab(OneUITheme theme, CmeProfileBloc bloc) {
    final credits = bloc.profile?.creditHistory ?? [];
    if (credits.isEmpty) {
      return _buildEmpty(
          theme, 'No credits yet', 'Earn credits by attending events');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: credits.length,
      itemBuilder: (_, index) {
        final credit = credits[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: theme.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${credit.credits ?? 0}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credit.eventTitle ?? 'CME Activity',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (credit.creditType != null)
                          Text(credit.creditType!, style: theme.caption),
                        if (credit.earnedDate != null) ...[
                          const SizedBox(width: 8),
                          Text(_formatDate(credit.earnedDate!),
                              style: theme.caption),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (credit.status != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: credit.isApproved
                        ? const Color(0xFF34C759).withValues(alpha: 0.1)
                        : const Color(0xFFFF9500).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    credit.displayStatus,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: credit.isApproved
                          ? const Color(0xFF34C759)
                          : const Color(0xFFFF9500),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTranscriptTab(OneUITheme theme, CmeProfileBloc bloc) {
    final transcript = bloc.transcript;

    if (transcript == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final entries = transcript.entries ?? [];

    return Column(
      children: [
        // Download button
        if (transcript.downloadUrl != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.tryParse(transcript.downloadUrl!);
                if (url != null && await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download Transcript',
                  style: TextStyle(fontFamily: 'Poppins')),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        // Entries
        Expanded(
          child: entries.isEmpty
              ? _buildEmpty(theme, 'No transcript entries',
                  'Complete events to build your transcript')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (_, index) {
                    final entry = entries[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: theme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.eventTitle ?? '',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (entry.creditType != null) ...[
                                Text(entry.creditType!, style: theme.caption),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                  '${entry.credits ?? 0} credits',
                                  style: theme.caption),
                              const Spacer(),
                              if (entry.completedDate != null)
                                Text(
                                  _formatDate(entry.completedDate!),
                                  style: theme.caption,
                                ),
                            ],
                          ),
                          if (entry.accreditationBody != null) ...[
                            const SizedBox(height: 4),
                            Text(entry.accreditationBody!, style: theme.caption),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAchievementsTab(OneUITheme theme, CmeProfileBloc bloc) {
    final achievements = bloc.achievements;

    if (achievements.isEmpty) {
      return _buildEmpty(
          theme, 'No achievements yet', 'Complete activities to earn badges');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: achievements.length,
      itemBuilder: (_, index) {
        final badge = achievements[index];
        final earned = badge.earnedAt != null;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: earned
                ? theme.primary.withValues(alpha: 0.05)
                : theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: earned
                  ? theme.primary.withValues(alpha: 0.3)
                  : theme.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: earned
                      ? _badgeColor(badge.category)
                      : theme.divider,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _badgeIcon(badge.category),
                  size: 24,
                  color: earned ? Colors.white : theme.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.title ?? '',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: earned ? theme.textPrimary : theme.textTertiary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (!earned && badge.progress != null) ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (badge.progress! / 100).clamp(0.0, 1.0),
                    backgroundColor: theme.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primary.withValues(alpha: 0.5)),
                    minHeight: 3,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _badgeColor(String? type) {
    switch (type) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF0A84FF);
    }
  }

  IconData _badgeIcon(String? type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'quiz':
        return Icons.quiz;
      case 'streak':
        return Icons.local_fire_department;
      case 'milestone':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${d.month}/${d.day}/${d.year}';
    } catch (_) {
      return date;
    }
  }

  Widget _buildEmpty(OneUITheme theme, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 48, color: theme.textTertiary),
          const SizedBox(height: 12),
          Text(title, style: theme.bodySecondary),
          Text(subtitle, style: theme.caption),
        ],
      ),
    );
  }
}
