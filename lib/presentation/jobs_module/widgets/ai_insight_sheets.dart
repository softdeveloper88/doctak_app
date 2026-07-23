import 'dart:io';

import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_chips.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_sheet_shell.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Candidate-facing AI insight sheets: "AI Brief" (promoted-job summary) and
/// "Analyze My Fit" (candidate match preview before applying).
Future<void> showAiBriefSheet(BuildContext context, String jobId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AiBriefSheet(jobId: jobId),
  );
}

Future<void> showFitPreviewSheet(BuildContext context, JobDetailDto job) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FitPreviewSheet(job: job),
  );
}

class _AiBriefSheet extends StatefulWidget {
  const _AiBriefSheet({required this.jobId});

  final String jobId;

  @override
  State<_AiBriefSheet> createState() => _AiBriefSheetState();
}

class _AiBriefSheetState extends State<_AiBriefSheet> {
  bool _loading = true;
  String? _gateMessage;
  String? _error;
  JobAiBriefDto? _brief;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _gateMessage = null;
    });
    try {
      final brief = await JobsNodeApiService.getAiBrief(
        widget.jobId,
        onGated: (msg) => _gateMessage = msg,
      );
      if (!mounted) return;
      setState(() {
        _brief = brief;
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

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return JobsSheetShell(
      title: 'AI Brief',
      leading: const JobsSheetLeadingIcon(icon: Icons.auto_awesome_rounded),
      maxHeightFactor: 0.85,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null || _gateMessage != null
              ? _InsightMessage(
                  icon: Icons.info_outline_rounded,
                  text: _error ?? _gateMessage!,
                )
              : _brief == null
                  ? const _InsightMessage(
                      icon: Icons.info_outline_rounded,
                      text: 'No brief available for this job right now.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _brief!.shortDescription,
                          style: theme.bodyMedium,
                        ),
                        if (_brief!.highlights.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Highlights',
                            style: theme.bodySecondary
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ..._brief!.highlights
                              .map((h) => _BulletLine(text: h, theme: theme)),
                        ],
                        if (_brief!.suggestedQuestions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Questions to ask',
                            style: theme.bodySecondary
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ..._brief!.suggestedQuestions
                              .map((q) => _BulletLine(text: q, theme: theme)),
                        ],
                        if (_brief!.nextStep.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline_rounded,
                                    size: 18, color: theme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _brief!.nextStep,
                                    style: theme.bodySecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
    );
  }
}

class _FitPreviewSheet extends StatefulWidget {
  const _FitPreviewSheet({required this.job});

  final JobDetailDto job;

  @override
  State<_FitPreviewSheet> createState() => _FitPreviewSheetState();
}

class _FitPreviewSheetState extends State<_FitPreviewSheet> {
  bool _loading = false;
  String? _error;
  JobAiMatchDto? _match;
  File? _pickedCv;

  String? get _defaultCvPath {
    final cvs = widget.job.savedCvs;
    if (cvs.isEmpty) return null;
    return cvs.firstWhere((c) => c.isDefault, orElse: () => cvs.first).path;
  }

  Future<void> _pickCv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );
      final path = result?.files.single.path;
      if (path != null) {
        setState(() => _pickedCv = File(path));
      }
    } catch (e) {
      toast('Could not open file picker: $e');
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final match = await JobsNodeApiService.getFitPreview(
        jobId: widget.job.id,
        existingCvPath: _pickedCv == null ? _defaultCvPath : null,
        cvFile: _pickedCv,
      );
      if (!mounted) return;
      setState(() {
        _match = match;
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

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final hasCv = _pickedCv != null || _defaultCvPath != null;

    return JobsSheetShell(
      title: 'Analyze My Fit',
      leading: const JobsSheetLeadingIcon(icon: Icons.insights_rounded),
      maxHeightFactor: 0.85,
      child: _match != null
          ? _FitResultView(match: _match!, theme: theme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let AI compare your profile & CV against this role and highlight strengths, gaps, and next steps.',
                  style: theme.bodySecondary,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickCv,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description_outlined,
                            size: 18, color: theme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pickedCv != null
                                ? _pickedCv!.path.split('/').last
                                : _defaultCvPath != null
                                    ? 'Using your saved CV'
                                    : 'Upload a CV (optional)',
                            style: theme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Change',
                          style: theme.bodySecondary
                              .copyWith(color: theme.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _InsightMessage(icon: Icons.error_outline_rounded, text: _error!),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _analyze,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(_loading ? 'Analyzing…' : 'Analyze my fit'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                if (!hasCv) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tip: add a CV for a more accurate match score.',
                    style: theme.caption.copyWith(color: theme.textSecondary),
                  ),
                ],
              ],
            ),
    );
  }
}

class _FitResultView extends StatelessWidget {
  const _FitResultView({required this.match, required this.theme});

  final JobAiMatchDto match;
  final OneUITheme theme;

  @override
  Widget build(BuildContext context) {
    final score = match.matchScore;
    final color = score == null
        ? theme.textSecondary
        : score >= 75
            ? theme.success
            : score >= 50
                ? theme.warning
                : theme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                score != null ? '$score%' : '—',
                style: theme.titleSmall.copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (match.matchLabel != null)
                    JobChip(
                      label: match.matchLabel!,
                      tone: score != null && score >= 75
                          ? JobChipTone.success
                          : JobChipTone.primary,
                    ),
                  if (match.summary != null) ...[
                    const SizedBox(height: 6),
                    Text(match.summary!, style: theme.bodySecondary),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (match.strengths.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Strengths', style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...match.strengths.map((s) => _BulletLine(text: s, theme: theme, positive: true)),
        ],
        if (match.gaps.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Gaps to address', style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...match.gaps.map((g) => _BulletLine(text: g, theme: theme, positive: false)),
        ],
        if (match.candidateActions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Suggested next steps', style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...match.candidateActions.map((a) => _BulletLine(text: a, theme: theme)),
        ],
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, required this.theme, this.positive});

  final String text;
  final OneUITheme theme;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    final color = positive == null
        ? theme.textSecondary
        : positive!
            ? theme.success
            : theme.warning;
    final icon = positive == null
        ? Icons.circle
        : positive!
            ? Icons.check_circle_rounded
            : Icons.error_outline_rounded;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(icon, size: positive == null ? 6 : 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.bodyMedium)),
        ],
      ),
    );
  }
}

class _InsightMessage extends StatelessWidget {
  const _InsightMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.bodySecondary)),
        ],
      ),
    );
  }
}
