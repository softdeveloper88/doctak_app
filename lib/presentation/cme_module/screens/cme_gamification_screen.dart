import 'package:doctak_app/data/models/cme/cme_gamification_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_gamification_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_gamification_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_gamification_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CmeGamificationScreen extends StatelessWidget {
  const CmeGamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeGamificationBloc()
        ..add(CmeLoadGamificationEvent())
        ..add(CmeLoadBadgesEvent())
        ..add(CmeLoadLeaderboardEvent()),
      child: const _GamificationView(),
    );
  }
}

class _GamificationView extends StatelessWidget {
  const _GamificationView();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: const Text('Achievements & Leaderboard',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
      ),
      body: BlocBuilder<CmeGamificationBloc, CmeGamificationState>(
        builder: (context, state) {
          if (state is CmeGamificationLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CmeGamificationErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: theme.textTertiary),
                  const SizedBox(height: 12),
                  Text(state.message, style: theme.bodySecondary),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context
                        .read<CmeGamificationBloc>()
                        .add(CmeLoadGamificationEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final bloc = context.read<CmeGamificationBloc>();
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                _buildOverviewCard(context, theme, bloc.gamificationData),
                TabBar(
                  labelColor: theme.primary,
                  unselectedLabelColor: theme.textTertiary,
                  indicatorColor: theme.primary,
                  tabs: const [
                    Tab(text: 'Badges'),
                    Tab(text: 'Leaderboard'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBadgesTab(context, theme, bloc.badges),
                      _buildLeaderboardTab(context, theme, bloc.leaderboard),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(
      BuildContext context, OneUITheme theme, CmeGamificationData? data) {
    if (data == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Level badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${data.level ?? 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.levelName ?? 'Level ${data.level ?? 1}',
                      style: theme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.totalPoints ?? 0} points',
                      style: theme.bodySecondary,
                    ),
                    const SizedBox(height: 8),
                    // Level progress
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: data.levelProgress,
                        backgroundColor: theme.divider,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.nextLevelPoints ?? 0} points to next level',
                      style: theme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _buildStatItem(theme, Icons.local_fire_department,
                  '${data.currentStreak ?? 0}', 'Streak', Colors.orange),
              _buildStatItem(theme, Icons.emoji_events,
                  '${data.longestStreak ?? 0}', 'Best', Colors.amber),
              _buildStatItem(theme, Icons.leaderboard,
                  '#${data.rank ?? '-'}', 'Rank', theme.primary),
              _buildStatItem(
                  theme,
                  Icons.people,
                  '${data.totalUsers ?? 0}',
                  'Users',
                  theme.textTertiary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      OneUITheme theme, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: theme.textPrimary)),
          Text(label, style: theme.caption),
        ],
      ),
    );
  }

  Widget _buildBadgesTab(
      BuildContext context, OneUITheme theme, List<CmeBadgeData> badges) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.military_tech_outlined,
                size: 64, color: theme.textTertiary),
            const SizedBox(height: 12),
            Text('No badges yet', style: theme.titleMedium),
            const SizedBox(height: 4),
            Text('Complete CME activities to earn badges',
                style: theme.bodySecondary),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(context, theme, badge);
      },
    );
  }

  Widget _buildBadgeCard(
      BuildContext context, OneUITheme theme, CmeBadgeData badge) {
    final isEarned = badge.isEarned ?? false;
    final tierColor = _getTierColor(badge.tier);

    return GestureDetector(
      onTap: () => _showBadgeDetail(context, theme, badge),
      child: Container(
        decoration: theme.cardDecoration,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned
                    ? tierColor.withOpacity(0.15)
                    : theme.scaffoldBackground,
                border: Border.all(
                  color: isEarned ? tierColor : theme.divider,
                  width: 2,
                ),
              ),
              child: Icon(
                _getBadgeIcon(badge.category),
                color: isEarned ? tierColor : theme.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name ?? '',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isEarned ? theme.textPrimary : theme.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (!isEarned && (badge.progress ?? 0) > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (badge.progress ?? 0) / 100,
                  backgroundColor: theme.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                  minHeight: 3,
                ),
              ),
            if (isEarned)
              Text(
                badge.tier?.toUpperCase() ?? '',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: tierColor,
                  letterSpacing: 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(
      BuildContext context, OneUITheme theme, CmeBadgeData badge) {
    final isEarned = badge.isEarned ?? false;
    final tierColor = _getTierColor(badge.tier);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned
                    ? tierColor.withOpacity(0.15)
                    : theme.scaffoldBackground,
                border: Border.all(color: tierColor, width: 3),
              ),
              child: Icon(
                _getBadgeIcon(badge.category),
                color: isEarned ? tierColor : theme.textTertiary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(badge.name ?? '', style: theme.titleLarge),
            if (badge.tier != null) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge.tier!.toUpperCase(),
                  style: TextStyle(
                    color: tierColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              badge.description ?? '',
              style: theme.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (isEarned)
              Text(
                '+${badge.pointsAwarded ?? 0} points earned',
                style: TextStyle(
                  color: theme.success,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              )
            else ...[
              Text('Progress: ${badge.progress ?? 0}%',
                  style: theme.bodySecondary),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (badge.progress ?? 0) / 100,
                  backgroundColor: theme.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                  minHeight: 8,
                ),
              ),
              if (badge.requirement != null) ...[
                const SizedBox(height: 8),
                Text(badge.requirement!, style: theme.caption),
              ],
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(BuildContext context, OneUITheme theme,
      List<CmeLeaderboardEntry> leaderboard) {
    if (leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 64, color: theme.textTertiary),
            const SizedBox(height: 12),
            Text('Leaderboard is empty', style: theme.titleMedium),
            const SizedBox(height: 4),
            Text('Be the first to earn points!', style: theme.bodySecondary),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final entry = leaderboard[index];
        return _buildLeaderboardItem(theme, entry, index);
      },
    );
  }

  Widget _buildLeaderboardItem(
      OneUITheme theme, CmeLeaderboardEntry entry, int index) {
    final isCurrentUser = entry.isCurrentUser ?? false;
    final isTopThree = index < 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: isCurrentUser
          ? BoxDecoration(
              color: theme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary.withOpacity(0.3)),
            )
          : theme.cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: isTopThree
                ? Icon(
                    Icons.emoji_events,
                    color: index == 0
                        ? Colors.amber
                        : index == 1
                            ? Colors.grey.shade400
                            : Colors.brown.shade300,
                    size: 24,
                  )
                : Text(
                    '#${entry.rank ?? index + 1}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.primary.withOpacity(0.1),
            backgroundImage: entry.userAvatar != null
                ? NetworkImage(entry.userAvatar!)
                : null,
            child: entry.userAvatar == null
                ? Text(
                    (entry.userName ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName ?? 'Unknown',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight:
                        isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                    color: theme.textPrimary,
                  ),
                ),
                if (entry.specialty != null)
                  Text(entry.specialty!, style: theme.caption),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalPoints ?? 0}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.primary,
                ),
              ),
              Text('pts', style: theme.caption),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey.shade400;
      case 'platinum':
        return const Color(0xFF7B68EE);
      case 'bronze':
      default:
        return Colors.brown.shade300;
    }
  }

  IconData _getBadgeIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'completion':
        return Icons.check_circle;
      case 'streak':
        return Icons.local_fire_department;
      case 'quiz':
        return Icons.quiz;
      case 'social':
        return Icons.people;
      case 'specialization':
        return Icons.workspace_premium;
      case 'milestone':
        return Icons.flag;
      default:
        return Icons.military_tech;
    }
  }
}
