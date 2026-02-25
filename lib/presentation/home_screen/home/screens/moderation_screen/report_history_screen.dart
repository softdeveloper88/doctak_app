import 'package:doctak_app/data/apiClient/services/moderation_api_service.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';

/// Screen to view user's report history and check admin response status
class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final ModerationApiService _moderationService = ModerationApiService();
  final ScrollController _scrollController = ScrollController();
  List<ReportHistoryItem> _reports = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    final result = await _moderationService.getMyReports(page: 1);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _reports = result.data!.reports;
          _currentPage = result.data!.currentPage;
          _lastPage = result.data!.lastPage;
        } else {
          _error = result.message ?? 'Failed to load reports';
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    final result = await _moderationService.getMyReports(page: _currentPage + 1);
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success && result.data != null) {
          _reports.addAll(result.data!.reports);
          _currentPage = result.data!.currentPage;
          _lastPage = result.data!.lastPage;
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
        title: 'My Reports',
        titleIcon: Icons.flag_rounded,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView(theme)
              : _reports.isEmpty
                  ? _buildEmptyView(theme)
                  : _buildList(theme),
    );
  }

  Widget _buildErrorView(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: theme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flag_outlined, size: 64, color: theme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reports Yet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t reported any content yet.\nReports help keep the community safe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(OneUITheme theme) {
    return RefreshIndicator(
      onRefresh: _loadReports,
      color: theme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _reports.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _reports.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildReportCard(_reports[index], theme);
        },
      ),
    );
  }

  Widget _buildReportCard(ReportHistoryItem report, OneUITheme theme) {
    final statusInfo = _getStatusInfo(report);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.isDark ? theme.surfaceVariant : Colors.transparent,
        ),
        boxShadow: theme.isDark ? [] : theme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // Content type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getContentTypeColor(report.contentType).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getContentTypeIcon(report.contentType),
                    size: 20,
                    color: _getContentTypeColor(report.contentType),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_capitalizeFirst(report.contentType)} Report',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeAgo(report.createdAt),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusInfo.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusInfo.icon, size: 14, color: statusInfo.color),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo.label,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content preview
          if (report.contentPreview.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  report.contentPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: theme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          // Reason
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Icon(Icons.report_problem_outlined, size: 16, color: theme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Reason: ${_formatReason(report.reason)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Note (if provided)
          if (report.note != null && report.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                'Note: ${report.note}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: theme.textSecondary.withOpacity(0.8),
                ),
              ),
            ),

          // Overdue warning
          if (report.isOverdue && report.adminResponse == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Awaiting admin response (over 24 hours)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Admin response
          if (report.adminResponse != null && report.adminResponse!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          'Admin Response',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Spacer(),
                        if (report.adminRespondedAt != null)
                          Text(
                            _timeAgo(report.adminRespondedAt!),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.green.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.adminResponse!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(ReportHistoryItem report) {
    switch (report.status) {
      case 0:
        return report.isOverdue
            ? _StatusInfo('Overdue', Colors.orange, Icons.schedule)
            : _StatusInfo('Pending', Colors.blue, Icons.hourglass_empty);
      case 1:
        return _StatusInfo('Reviewing', Colors.purple, Icons.visibility);
      case 2:
        return _StatusInfo('Resolved', Colors.green, Icons.check_circle);
      case 3:
        return _StatusInfo('Dismissed', Colors.grey, Icons.cancel);
      default:
        return _StatusInfo('Unknown', Colors.grey, Icons.help);
    }
  }

  IconData _getContentTypeIcon(String type) {
    switch (type) {
      case 'post':
        return Icons.article_outlined;
      case 'comment':
        return Icons.comment_outlined;
      case 'user':
        return Icons.person_outlined;
      default:
        return Icons.flag_outlined;
    }
  }

  Color _getContentTypeColor(String type) {
    switch (type) {
      case 'post':
        return Colors.blue;
      case 'comment':
        return Colors.teal;
      case 'user':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatReason(String reason) {
    return reason.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;
  _StatusInfo(this.label, this.color, this.icon);
}
