import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import '../models/case_discussion_models.dart';

class DiscussionStatsBar extends StatelessWidget {
  final List<CaseDiscussionListItem> discussions;
  final CaseDiscussionFilters currentFilters;
  final bool isLoading;

  const DiscussionStatsBar({super.key, required this.discussions, required this.currentFilters, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: theme.cardBackground,
        child: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.primary))),
            const SizedBox(width: 8),
            Text(
              'Loading discussions...',
              style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: theme.textSecondary),
            ),
          ],
        ),
      );
    }

    final totalLikes = discussions.fold<int>(0, (sum, d) => sum + d.stats.likes);
    final totalComments = discussions.fold<int>(0, (sum, d) => sum + d.stats.commentsCount);
    final totalViews = discussions.fold<int>(0, (sum, d) => sum + d.stats.views);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(bottom: BorderSide(color: theme.divider, width: 1)),
      ),
      child: Column(
        children: [
          // Results count and filter info
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 16, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                '${discussions.length} discussions found',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.primary),
              ),
              if (_hasActiveFilters()) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'Filtered',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, fontFamily: 'Poppins', color: theme.primary),
                  ),
                ),
              ],
              const Spacer(),
              if (currentFilters.selectedSpecialty != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    currentFilters.selectedSpecialty!.name,
                    style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: theme.primary, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (currentFilters.selectedCountry != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currentFilters.selectedCountry!.flag, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 2),
                    Text(
                      currentFilters.selectedCountry!.name,
                      style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: theme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              if (discussions.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 16, color: theme.iconColor),
                  color: theme.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 16, color: theme.textPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Export Results',
                            style: TextStyle(color: theme.textPrimary, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 16, color: theme.textPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Share Filters',
                            style: TextStyle(color: theme.textPrimary, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'export':
                        _exportResults(context);
                        break;
                      case 'share':
                        _shareFilters(context);
                        break;
                    }
                  },
                ),
            ],
          ),

          // Stats summary
          if (discussions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatItem(icon: Icons.thumb_up_outlined, label: 'Total Likes', value: _formatNumber(totalLikes), color: theme.primary, theme: theme),
                const SizedBox(width: 16),
                _buildStatItem(icon: Icons.comment_outlined, label: 'Total Comments', value: _formatNumber(totalComments), color: theme.success, theme: theme),
                const SizedBox(width: 16),
                _buildStatItem(icon: Icons.visibility_outlined, label: 'Total Views', value: _formatNumber(totalViews), color: theme.warning, theme: theme),
                const Spacer(),
                if (_hasActiveFilters())
                  TextButton(
                    onPressed: () => _showFilterSummary(context, theme),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero),
                    child: Text(
                      'View Filters',
                      style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: theme.primary),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value, required Color color, required OneUITheme theme}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: theme.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  bool _hasActiveFilters() {
    return currentFilters.selectedSpecialty != null ||
        currentFilters.selectedCountry != null ||
        currentFilters.status != null ||
        currentFilters.sortBy != null ||
        (currentFilters.searchQuery != null && currentFilters.searchQuery!.isNotEmpty);
  }

  void _exportResults(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export functionality will be implemented')));
  }

  void _shareFilters(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share filters functionality will be implemented')));
  }

  void _showFilterSummary(BuildContext context, OneUITheme theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Active Filters',
          style: TextStyle(color: theme.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentFilters.searchQuery != null && currentFilters.searchQuery!.isNotEmpty) _buildFilterItem('Search', currentFilters.searchQuery!, theme),
            if (currentFilters.selectedSpecialty != null) _buildFilterItem('Specialty', currentFilters.selectedSpecialty!.name, theme),
            if (currentFilters.selectedCountry != null) _buildFilterItem('Country', '${currentFilters.selectedCountry!.flag} ${currentFilters.selectedCountry!.name}', theme),
            if (currentFilters.status != null) _buildFilterItem('Status', currentFilters.status!.value.toUpperCase(), theme),
            if (currentFilters.sortBy != null) _buildFilterItem('Sort', '${currentFilters.sortBy} (${currentFilters.sortOrder ?? 'desc'})', theme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: theme.primary, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String label, String value, OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, fontFamily: 'Poppins', color: theme.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: theme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
