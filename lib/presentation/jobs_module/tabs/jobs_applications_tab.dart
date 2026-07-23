import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_detail_screen.dart';
import 'package:doctak_app/presentation/jobs_module/screens/my_application_detail_screen.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card_shimmer.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_chips.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_display_utils.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_empty_state.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/one_ui_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class JobsApplicationsTab extends StatefulWidget {
  const JobsApplicationsTab({super.key});

  @override
  State<JobsApplicationsTab> createState() => _JobsApplicationsTabState();
}

class _JobsApplicationsTabState extends State<JobsApplicationsTab>
    with AutomaticKeepAliveClientMixin {
  List<JobApplicationDto> _items = [];
  bool _loading = true;
  String? _error;

  static const _past = {'accepted', 'rejected'};

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
      final items = await JobsNodeApiService.getMyApplications();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _withdraw(JobApplicationDto app) async {
    final ok = await showOneUIConfirmDialog(
      context,
      title: 'Withdraw application?',
      subtitle:
          'This removes your application for ${app.job.title}. You can apply again later if the job is still open.',
      confirmLabel: 'Withdraw',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (!ok) return;
    try {
      await JobsNodeApiService.withdrawApplication(app.applicationId);
      toast('Application withdrawn');
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
        title: 'Couldn’t load applications',
        subtitle: _error,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return const JobsEmptyState(
        title: 'No applications yet',
        subtitle: 'Roles you apply to will appear here with status updates.',
        icon: Icons.send_outlined,
      );
    }

    final active = _items.where((a) => !_past.contains(a.status)).toList();
    final past = _items.where((a) => _past.contains(a.status)).toList();

    return ColoredBox(
      color: theme.scaffoldBackground,
      child: RefreshIndicator(
        color: theme.primary,
        onRefresh: _load,
        child: ListView(
          padding: JobsTheme.listPadding(context, top: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '${_items.length} application${_items.length == 1 ? '' : 's'}',
                style: theme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
            ),
            if (active.isNotEmpty) ...active.map(_card),
            if (past.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Past',
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              ...past.map(_card),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(JobApplicationDto app) {
    return JobCard(
      job: app.job.copyWith(isApplied: true),
      showBookmark: false,
      statusLabel: JobStageLabels.label(app.status),
      statusTone: jobStageChipTone(app.status),
      footerLabel: app.appliedAt != null
          ? 'Applied ${JobDisplayUtils.relativePosted(app.appliedAt)}'
          : null,
      onTap: () async {
        final changed = await MyApplicationDetailScreen(
          applicationId: app.applicationId,
        ).launch(context);
        if (changed == true) _load();
      },
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'withdraw') _withdraw(app);
          if (v == 'open') {
            JobDetailScreen(jobId: app.job.id).launch(context);
          }
          if (v == 'detail') {
            MyApplicationDetailScreen(applicationId: app.applicationId)
                .launch(context)
                .then((changed) {
              if (changed == true) _load();
            });
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'detail',
            child: Text('Application details'),
          ),
          const PopupMenuItem(value: 'open', child: Text('View job')),
          if (!_past.contains(app.status))
            const PopupMenuItem(
              value: 'withdraw',
              child: Text('Withdraw'),
            ),
        ],
      ),
    );
  }
}
