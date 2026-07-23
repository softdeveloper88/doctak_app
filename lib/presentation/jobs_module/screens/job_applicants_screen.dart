import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_cv_viewer_screen.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/applicant_stage_sheet.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card_shimmer.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_chips.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_display_utils.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_empty_state.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_sheet_shell.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

enum _AppliedWithin { all, today, week, month }

enum _ApplicantSort { newest, oldest, aiScore }

/// Recruiter applicants — pipeline tabs + review / advance actions.
class JobApplicantsScreen extends StatefulWidget {
  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  final String jobId;
  final String jobTitle;

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  static const _stages = JobStageLabels.order;

  int _selectedIndex = 0;
  JobApplicantsResult? _result;
  bool _loading = true;
  String? _error;
  Map<String, ApplicantAnalysisResultDto> _ranking = {};
  bool _analyzing = false;
  String? _lastAnalyzedAt;
  _AppliedWithin _within = _AppliedWithin.all;
  _ApplicantSort _sort = _ApplicantSort.newest;

  String get _activeStage => _stages[_selectedIndex.clamp(0, _stages.length - 1)];

  @override
  void initState() {
    super.initState();
    _load();
    _loadRankingState();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await JobsNodeApiService.getApplicants(widget.jobId);
      if (!mounted) return;
      setState(() {
        _result = result;
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

  bool _matchesDateFilter(JobApplicantDto a) {
    if (_within == _AppliedWithin.all) return true;
    final raw = a.appliedAt;
    if (raw == null || raw.isEmpty) return false;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return false;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    switch (_within) {
      case _AppliedWithin.today:
        return !dt.isBefore(startOfToday);
      case _AppliedWithin.week:
        return !dt.isBefore(startOfToday.subtract(const Duration(days: 7)));
      case _AppliedWithin.month:
        return !dt.isBefore(startOfToday.subtract(const Duration(days: 30)));
      case _AppliedWithin.all:
        return true;
    }
  }

  List<JobApplicantDto> _forStage(String stage) {
    final result = _result;
    if (result == null) return const [];
    final items = result.stages[stage]
            ?.where(_matchesDateFilter)
            .toList(growable: true) ??
        <JobApplicantDto>[];

    items.sort((a, b) {
      switch (_sort) {
        case _ApplicantSort.aiScore:
          final scoreA = _ranking[a.applicationId]?.overallScore ??
              a.aiMatchScore ??
              -1;
          final scoreB = _ranking[b.applicationId]?.overallScore ??
              b.aiMatchScore ??
              -1;
          final cmp = scoreB.compareTo(scoreA);
          if (cmp != 0) return cmp;
          break;
        case _ApplicantSort.oldest:
          return _compareApplied(a, b);
        case _ApplicantSort.newest:
          return _compareApplied(b, a);
      }
      if (_ranking.isNotEmpty) {
        final scoreA = _ranking[a.applicationId]?.overallScore;
        final scoreB = _ranking[b.applicationId]?.overallScore;
        if (scoreA != null || scoreB != null) {
          if (scoreA == null) return 1;
          if (scoreB == null) return -1;
          final cmp = scoreB.compareTo(scoreA);
          if (cmp != 0) return cmp;
        }
      }
      return _compareApplied(b, a);
    });
    return items;
  }

  int _compareApplied(JobApplicantDto a, JobApplicantDto b) {
    final da = DateTime.tryParse(a.appliedAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final db = DateTime.tryParse(b.appliedAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return da.compareTo(db);
  }

  int _stageCount(String stage) {
    final result = _result;
    if (result == null) return 0;
    return result.stages[stage]?.where(_matchesDateFilter).length ?? 0;
  }

  Future<void> _loadRankingState() async {
    try {
      final state =
          await JobsNodeApiService.getApplicantAnalysisState(widget.jobId);
      if (!mounted) return;
      setState(() {
        _ranking = {for (final r in state.results) r.applicationId: r};
        _lastAnalyzedAt = state.lastAnalyzedAt;
      });
    } catch (_) {
      /* ranking is optional */
    }
  }

  Future<void> _runRanking() async {
    setState(() => _analyzing = true);
    try {
      final state =
          await JobsNodeApiService.runApplicantAnalysis(widget.jobId);
      if (!mounted) return;
      setState(() {
        _ranking = {for (final r in state.results) r.applicationId: r};
        _lastAnalyzedAt = state.lastAnalyzedAt;
        _analyzing = false;
        _sort = _ApplicantSort.aiScore;
      });
      toast('AI ranking updated for ${state.results.length} applicant(s)');
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      toast(e.toString());
    }
  }

  Future<void> _applyStage(JobApplicantDto applicant, String next) async {
    if (next == applicant.stage) return;
    try {
      await JobsNodeApiService.updateApplicationStage(
        applicationId: applicant.applicationId,
        stage: next,
      );
      toast('Moved to ${JobStageLabels.label(next)}');
      final nextIdx = _stages.indexOf(next);
      if (nextIdx >= 0) {
        setState(() => _selectedIndex = nextIdx);
      }
      await _load();
    } catch (e) {
      toast(e.toString());
    }
  }

  Future<void> _moveStage(JobApplicantDto applicant) async {
    final next = await showApplicantStageSheet(
      context: context,
      applicant: applicant,
    );
    if (next == null || next == applicant.stage) return;
    await _applyStage(applicant, next);
  }

  Future<void> _advance(JobApplicantDto applicant) async {
    final next = jobNextPipelineStage(applicant.stage);
    if (next == null) {
      await _moveStage(applicant);
      return;
    }
    await _applyStage(applicant, next);
  }

  void _showRankingInsight(JobApplicantDto applicant) {
    final result = _ranking[applicant.applicationId];
    if (result == null) return;
    final theme = OneUITheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobsSheetShell(
        title: '${applicant.name} · AI fit',
        subtitle: 'Match analysis',
        leading: JobsSheetLeadingIcon(
          icon: Icons.auto_awesome_rounded,
          color: theme.primary,
        ),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8, top: 4),
          child: JobChip(
            label: '${result.overallScore}% · ${result.fitLabel}',
            tone: result.overallScore >= 75
                ? JobChipTone.success
                : JobChipTone.primary,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.summary.isNotEmpty)
              Text(result.summary, style: theme.bodySecondary),
            if (result.strengths.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Strengths',
                style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...result.strengths.map(
                (s) => _BulletRow(
                  icon: Icons.check_circle_rounded,
                  color: theme.success,
                  text: s,
                ),
              ),
            ],
            if (result.gaps.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Gaps',
                style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...result.gaps.map(
                (g) => _BulletRow(
                  icon: Icons.error_outline_rounded,
                  color: theme.warning,
                  text: g,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openCv(JobApplicantDto applicant) async {
    await openJobCvInApp(
      context,
      cvUrl: applicant.cvUrl,
      title: '${applicant.name} · CV',
      cvPreview: applicant.cvPreview,
    );
  }

  Future<void> _reviewApplicant(JobApplicantDto applicant) async {
    final theme = OneUITheme.of(context);
    final ranked = _ranking[applicant.applicationId];
    final next = jobNextPipelineStage(applicant.stage);
    final avatarUrl = applicant.avatar ?? '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JobsSheetShell(
        title: applicant.name,
        subtitle: applicant.specialty ?? 'Applicant review',
        leading: ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: AppCachedNetworkImage(
              imageUrl: avatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: theme.avatarBackground,
                alignment: Alignment.center,
                child: Text(
                  applicant.name.isNotEmpty ? applicant.name[0] : '?',
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                JobChip(
                  label: JobStageLabels.label(applicant.stage),
                  tone: JobChipTone.primary,
                ),
                if (applicant.appliedAt != null)
                  JobChip(
                    label:
                        'Applied ${JobDisplayUtils.relativePosted(applicant.appliedAt)}',
                    tone: JobChipTone.neutral,
                  ),
                if (ranked != null)
                  JobChip(
                    label: '${ranked.overallScore}% · ${ranked.fitLabel}',
                    tone: ranked.overallScore >= 75
                        ? JobChipTone.success
                        : JobChipTone.primary,
                  ),
              ],
            ),
            if (applicant.extraFieldEntries.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Application answers',
                style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...applicant.extraFieldEntries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          e.key,
                          style: theme.caption.copyWith(
                            color: theme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(e.value, style: theme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openCv(applicant);
              },
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('View CV'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            if (ranked != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showRankingInsight(applicant);
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('AI fit details'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: theme.primary,
                  side: BorderSide(color: theme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (next != null)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _advance(applicant);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text('Advance to ${JobStageLabels.label(next)}'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _moveStage(applicant);
              },
              child: const Text('Change stage…'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterSortSheet() async {
    final theme = OneUITheme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var within = _within;
        var sort = _sort;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return JobsSheetShell(
              title: 'Filter & sort',
              subtitle: 'Applied date and order',
              leading: JobsSheetLeadingIcon(
                icon: Icons.tune_rounded,
                color: theme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Applied within',
                    style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in _AppliedWithin.values)
                        ChoiceChip(
                          label: Text(_withinLabel(option)),
                          selected: within == option,
                          onSelected: (_) => setSheet(() => within = option),
                          selectedColor: theme.accentSoft,
                          labelStyle: theme.bodySecondary.copyWith(
                            fontWeight: FontWeight.w600,
                            color: within == option
                                ? theme.primary
                                : theme.textPrimary,
                          ),
                          side: BorderSide(
                            color: within == option
                                ? theme.primary.withValues(alpha: 0.35)
                                : theme.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Sort by',
                    style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final option in _ApplicantSort.values)
                    Material(
                      color: sort == option
                          ? theme.primary.withValues(alpha: 0.08)
                          : theme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      child: RadioListTile<_ApplicantSort>(
                        value: option,
                        groupValue: sort,
                        onChanged: (v) {
                          if (v != null) setSheet(() => sort = v);
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(_sortLabel(option)),
                        activeColor: theme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _within = within;
                        _sort = sort;
                      });
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: theme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _withinLabel(_AppliedWithin v) {
    switch (v) {
      case _AppliedWithin.all:
        return 'All time';
      case _AppliedWithin.today:
        return 'Today';
      case _AppliedWithin.week:
        return 'Last 7 days';
      case _AppliedWithin.month:
        return 'Last 30 days';
    }
  }

  String _sortLabel(_ApplicantSort v) {
    switch (v) {
      case _ApplicantSort.newest:
        return 'Newest applications';
      case _ApplicantSort.oldest:
        return 'Oldest applications';
      case _ApplicantSort.aiScore:
        return 'AI match score';
    }
  }

  int get _activeFilterCount =>
      (_within != _AppliedWithin.all ? 1 : 0) +
      (_sort != _ApplicantSort.newest ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final tabLabels = [
      for (final stage in _stages)
        '${JobStageLabels.shortLabel(stage)} (${_stageCount(stage)})',
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Applicants',
        subtitle: widget.jobTitle,
        backgroundColor: theme.cardBackground,
        showShadow: false,
        titleColor: theme.textPrimary,
        titleFontWeight: FontWeight.w700,
        titleFontSize: 20,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Badge(
              isLabelVisible: _activeFilterCount > 0,
              backgroundColor: theme.primary,
              label: Text('$_activeFilterCount'),
              child: IconButton(
                tooltip: 'Filter & sort',
                onPressed: _loading ? null : _showFilterSortSheet,
                icon: Icon(Icons.tune_rounded, color: theme.primary),
              ),
            ),
          ),
          IconButton(
            onPressed: _analyzing || _loading ? null : _runRanking,
            tooltip:
                _lastAnalyzedAt != null ? 'Re-run AI ranking' : 'Rank with AI',
            icon: _analyzing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  )
                : Icon(Icons.auto_awesome_rounded, color: theme.primary),
          ),
        ],
      ),
      body: _loading
          ? const JobCardShimmerList()
          : _error != null
              ? JobsEmptyState(
                  title: 'Couldn’t load applicants',
                  subtitle: _error,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : Column(
                  children: [
                    OneUIProfileTabBar(
                      tabs: tabLabels,
                      selectedIndex: _selectedIndex,
                      onSelected: (i) => setState(() => _selectedIndex = i),
                      expandTabs: false,
                      showBottomBorder: true,
                      backgroundColor: theme.cardBackground,
                      matchAppBar: false,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tabSpacing: 20,
                    ),
                    Expanded(
                      child: _stageList(theme, _forStage(_activeStage)),
                    ),
                  ],
                ),
    );
  }

  Widget _stageList(OneUITheme theme, List<JobApplicantDto> items) {
    if (items.isEmpty) {
      return JobsEmptyState(
        title: 'No applicants here',
        subtitle: _within == _AppliedWithin.all
            ? 'Nothing in this stage yet.'
            : 'Try widening the applied-date filter.',
        icon: Icons.inbox_outlined,
        actionLabel: _within != _AppliedWithin.all ? 'Clear date filter' : null,
        onAction: _within != _AppliedWithin.all
            ? () => setState(() => _within = _AppliedWithin.all)
            : null,
      );
    }
    return RefreshIndicator(
      color: theme.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: JobsTheme.listPadding(context, top: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final a = items[index];
          final ranked = _ranking[a.applicationId];
          final avatarUrl = a.avatar ?? '';
          return AppSurfaceCard.listItem(
            onTap: () => _reviewApplicant(a),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ranked != null && ranked.rank <= 3)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 2),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.warning.withValues(alpha: 0.15),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${ranked.rank}',
                            style: theme.caption.copyWith(
                              color: theme.warning,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ClipOval(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: AppCachedNetworkImage(
                          imageUrl: avatarUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: theme.avatarBackground,
                            alignment: Alignment.center,
                            child: Text(
                              a.name.isNotEmpty ? a.name[0] : '?',
                              style: theme.titleSmall
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name,
                            style: theme.titleSmall
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (a.specialty != null)
                            Text(
                              a.specialty!,
                              style: theme.caption
                                  .copyWith(color: theme.textSecondary),
                            ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              JobChip(
                                label: JobStageLabels.label(a.stage),
                                tone: JobChipTone.primary,
                              ),
                              if (ranked != null)
                                JobChip(
                                  label:
                                      '${ranked.overallScore}% · ${ranked.fitLabel}',
                                  tone: ranked.overallScore >= 75
                                      ? JobChipTone.success
                                      : JobChipTone.primary,
                                )
                              else if (a.aiMatchScore != null)
                                JobChip(
                                  label: '${a.aiMatchScore!.round()}% match',
                                  tone: JobChipTone.success,
                                ),
                              if (a.appliedAt != null)
                                JobChip(
                                  label: JobDisplayUtils.relativePosted(
                                    a.appliedAt,
                                  ),
                                  tone: JobChipTone.neutral,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openCv(a),
                        icon: const Icon(Icons.description_outlined, size: 16),
                        label: const Text('CV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primary,
                          side: BorderSide(color: theme.border),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _moveStage(a),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('Move'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textPrimary,
                          side: BorderSide(color: theme.border),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: theme.bodyMedium)),
        ],
      ),
    );
  }
}
