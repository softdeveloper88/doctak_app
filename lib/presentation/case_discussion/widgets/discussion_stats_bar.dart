import 'package:flutter/material.dart';
import '../models/case_discussion_models.dart';

class DiscussionStatsBar extends StatelessWidget {
  final List<CaseDiscussionListItem> discussions;
  final CaseDiscussionFilters currentFilters;
  final bool isLoading;

  const DiscussionStatsBar({
    Key? key,
    required this.discussions,
    required this.currentFilters,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading discussions...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
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
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Results count and filter info
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${discussions.length} discussions found',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              if (_hasActiveFilters()) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Filtered',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Show active specialty/country info
              if (currentFilters.selectedSpecialty != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentFilters.selectedSpecialty!.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (currentFilters.selectedCountry != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentFilters.selectedCountry!.flag,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      currentFilters.selectedCountry!.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              if (discussions.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 16),
                          SizedBox(width: 8),
                          Text('Export Results'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 16),
                          SizedBox(width: 8),
                          Text('Share Filters'),
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
                _buildStatItem(
                  icon: Icons.thumb_up_outlined,
                  label: 'Total Likes',
                  value: _formatNumber(totalLikes),
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.comment_outlined,
                  label: 'Total Comments',
                  value: _formatNumber(totalComments),
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.visibility_outlined,
                  label: 'Total Views',
                  value: _formatNumber(totalViews),
                  color: Colors.orange,
                ),
                const Spacer(),
                if (_hasActiveFilters())
                  TextButton(
                    onPressed: () => _showFilterSummary(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'View Filters',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality will be implemented'),
      ),
    );
  }

  void _shareFilters(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share filters functionality will be implemented'),
      ),
    );
  }

  void _showFilterSummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentFilters.searchQuery != null && currentFilters.searchQuery!.isNotEmpty)
              _buildFilterItem('Search', currentFilters.searchQuery!),
            if (currentFilters.selectedSpecialty != null)
              _buildFilterItem('Specialty', currentFilters.selectedSpecialty!.name),
            if (currentFilters.selectedCountry != null)
              _buildFilterItem('Country', '${currentFilters.selectedCountry!.flag} ${currentFilters.selectedCountry!.name}'),
            if (currentFilters.status != null)
              _buildFilterItem('Status', currentFilters.status!.value.toUpperCase()),
            if (currentFilters.sortBy != null)
              _buildFilterItem('Sort', '${currentFilters.sortBy} (${currentFilters.sortOrder ?? 'desc'})'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
