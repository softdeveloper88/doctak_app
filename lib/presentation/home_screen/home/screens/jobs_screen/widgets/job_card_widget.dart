import 'package:doctak_app/core/utils/post_utils.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobCardWidget extends StatelessWidget {
  final dynamic jobData; // Replace 'dynamic' with the actual model type
  final int selectedIndex;
  final VoidCallback onJobTap;
  final VoidCallback onShareTap;
  final Function(String) onApplyTap;
  final Function(Uri) onLaunchLink;

  const JobCardWidget({
    super.key,
    required this.jobData,
    required this.selectedIndex,
    required this.onJobTap,
    required this.onShareTap,
    required this.onApplyTap,
    required this.onLaunchLink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onJobTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF0F172A)
              : Colors.white, // slate-900 / white
          borderRadius: BorderRadius.circular(12), // rounded-xl
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9), // slate-800 / slate-100
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobHeader(theme, isDark),
            const SizedBox(height: 16),
            _buildJobMetadataRow(isDark),
            const SizedBox(height: 20),
            _buildDateBoxes(isDark),
            const SizedBox(height: 20),
            _buildActionRow(theme, isDark, context),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHeader(ThemeData theme, bool isDark) {
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
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC), // slate-800 / slate-50
                  borderRadius: BorderRadius.circular(8), // rounded-lg
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9), // slate-700 / slate-100
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons
                        .local_hospital, // You can make this dynamic if job type varies
                    color: theme.primaryColor,
                    size: 32, // text-3xl roughly
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
                          jobData.jobTitle ?? "Position Available",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                            height: 1.2,
                          ),
                        ),
                        if (jobData.promoted != null && jobData.promoted != 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.amber[900]!.withOpacity(0.3)
                                  : Colors.amber[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SPONSORED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.amber[400]
                                    : Colors.amber[700],
                                letterSpacing: 0.5, // tracking-wider
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jobData.companyName ?? 'Healthcare Facility',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569), // slate-400 / slate-600
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
          onPressed: onShareTap,
          icon: Icon(
            Icons.bookmark_outline,
            color: isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF94A3B8), // slate-400 roughly
          ),
        ),
      ],
    );
  }

  Widget _buildJobMetadataRow(bool isDark) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildMetaItem(
          Icons.location_on,
          jobData.location ?? "Not specified",
          isDark,
        ),
        if (jobData.experience != null &&
            jobData.experience.toString().isNotEmpty)
          _buildMetaItem(
            Icons.work_history,
            '${jobData.experience} Exp.',
            isDark,
          ),
        if (jobData.preferredLanguage != null &&
            jobData.preferredLanguage.toString().isNotEmpty)
          _buildMetaItem(Icons.translate, jobData.preferredLanguage, isDark),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String text, bool isDark) {
    final textColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF64748B); // slate-500
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: textColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14, // text-[12pt] roughly 14px-16px
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDateBoxes(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildDateBox(
            title: 'Application Opens',
            date: jobData.createdAt,
            colorSwatch: Colors.green,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateBox(
            title: 'Application Closes',
            date: jobData.lastDate,
            colorSwatch: Colors.red,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDateBox({
    required String title,
    required String? date,
    required MaterialColor colorSwatch,
    required bool isDark,
  }) {
    final bgColor = isDark
        ? colorSwatch[900]!.withOpacity(0.2)
        : colorSwatch[50];
    final borderColor = isDark
        ? colorSwatch[800]!.withOpacity(0.5)
        : colorSwatch[100];
    final titleColor = isDark ? colorSwatch[400] : colorSwatch[600];
    final dateColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E293B); // slate-200 / slate-800

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date != null
                ? DateFormat('MMM dd, yyyy').format(DateTime.parse(date))
                : 'Not specified',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dateColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(ThemeData theme, bool isDark, BuildContext context) {
    bool isJobOwner = jobData.user?.id == AppData.logInUserId;
    bool hasApplied =
        jobData.applicants?.any(
          (applicant) => applicant.id == AppData.logInUserId,
        ) ??
        false;

    return Row(
      children: [
        if (!isJobOwner)
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: hasApplied
                    ? null
                    : () => onApplyTap(jobData.id.toString()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasApplied
                      ? Colors.green.withOpacity(0.1)
                      : theme.primaryColor,
                  foregroundColor: hasApplied ? Colors.green : Colors.white,
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

        if (!isJobOwner && jobData.link != null && jobData.link!.isNotEmpty)
          const SizedBox(width: 12),

        if (jobData.link != null && jobData.link!.isNotEmpty)
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  if (jobData.link != null && jobData.link!.isNotEmpty) {
                    await PostUtils.launchURL(context, jobData.link!);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(
                    color: theme.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Visit Site',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
