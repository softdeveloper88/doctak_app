import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_cv_viewer_screen.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_detail_screen.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_application_stage_stepper.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card_shimmer.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_chips.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_display_utils.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_empty_state.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_search_header.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class MyApplicationDetailScreen extends StatefulWidget {
  const MyApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  State<MyApplicationDetailScreen> createState() =>
      _MyApplicationDetailScreenState();
}

class _MyApplicationDetailScreenState extends State<MyApplicationDetailScreen> {
  bool _loading = true;
  String? _error;
  JobApplicantDto? _applicant;
  JobCardDto? _job;

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
      final data =
          await JobsNodeApiService.getApplicationDetail(widget.applicationId);
      if (!mounted) return;
      final applicantJson = data['applicant'];
      final jobJson = data['job'];
      setState(() {
        _applicant = applicantJson is Map
            ? JobApplicantDto.fromJson(Map<String, dynamic>.from(applicantJson))
            : null;
        _job = jobJson is Map
            ? JobCardDto.fromJson(Map<String, dynamic>.from(jobJson))
            : null;
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

  Future<void> _withdraw() async {
    final ok = await showOneUIConfirmDialog(
      context,
      title: 'Withdraw application?',
      subtitle:
          'This removes your application. You can apply again later if the job is still open.',
      confirmLabel: 'Withdraw',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (!ok) return;
    try {
      await JobsNodeApiService.withdrawApplication(widget.applicationId);
      toast('Application withdrawn');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final applicant = _applicant;
    final job = _job;
    final canWithdraw = applicant != null &&
        applicant.stage != 'accepted' &&
        applicant.stage != 'rejected';

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Application',
        subtitle: job?.title,
        backgroundColor: theme.cardBackground,
        showShadow: false,
      ),
      bottomNavigationBar: applicant == null || _loading || _error != null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  border: Border(
                    top: BorderSide(color: theme.border),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (job != null)
                      SizedBox(
                        width: double.infinity,
                        height: kOneUIButtonHeight,
                        child: OutlinedButton(
                          onPressed: () =>
                              JobDetailScreen(jobId: job.id).launch(context),
                          style: OneUIButtons.outlined(theme),
                          child: const Text('View job posting'),
                        ),
                      ),
                    if (job != null && canWithdraw) const SizedBox(height: 4),
                    if (canWithdraw)
                      SizedBox(
                        width: double.infinity,
                        height: kOneUIButtonHeight,
                        child: TextButton(
                          onPressed: _withdraw,
                          style: OneUIButtons.text(theme, destructive: true),
                          child: const Text('Withdraw application'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 12),
              physics: NeverScrollableScrollPhysics(),
              child: JobCardShimmer(),
            )
          : _error != null
              ? JobsEmptyState(
                  title: 'Couldn’t load application',
                  subtitle: _error,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : applicant == null
                  ? const JobsEmptyState(title: 'Not found')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      children: [
                        JobsSurfaceCard(
                          margin: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              JobChip(
                                label: JobStageLabels.label(applicant.stage),
                                tone: jobStageChipTone(applicant.stage),
                                dense: false,
                              ),
                              const SizedBox(height: 12),
                              Text(job?.title ?? 'Job', style: JobsTheme.title),
                              Text(
                                job?.companyName ?? '',
                                style: JobsTheme.bodyMuted,
                              ),
                              if (applicant.appliedAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Applied ${JobDisplayUtils.friendlyDateTime(applicant.appliedAt)}',
                                  style: JobsTheme.caption,
                                ),
                              ],
                              if (applicant.aiMatchScore != null) ...[
                                const SizedBox(height: 8),
                                JobChip(
                                  label:
                                      'AI match ${applicant.aiMatchScore!.round()}%',
                                  tone: JobChipTone.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        JobsSurfaceCard(
                          margin: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const JobSectionLabel('Pipeline progress'),
                              const SizedBox(height: 14),
                              JobApplicationStageStepper(
                                stage: applicant.stage,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (applicant.extraFieldEntries.isNotEmpty)
                          JobsSurfaceCard(
                            margin: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const JobSectionLabel('Your answers'),
                                const SizedBox(height: 14),
                                for (var i = 0;
                                    i < applicant.extraFieldEntries.length;
                                    i++) ...[
                                  _AnswerEntry(
                                    label: JobDisplayUtils.humanizeFieldLabel(
                                      applicant.extraFieldEntries[i].key,
                                    ),
                                    value: JobDisplayUtils.formatAnswerValue(
                                      applicant.extraFieldEntries[i].value,
                                    ),
                                  ),
                                  if (i <
                                      applicant.extraFieldEntries.length - 1)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(
                                        height: 1,
                                        color: JobsTheme.surfaceContainer,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (applicant.cvUrl != null ||
                            applicant.cvPreview != null)
                          JobsSurfaceCard(
                            margin: EdgeInsets.zero,
                            onTap: () => openJobCvInApp(
                              context,
                              cvUrl: applicant.cvUrl,
                              title: 'Submitted CV',
                              cvPreview: applicant.cvPreview,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  color: JobsTheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    applicant.cvUrl != null
                                        ? 'Open submitted CV'
                                        : (applicant.cvPreview ?? 'CV'),
                                    style: JobsTheme.body,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}

class _AnswerEntry extends StatefulWidget {
  const _AnswerEntry({required this.label, required this.value});

  final String label;
  final String value;

  static const int _collapsedLength = 280;

  @override
  State<_AnswerEntry> createState() => _AnswerEntryState();
}

class _AnswerEntryState extends State<_AnswerEntry> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final value = JobDisplayUtils.formatAnswerValue(widget.value).trim();
    final chips = JobDisplayUtils.answerChips(value);
    final useChips = chips.length > 1;
    final isLong = !useChips && value.length > _AnswerEntry._collapsedLength;
    final displayValue = isLong && !_expanded
        ? '${value.substring(0, _AnswerEntry._collapsedLength).trimRight()}…'
        : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: JobsTheme.label.copyWith(
            fontWeight: FontWeight.w700,
            color: JobsTheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        if (value.isEmpty)
          Text('—', style: JobsTheme.bodyMuted)
        else if (useChips)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in chips)
                JobChip(label: chip, dense: false, outlined: true),
            ],
          )
        else
          SelectableText(
            displayValue,
            style: JobsTheme.body.copyWith(
              height: 1.5,
              color: JobsTheme.onSurface,
            ),
          ),
        if (isLong)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Show more',
                style: JobsTheme.label.copyWith(
                  color: JobsTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
