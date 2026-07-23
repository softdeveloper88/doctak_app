import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_chips.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_display_utils.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_search_header.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Shared job list card — Browse / Saved / Applications / Manage / search / feed.
/// Layout aligned with doctak-node [JobCard] (website jobs browse).
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onBookmark,
    this.showBookmark = true,
    this.showRecruiterStats = false,
    this.trailing,
    this.statusLabel,
    this.statusTone,
    this.footerLabel,
  });

  final JobCardDto job;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final bool showBookmark;
  final bool showRecruiterStats;
  final Widget? trailing;
  final String? statusLabel;
  final JobChipTone? statusTone;
  final String? footerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final company = job.companyName?.trim().isNotEmpty == true
        ? job.companyName!
        : (job.organization?.name ?? 'Healthcare employer');
    final location = JobDisplayUtils.locationLine(job);
    final postedWhen = JobDisplayUtils.postedTimeLabel(job.createdAt);
    final salary = job.salaryRange != null && job.salaryRange!.trim().isNotEmpty
        ? JobDisplayUtils.salaryLabel(job.salaryRange)
        : null;
    final expiry = footerLabel ??
        JobDisplayUtils.expiryLabel(
          daysLeft: job.daysLeft,
          isExpired: job.isExpired,
        );

    final tags = <String>[
      JobDisplayUtils.formatExperience(job.experience),
      if (job.country != null && job.country!.trim().isNotEmpty)
        job.country!.trim(),
      JobDisplayUtils.jobTypeLabel(job.jobType),
      ...job.specialties.take(2),
      if (job.specialty != null &&
          job.specialty!.isNotEmpty &&
          !job.specialties.contains(job.specialty))
        job.specialty!,
    ].where((s) => s.trim().isNotEmpty && s != 'Role').toList();

    return JobsSurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JobLogoAvatar(
                imageUrl: job.organization?.logoUrl ?? job.image,
                size: 52,
                radius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: JobsTheme.title,
                          ),
                        ),
                        if (postedWhen.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            postedWhen,
                            style: JobsTheme.caption.copyWith(
                              color: theme.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: JobsTheme.bodyMuted.copyWith(fontSize: 13),
                        children: [
                          TextSpan(
                            text: company,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (location.isNotEmpty &&
                              location != 'Location flexible') ...[
                            const TextSpan(
                              text: '  ·  ',
                              style: TextStyle(color: JobsTheme.outline),
                            ),
                            TextSpan(text: location),
                          ],
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty ||
              job.promoted ||
              statusLabel != null ||
              job.isApplied) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (job.promoted) PromotedBadge(tier: job.promotionTier),
                for (final tag in tags) JobChip(label: tag),
                if (statusLabel != null && statusLabel!.isNotEmpty)
                  JobChip(
                    label: statusLabel!,
                    tone: statusTone ?? JobChipTone.neutral,
                  ),
                if (job.isApplied && statusLabel == null)
                  const JobChip(label: 'Applied', tone: JobChipTone.success),
                if (job.isExpired && statusLabel == null)
                  const JobChip(label: 'Expired', tone: JobChipTone.danger),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: showRecruiterStats
                    ? _RecruiterStatsRow(job: job)
                    : _CandidateFooter(
                        theme: theme,
                        salary: salary,
                        expiry: expiry,
                        daysLeft: job.daysLeft,
                        isExpired: job.isExpired,
                      ),
              ),
              if (trailing != null)
                trailing!
              else if (showBookmark && onBookmark != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: job.isBookmarked ? 'Remove save' : 'Save role',
                  onPressed: onBookmark,
                  icon: Icon(
                    job.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: job.isBookmarked
                        ? theme.primary
                        : theme.textTertiary,
                    size: 22,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CandidateFooter extends StatelessWidget {
  const _CandidateFooter({
    required this.theme,
    required this.salary,
    required this.expiry,
    required this.daysLeft,
    required this.isExpired,
  });

  final OneUITheme theme;
  final String? salary;
  final String? expiry;
  final int? daysLeft;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (salary != null)
          Text(
            '$salary · est.',
            style: JobsTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
            ),
          ),
        if (expiry != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: JobDisplayUtils.expiryColor(
                    theme,
                    daysLeft: daysLeft,
                    isExpired: isExpired,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                expiry!,
                style: JobsTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: JobDisplayUtils.expiryColor(
                    theme,
                    daysLeft: daysLeft,
                    isExpired: isExpired,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _RecruiterStatsRow extends StatelessWidget {
  const _RecruiterStatsRow({required this.job});

  final JobCardDto job;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.visibility_outlined,
          size: 14,
          color: JobsTheme.outline,
        ),
        const SizedBox(width: 4),
        Text('${job.stats.views}', style: JobsTheme.caption),
        const SizedBox(width: 14),
        const Icon(
          Icons.people_outline,
          size: 14,
          color: JobsTheme.outline,
        ),
        const SizedBox(width: 4),
        Text('${job.stats.applicants}', style: JobsTheme.caption),
        const Spacer(),
        Text(
          job.daysLeft != null && job.daysLeft! >= 0
              ? '${job.daysLeft}d left'
              : JobDisplayUtils.relativePosted(job.createdAt),
          style: JobsTheme.caption.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
