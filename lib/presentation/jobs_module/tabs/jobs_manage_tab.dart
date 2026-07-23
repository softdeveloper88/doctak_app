import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_analytics_screen.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_applicants_screen.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_detail_screen.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_post_wizard_screen.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card_shimmer.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_display_utils.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_empty_state.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_sheet_shell.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class JobsManageTab extends StatefulWidget {
  const JobsManageTab({super.key, this.highlightJobId});

  final String? highlightJobId;

  @override
  State<JobsManageTab> createState() => _JobsManageTabState();
}

class _JobsManageTabState extends State<JobsManageTab>
    with AutomaticKeepAliveClientMixin {
  List<JobCardDto> _items = [];
  MyPostedJobsSummaryDto _summary = const MyPostedJobsSummaryDto();
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

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
      final result = await JobsNodeApiService.getMyPosted();
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _summary = result.summary;
        _loading = false;
      });
      if (widget.highlightJobId != null) {
        final hit = _items.where((j) => j.id == widget.highlightJobId).toList();
        if (hit.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            JobApplicantsScreen(jobId: hit.first.id, jobTitle: hit.first.title)
                .launch(context);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _promote(JobCardDto job) async {
    final tier = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = OneUITheme.of(ctx);
        return JobsSheetShell(
          title: 'Promote listing',
          subtitle: 'Checkout opens securely. After payment you’ll return here.',
          leading: const JobsSheetLeadingIcon(icon: Icons.rocket_launch_outlined),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PromoteTierTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Standard — \$49',
                subtitle: '30 days featured placement',
                onTap: () => Navigator.pop(ctx, 'standard'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.border.withValues(alpha: 0.85),
                ),
              ),
              _PromoteTierTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Premium — \$149',
                subtitle: 'Top placement + highlight',
                onTap: () => Navigator.pop(ctx, 'premium'),
              ),
            ],
          ),
        );
      },
    );
    if (tier == null) return;
    try {
      final url = await JobsNodeApiService.createPromoteCheckout(
        jobId: job.id,
        tier: tier,
        jobTitle: job.title,
      );
      if (url == null || url.isEmpty) {
        toast('Could not start checkout');
        return;
      }
      await JobDisplayUtils.openExternalUrl(url);
      if (!mounted) return;
      toast('Complete payment in the browser — we’ll bring you back to Manage.');
      await _load();
    } catch (e) {
      toast(e.toString());
    }
  }

  Future<void> _delete(JobCardDto job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text('Permanently delete “${job.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await JobsNodeApiService.deleteJob(job.id);
      toast('Job deleted');
      _load();
    } catch (e) {
      toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = OneUITheme.of(context);
    if (_loading) return const JobCardShimmerList();
    if (_error != null) {
      return JobsEmptyState(
        title: 'Couldn’t load postings',
        subtitle: _error,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    return ColoredBox(
      color: theme.scaffoldBackground,
      child: RefreshIndicator(
        color: theme.primary,
        onRefresh: _load,
        child: ListView(
          padding: JobsTheme.listPadding(context, top: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _metric('Active', '${_summary.activeJobs}', isLast: false),
                  _metric(
                    'Applicants',
                    '${_summary.totalApplicants}',
                    isLast: false,
                  ),
                  _metric('Views', '${_summary.listingViews}', isLast: true),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            JobsEmptyState(
              title: 'No job postings yet',
              subtitle: 'Post a role to start receiving applicants.',
              actionLabel: 'Post a job',
              onAction: () async {
                final ok = await const JobPostWizardScreen().launch(context);
                if (ok == true) _load();
              },
            )
          else
            ..._items.map((job) {
              return JobCard(
                job: job,
                showBookmark: false,
                showRecruiterStats: true,
                onTap: () => JobApplicantsScreen(
                  jobId: job.id,
                  jobTitle: job.title,
                ).launch(context),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'applicants':
                        JobApplicantsScreen(
                          jobId: job.id,
                          jobTitle: job.title,
                        ).launch(context);
                      case 'view':
                        JobDetailScreen(jobId: job.id).launch(context);
                      case 'edit':
                        final ok = await JobPostWizardScreen(
                          jobId: job.id,
                        ).launch(context);
                        if (ok == true) _load();
                      case 'analytics':
                        JobAnalyticsScreen(
                          jobId: job.id,
                          jobTitle: job.title,
                        ).launch(context);
                      case 'promote':
                        _promote(job);
                      case 'delete':
                        _delete(job);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'applicants',
                      child: Text('Applicants'),
                    ),
                    PopupMenuItem(value: 'view', child: Text('Preview')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'analytics', child: Text('Analytics')),
                    PopupMenuItem(value: 'promote', child: Text('Promote')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, {required bool isLast}) {
    return Expanded(
      child: JobsSurfaceCard(
        margin: EdgeInsets.only(right: isLast ? 0 : 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: JobsTheme.displayTitle),
            const SizedBox(height: 2),
            Text(label, style: JobsTheme.caption),
          ],
        ),
      ),
    );
  }
}

class _PromoteTierTile extends StatelessWidget {
  const _PromoteTierTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: theme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleSmall.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.caption.copyWith(
                        fontSize: 13,
                        height: 1.3,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textSecondary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
