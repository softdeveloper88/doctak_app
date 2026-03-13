import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Enhanced memory-optimized job item widget with One UI 8.5 design
class MemoryOptimizedJobItem extends StatefulWidget {
  final dynamic jobData;
  final VoidCallback onJobTap;
  final VoidCallback onShareTap;
  final Function(String) onApplyTap;
  final Function(Uri) onLaunchLink;

  const MemoryOptimizedJobItem({
    super.key,
    required this.jobData,
    required this.onJobTap,
    required this.onShareTap,
    required this.onApplyTap,
    required this.onLaunchLink,
  });

  @override
  State<MemoryOptimizedJobItem> createState() => _MemoryOptimizedJobItemState();
}

class _MemoryOptimizedJobItemState extends State<MemoryOptimizedJobItem> {
  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    // Light Theme specific colors based on the design
    // Dark Theme uses existing OneUITheme variables
    final isDark = theme.isDark;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onJobTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : Colors.white, // slate-800 / white
            borderRadius: BorderRadius.circular(16), // rounded-2xl
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9), // slate-700 / slate-100
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04), // shadow-sm
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildJobHeader(theme, isDark),
              const SizedBox(height: 16),
              _buildJobMetadataRow(theme, isDark),
              const SizedBox(height: 20),
              _buildDateBoxes(theme, isDark),
              const SizedBox(height: 20),
              _buildActionRow(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobHeader(OneUITheme theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.work_outline,
                    color: theme.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title and Company
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          widget.jobData.jobTitle ?? "Position Available",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.primary,
                            height: 1.2,
                          ),
                        ),
                        if (widget.jobData.promoted != null &&
                            widget.jobData.promoted != 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: theme.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'PROMOTED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: theme.warning,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.jobData.companyName ?? 'Healthcare Facility',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bookmark / Share
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: widget.onShareTap,
          icon: Icon(
            Icons.share_outlined,
            color: theme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildJobMetadataRow(OneUITheme theme, bool isDark) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildMetaItem(
          Icons.location_on,
          widget.jobData.location ?? "Not specified",
          theme,
        ),
        if (widget.jobData.experience != null &&
            widget.jobData.experience.toString().isNotEmpty)
          _buildMetaItem(
            Icons.work_history,
            '${widget.jobData.experience} Exp.',
            theme,
          ),
        if (widget.jobData.preferredLanguage != null &&
            widget.jobData.preferredLanguage.toString().isNotEmpty)
          _buildMetaItem(
            Icons.translate,
            widget.jobData.preferredLanguage,
            theme,
          ),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String text, OneUITheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: theme.textSecondary),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDateBoxes(OneUITheme theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildDateBox(
            title: 'Application Opens',
            date: widget.jobData.createdAt,
            accentColor: theme.success,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateBox(
            title: 'Application Closes',
            date: widget.jobData.lastDate,
            accentColor: theme.error,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildDateBox({
    required String title,
    required String? date,
    required Color accentColor,
    required OneUITheme theme,
  }) {
    String fmtDate(String? d) {
      if (d == null || d.trim().isEmpty) return 'Not specified';
      try {
        return DateFormat('MMM dd, yyyy').format(DateTime.parse(d));
      } catch (_) {
        return d;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fmtDate(date),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(OneUITheme theme, bool isDark) {
    bool isJobOwner = widget.jobData.user?.id == AppData.logInUserId;
    bool hasApplied =
        widget.jobData.applicants?.any(
          (applicant) => applicant.id == AppData.logInUserId,
        ) ??
        false;
    final hasLink = widget.jobData.link != null &&
        widget.jobData.link!.toString().trim().isNotEmpty;

    return Row(
      children: [
        if (!isJobOwner) ...[          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: hasApplied
                    ? null
                    : () => widget.onApplyTap(widget.jobData.id.toString()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasApplied
                      ? theme.success.withOpacity(0.12)
                      : theme.primary,
                  foregroundColor:
                      hasApplied ? theme.success : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  hasApplied ? 'Applied' : 'Apply Now',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: hasLink
                  ? () => PostUtils.launchURL(
                      context, widget.jobData.link!.toString())
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                disabledForegroundColor:
                    theme.textSecondary,
                side: BorderSide(
                  color: hasLink
                      ? theme.primary.withOpacity(0.4)
                      : theme.textSecondary.withOpacity(0.2),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Visit Site',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
