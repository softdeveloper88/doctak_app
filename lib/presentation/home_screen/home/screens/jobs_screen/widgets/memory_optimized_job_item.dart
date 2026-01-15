import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

/// Enhanced memory-optimized job item widget with One UI 8.5 design
class MemoryOptimizedJobItem extends StatefulWidget {
  final dynamic jobData;
  final VoidCallback onJobTap;
  final VoidCallback onShareTap;
  final Function(String) onApplyTap;
  final Function(Uri) onLaunchLink;

  const MemoryOptimizedJobItem({super.key, required this.jobData, required this.onJobTap, required this.onShareTap, required this.onApplyTap, required this.onLaunchLink});

  @override
  State<MemoryOptimizedJobItem> createState() => _MemoryOptimizedJobItemState();
}

class _MemoryOptimizedJobItemState extends State<MemoryOptimizedJobItem> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onJobTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          decoration: theme.cardDecoration,
          child: ClipRRect(
            borderRadius: theme.radiusL,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildJobHeader(theme), _buildJobContent(theme), _buildJobDetails(theme), _buildActionRow(theme)]),
          ),
        ),
      ),
    );
  }

  Widget _buildJobHeader(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.cardBackground,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company/Job Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primary.withValues(alpha: 0.15), theme.secondary.withValues(alpha: 0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: theme.radiusM,
            ),
            child: Center(child: Icon(Icons.work_outline_rounded, color: theme.primary, size: 28)),
          ),
          const SizedBox(width: 12),

          // Job Title and Company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.jobData.jobTitle ?? "",
                  style: TextStyle(color: theme.primary, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(widget.jobData.companyName ?? 'N/A', style: theme.bodyMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: theme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(widget.jobData.location ?? 'N/A', style: theme.caption)),
                    if (widget.jobData.promoted != null && widget.jobData.promoted != 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: theme.warning.withValues(alpha: 0.15), borderRadius: theme.radiusM),
                        child: Text(
                          'Sponsored',
                          style: TextStyle(color: theme.warning, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Share button
          IconButton(
            onPressed: widget.onShareTap,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: theme.iconButtonBg, shape: BoxShape.circle),
              child: Icon(Icons.share_outlined, size: 18, color: theme.iconColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobContent(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: theme.divider, width: 1)),
      ),
      child: Row(
        children: [
          // Experience Info
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Icon(Icons.work_history_outlined, size: 20, color: theme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Experience', style: theme.caption),
                      Text(
                        widget.jobData.experience ?? 'Not specified',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.textPrimary, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Language Info
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(Icons.language_outlined, size: 20, color: theme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Language', style: theme.caption),
                      Text(
                        widget.jobData.preferredLanguage ?? 'Any',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.textPrimary, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetails(OneUITheme theme) {
    String description = widget.jobData.description ?? "";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Application Dates
          Row(
            children: [
              Expanded(child: _buildDateInfo('Application Start', widget.jobData.createdAt, Icons.calendar_today_outlined, theme.success, theme)),
              const SizedBox(width: 16),
              Expanded(child: _buildDateInfo('Application End', widget.jobData.lastDate, Icons.event_outlined, theme.error, theme)),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Job Description',
              style: TextStyle(color: theme.textSecondary, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: _isDescriptionExpanded ? double.infinity : 60),
              child: SingleChildScrollView(
                physics: _isDescriptionExpanded ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
                child: HtmlWidget(
                  '<p>$description</p>',
                  textStyle: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: theme.textSecondary, height: 1.4),
                ),
              ),
            ),
            if (description.length > 100)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDescriptionExpanded = !_isDescriptionExpanded;
                    });
                  },
                  child: Text(
                    _isDescriptionExpanded ? 'See less' : 'See more',
                    style: TextStyle(color: theme.primary, fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateInfo(String title, String? date, IconData icon, Color color, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: theme.radiusM,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            date != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(date)) : 'Not specified',
            style: TextStyle(color: theme.textSecondary, fontSize: 13, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: theme.divider, width: 1)),
      ),
      child: Row(
        children: [
          // Apply Button
          if (widget.jobData.user?.id != null)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => widget.onApplyTap(widget.jobData.id.toString()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: theme.radiusXL),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_outlined, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Apply Now',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
            ),

          if (widget.jobData.user?.id != null) const SizedBox(width: 12),

          // Visit Site Button
          Expanded(
            flex: widget.jobData.user?.id != null ? 2 : 1,
            child: OutlinedButton(
              onPressed: () async {
                final Uri url = Uri.parse(widget.jobData.link ?? '');
                final shouldLeave = await _showConfirmationDialog(context, theme);
                if (!mounted) return;

                if (shouldLeave == true) {
                  widget.onLaunchLink(url);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).msg_leaving_app_canceled)));
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.primary.withValues(alpha: 0.3), width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: theme.radiusXL),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new_outlined, size: 16, color: theme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Visit Site',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, OneUITheme theme) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: theme.radiusL),
        title: Text(translation(context).lbl_leave_app, style: theme.titleMedium),
        content: Text(translation(context).msg_open_link_confirm, style: theme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(translation(context).lbl_no_answer, style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(translation(context).lbl_yes, style: TextStyle(color: theme.primary)),
          ),
        ],
      ),
    );
  }
}
