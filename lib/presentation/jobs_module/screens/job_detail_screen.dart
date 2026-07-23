import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/screens/apply_wizard_sheet.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_applicants_screen.dart';
import 'package:doctak_app/presentation/jobs_module/screens/my_application_detail_screen.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/ai_insight_sheets.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_application_stage_stepper.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_chips.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_display_utils.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_empty_state.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_safe_icons.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_search_header.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:shimmer/shimmer.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobDetailDto? _job;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final job = await JobsNodeApiService.getJobDetail(widget.jobId);
      JobsNodeApiService.track(widget.jobId, type: 'view');
      if (!mounted) return;
      setState(() {
        _job = job;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final job = _job;
    if (job == null) return;
    try {
      final booked = await JobsNodeApiService.toggleBookmark(job.id);
      if (!mounted) return;
      setState(() {
        _job = JobDetailDto.fromJson({
          ..._jobToMap(job),
          'isBookmarked': booked,
        });
      });
    } catch (e) {
      toast(e.toString());
    }
  }

  Map<String, dynamic> _jobToMap(JobDetailDto job) {
    return {
      'id': job.id,
      'title': job.title,
      'companyName': job.companyName,
      'location': job.location,
      'experience': job.experience,
      'specialty': job.specialty,
      'specialties': job.specialties,
      'jobType': job.jobType,
      'salaryRange': job.salaryRange,
      'description': job.description,
      'image': job.image,
      'lastDate': job.lastDate,
      'createdAt': job.createdAt,
      'country': job.country,
      'promoted': job.promoted,
      'promotionTier': job.promotionTier,
      'isFreeTier': job.isFreeTier,
      'organization': {
        'id': job.organization?.id,
        'name': job.organization?.name,
        'type': job.organization?.type,
        'logoUrl': job.organization?.logoUrl,
      },
      'posterUserId': job.posterUserId,
      'stats': {
        'views': job.stats.views,
        'applicants': job.stats.applicants,
      },
      'isApplied': job.isApplied,
      'isBookmarked': job.isBookmarked,
      'daysLeft': job.daysLeft,
      'isExpired': job.isExpired,
      'link': job.link,
      'applyType': job.applyType,
      'totalJobs': job.totalJobs,
      'preferredLanguage': job.preferredLanguage,
      'applicationFields': job.applicationFields
          .map((f) => {
                'id': f.id,
                'fieldKey': f.fieldKey,
                'label': f.label,
                'type': f.type,
                'required': f.required,
                'options': f.options,
                'placeholder': f.placeholder,
                'isCustom': f.isCustom,
              })
          .toList(),
      'applicationId': job.applicationId,
      'applicationStatus': job.applicationStatus,
      'appliedAt': job.appliedAt,
      'aiMatchScore': job.aiMatchScore,
      'savedCvs': job.savedCvs
          .map((c) => {
                'id': c.id,
                'path': c.path,
                'name': c.name,
                'url': c.url,
                'isDefault': c.isDefault,
              })
          .toList(),
      'isOwnerView': job.isOwnerView,
    };
  }

  Future<void> _apply() async {
    final job = _job;
    if (job == null) return;
    if (job.isExternalApply) {
      JobsNodeApiService.track(job.id, type: 'click');
      await JobDisplayUtils.openExternalUrl(job.link);
      return;
    }
    final applied = await showApplyWizard(context: context, job: job);
    if (applied == true) _load();
  }

  Future<void> _withdraw() async {
    final job = _job;
    if (job == null) return;
    try {
      final applicationId = await _resolveApplicationId(job);
      if (applicationId == null || applicationId.isEmpty) {
        toast('Application not found');
        return;
      }
      if (!mounted) return;
      final ok = await showOneUIConfirmDialog(
        context,
        title: 'Withdraw application?',
        subtitle:
            'This removes your application. You can apply again later if the job is still open.',
        confirmLabel: 'Withdraw',
        cancelLabel: 'Cancel',
        destructive: true,
      );
      if (!ok || !mounted) return;
      await JobsNodeApiService.withdrawApplication(applicationId);
      toast('Application withdrawn');
      _load();
    } catch (e) {
      toast(e.toString());
    }
  }

  Future<String?> _resolveApplicationId(JobDetailDto job) async {
    final fromDetail = job.applicationId;
    if (fromDetail != null && fromDetail.isNotEmpty) return fromDetail;
    final apps = await JobsNodeApiService.getMyApplications();
    final match = apps.where((a) => a.job.id == job.id).toList();
    if (match.isEmpty) return null;
    return match.first.applicationId;
  }

  Future<void> _openApplicationStatus() async {
    final job = _job;
    if (job == null) return;
    try {
      final applicationId = await _resolveApplicationId(job);
      if (applicationId == null || applicationId.isEmpty) {
        toast('Application not found');
        return;
      }
      if (!mounted) return;
      await MyApplicationDetailScreen(applicationId: applicationId).launch(context);
      if (mounted) _load();
    } catch (e) {
      toast(e.toString());
    }
  }

  String _absoluteDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return '';
    }
  }

  String _postedHeadline(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final startToday = DateTime(now.year, now.month, now.day);
      final startPosted = DateTime(d.year, d.month, d.day);
      final days = startToday.difference(startPosted).inDays;
      if (days <= 0) return 'Today';
      if (days == 1) return 'Yesterday';
      return JobDisplayUtils.relativePosted(iso);
    } catch (_) {
      return JobDisplayUtils.relativePosted(iso);
    }
  }

  bool _hasCoverImage(JobDetailDto job) {
    final url = job.image?.trim();
    return url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final company = job?.companyName?.trim().isNotEmpty == true
        ? job!.companyName!
        : (job?.organization?.name ?? 'Employer');

    return Scaffold(
      backgroundColor: OneUITheme.of(context).scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Job Details',
        backgroundColor: OneUITheme.of(context).cardBackground,
        showShadow: false,
        actions: [
          if (job != null)
            IconButton(
              onPressed: () => DeepLinkService.shareJob(
                jobId: job.id,
                title: job.title,
                company: job.companyName,
                location: job.location,
              ),
              icon: const Icon(Icons.share_outlined, color: JobsTheme.primary),
            ),
        ],
      ),
      body: _loading
          ? const _JobDetailShimmer()
          : _error != null
              ? JobsEmptyState(
                  title: 'Couldn’t load job',
                  subtitle: _error,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : job == null
                  ? const JobsEmptyState(title: 'Job not found')
                  : RefreshIndicator(
                      color: JobsTheme.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        children: [
                          if (job.isApplied) ...[
                            _AppliedBanner(
                              job: job,
                              onTap: _openApplicationStatus,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_hasCoverImage(job))
                            _JobCoverImage(url: job.image!.trim()),
                          JobsSurfaceCard(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    JobLogoAvatar(
                                      imageUrl: job.organization?.logoUrl,
                                      size: 56,
                                      radius: 14,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  job.title,
                                                  style: JobsTheme.displayTitle,
                                                ),
                                              ),
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 36,
                                                  minHeight: 36,
                                                ),
                                                onPressed: _toggleBookmark,
                                                icon: Icon(
                                                  job.isBookmarked
                                                      ? Icons.bookmark_rounded
                                                      : Icons
                                                          .bookmark_border_rounded,
                                                  color: job.isBookmarked
                                                      ? JobsTheme.primary
                                                      : JobsTheme
                                                          .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            company,
                                            style: JobsTheme.bodyMuted.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.place_outlined,
                                      size: 16,
                                      color: JobsTheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        JobDisplayUtils.locationLine(job),
                                        style: JobsTheme.bodyMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (job.promoted)
                                      PromotedBadge(tier: job.promotionTier),
                                    JobChip(
                                      label: JobDisplayUtils.jobTypeLabel(
                                        job.jobType,
                                      ),
                                      tone: JobChipTone.primary,
                                      dense: false,
                                    ),
                                    if (job.experience != null &&
                                        job.experience!.isNotEmpty)
                                      JobChip(
                                        label: job.experience!,
                                        dense: false,
                                      ),
                                    if (job.isExpired)
                                      const JobChip(
                                        label: 'Expired',
                                        tone: JobChipTone.danger,
                                        dense: false,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _HighlightTile(
                                  label: 'Salary',
                                  value: job.salaryRange != null &&
                                          job.salaryRange!.isNotEmpty
                                      ? JobDisplayUtils.salaryLabel(
                                          job.salaryRange,
                                        )
                                      : '—',
                                  caption:
                                      'Per year · ${JobDisplayUtils.jobTypeLabel(job.jobType)}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _HighlightTile(
                                  label: 'Posted',
                                  value: _postedHeadline(job.createdAt),
                                  caption: _absoluteDate(job.createdAt),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _HighlightTile(
                            label: 'Openings',
                            value: '${job.totalJobs ?? 1}',
                            caption:
                                'position${(job.totalJobs ?? 1) == 1 ? '' : 's'} available',
                          ),
                          if (!job.isOwnerView) ...[
                            const SizedBox(height: 16),
                            _AiInsightsRow(job: job),
                          ],
                          const SizedBox(height: 16),
                          JobsSurfaceCard(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const JobSectionLabel('About the Role'),
                                const SizedBox(height: 10),
                                HtmlWidget(
                                  job.description ??
                                      '<p>No description provided.</p>',
                                  textStyle:
                                      JobsTheme.body.copyWith(height: 1.55),
                                ),
                              ],
                            ),
                          ),
                          if (job.specialties.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            JobsSurfaceCard(
                              margin: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const JobSectionLabel('Specialties'),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: job.specialties
                                        .map(
                                          (s) => JobChip(
                                            label: s,
                                            dense: false,
                                            outlined: true,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          JobsSurfaceCard(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                JobSectionLabel('About $company'),
                                const SizedBox(height: 10),
                                Text(
                                  '$company is a verified hiring partner on DocTak — '
                                  'credentials and licensing requirements are confirmed before posting.',
                                  style: JobsTheme.bodyMuted
                                      .copyWith(height: 1.55),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
      bottomNavigationBar: job == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: JobsTheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: JobsTheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                child: job.isOwnerView
                    ? _PillButton(
                        label: 'View applicants',
                        onPressed: () => JobApplicantsScreen(
                          jobId: job.id,
                          jobTitle: job.title,
                        ).launch(context),
                      )
                    : job.isApplied
                        ? Row(
                            children: [
                              Expanded(
                                child: _PillButton(
                                  label: 'Check status',
                                  onPressed: _openApplicationStatus,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PillButton(
                                  label: 'Withdraw',
                                  outlined: true,
                                  danger: true,
                                  onPressed: _withdraw,
                                ),
                              ),
                            ],
                          )
                        : _PillButton(
                            label: job.isExpired
                                ? 'Applications closed'
                                : job.isExternalApply
                                    ? 'Apply on website'
                                    : 'Apply now',
                            onPressed: job.isExpired ? null : _apply,
                          ),
              ),
            ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    this.onPressed,
    this.outlined = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(kOneUIButtonHeight),
          maximumSize: const Size.fromHeight(kOneUIButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: danger ? JobsTheme.danger : JobsTheme.primary,
          side: BorderSide(
            color: danger ? JobsTheme.danger : JobsTheme.primary,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: JobsTheme.title.copyWith(
            fontSize: 14,
            color: danger ? JobsTheme.danger : JobsTheme.primary,
          ),
        ),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kOneUIButtonHeight),
        maximumSize: const Size.fromHeight(kOneUIButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: JobsTheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: radius),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: JobsTheme.title.copyWith(fontSize: 14, color: Colors.white),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return JobsSurfaceCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JobSectionLabel(label),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: JobsTheme.title.copyWith(
                fontSize: 15,
                height: 1.2,
              ),
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: JobsTheme.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _AppliedBanner extends StatelessWidget {
  const _AppliedBanner({required this.job, this.onTap});

  final JobDetailDto job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = job.applicationStatus?.trim();
    final stage = (status == null || status.isEmpty) ? 'new' : status;
    final statusLabel = 'Applied · ${JobStageLabels.label(stage)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: JobsSurfaceCard(
          margin: EdgeInsets.zero,
          borderColor: JobsTheme.primary.withValues(alpha: 0.28),
          color: JobsTheme.successSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: JobsTheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: JobsTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusLabel,
                          style: JobsTheme.body
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (job.appliedAt != null)
                          Text(
                            'Applied ${JobDisplayUtils.friendlyDateTime(job.appliedAt)}',
                            style: JobsTheme.caption,
                          )
                        else
                          Text(
                            'Tap to view full status',
                            style: JobsTheme.caption,
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: JobsTheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              JobApplicationStageStepper(stage: stage, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiInsightsRow extends StatelessWidget {
  const _AiInsightsRow({required this.job});

  final JobDetailDto job;

  @override
  Widget build(BuildContext context) {
    final score = job.aiMatchScore;
    final subtitle = score != null
        ? 'Your fit score is ${score.round()}% — tap to refresh or deepen analysis'
        : 'See how your profile matches this role before you apply';

    return Column(
      children: [
        JobsSurfaceCard(
          margin: EdgeInsets.zero,
          onTap: () => showFitPreviewSheet(context, job),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: JobsTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: JobsSafeIcon.insights(size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyze my fit',
                      style: JobsTheme.title.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: JobsTheme.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (score != null) ...[
                const SizedBox(width: 8),
                JobChip(
                  label: '${score.round()}%',
                  tone: JobChipTone.primary,
                ),
              ] else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: JobsTheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
        if (job.promoted) ...[
          const SizedBox(height: 10),
          JobsSurfaceCard(
            margin: EdgeInsets.zero,
            onTap: () => showAiBriefSheet(context, job.id),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: JobsTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: JobsSafeIcon.sparkles(size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI job brief',
                        style: JobsTheme.title.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Get a concise summary of this promoted role',
                        style: JobsTheme.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: JobsTheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _JobCoverImage extends StatefulWidget {
  const _JobCoverImage({required this.url});

  final String url;

  @override
  State<_JobCoverImage> createState() => _JobCoverImageState();
}

class _JobCoverImageState extends State<_JobCoverImage> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: JobsSurfaceCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: widget.url,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, _) => Container(
                color: JobsTheme.surfaceContainerLow,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: JobsTheme.primary,
                  ),
                ),
              ),
              errorWidget: (_, _, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _failed = true);
                });
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _JobDetailShimmer extends StatelessWidget {
  const _JobDetailShimmer();

  @override
  Widget build(BuildContext context) {
    const base = JobsTheme.surfaceContainer;
    const highlight = JobsTheme.surfaceContainerLow;

    Widget bone({
      double? width,
      double height = 12,
      double radius = 8,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    Widget tile() => Expanded(
          child: JobsSurfaceCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bone(width: 56, height: 10),
                const SizedBox(height: 10),
                bone(width: 72, height: 16),
                const SizedBox(height: 8),
                bone(width: 96, height: 10),
              ],
            ),
          ),
        );

    return ColoredBox(
      color: JobsTheme.background,
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Cover placeholder (matches optional cover card)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x1A0B1220)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header card
            JobsSurfaceCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bone(width: 56, height: 56, radius: 14),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bone(width: 200, height: 16),
                            const SizedBox(height: 8),
                            bone(width: 120, height: 12),
                          ],
                        ),
                      ),
                      bone(width: 28, height: 28, radius: 8),
                    ],
                  ),
                  const SizedBox(height: 12),
                  bone(width: 160, height: 12),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      bone(width: 78, height: 28, radius: 8),
                      const SizedBox(width: 8),
                      bone(width: 64, height: 28, radius: 8),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [tile(), const SizedBox(width: 12), tile()]),
            const SizedBox(height: 12),
            JobsSurfaceCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bone(width: 72, height: 10),
                  const SizedBox(height: 10),
                  bone(width: 40, height: 16),
                  const SizedBox(height: 8),
                  bone(width: 140, height: 10),
                ],
              ),
            ),
            const SizedBox(height: 16),
            JobsSurfaceCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  bone(width: 40, height: 40, radius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bone(width: 110, height: 14),
                        const SizedBox(height: 8),
                        bone(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            JobsSurfaceCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bone(width: 100, height: 10),
                  const SizedBox(height: 12),
                  bone(height: 12),
                  const SizedBox(height: 8),
                  bone(height: 12),
                  const SizedBox(height: 8),
                  bone(width: 180, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
