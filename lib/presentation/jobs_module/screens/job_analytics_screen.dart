import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card_shimmer.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_empty_state.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';

/// Recruiter-facing job performance analytics (views/clicks/funnel).
/// Requires a paid promotion tier — free-tier jobs see an upgrade prompt.
class JobAnalyticsScreen extends StatefulWidget {
  const JobAnalyticsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  final String jobId;
  final String jobTitle;

  @override
  State<JobAnalyticsScreen> createState() => _JobAnalyticsScreenState();
}

class _JobAnalyticsScreenState extends State<JobAnalyticsScreen> {
  bool _loading = true;
  String? _error;
  String? _gateMessage;
  JobAnalyticsDto? _analytics;

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
      final analytics = await JobsNodeApiService.getAnalytics(
        widget.jobId,
        onGated: (msg) => _gateMessage = msg,
      );
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Analytics',
        subtitle: widget.jobTitle,
        backgroundColor: theme.cardBackground,
        showShadow: false,
        titleColor: theme.textPrimary,
        titleFontWeight: FontWeight.w700,
      ),
      body: _loading
          ? const JobCardShimmerList()
          : _error != null
              ? JobsEmptyState(
                  title: 'Couldn’t load analytics',
                  subtitle: _error,
                  actionLabel: 'Retry',
                  onAction: _load,
                )
              : _gateMessage != null || _analytics == null
                  ? JobsEmptyState(
                      icon: Icons.bar_chart_rounded,
                      title: 'Analytics locked',
                      subtitle: _gateMessage ??
                          'Analytics require a paid promotion tier (Standard or Premium).',
                    )
                  : RefreshIndicator(
                      color: theme.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: JobsTheme.listPadding(
                          context,
                          top: 16,
                          horizontal: 16,
                        ),
                        children: [
                          _funnelCard(theme, _analytics!),
                          if (_analytics!.timeSeries.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _seriesCard(theme, _analytics!.timeSeries),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _funnelCard(OneUITheme theme, JobAnalyticsDto analytics) {
    final funnel = analytics.funnel;
    final items = <_MetricSpec>[
      _MetricSpec('Impressions', funnel.impressions, Icons.visibility_outlined),
      _MetricSpec(
        'Unique visitors',
        funnel.uniqueVisitors,
        Icons.person_outline_rounded,
      ),
      _MetricSpec('Apply clicks', funnel.applyClicks, Icons.ads_click_rounded),
      _MetricSpec(
        'Applications',
        funnel.applications,
        Icons.assignment_outlined,
      ),
      _MetricSpec(
        'Shortlisted',
        funnel.shortlisted,
        Icons.star_outline_rounded,
      ),
      _MetricSpec('Hired', funnel.hired, Icons.emoji_events_outlined),
    ];

    return AppSurfaceCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Performance funnel',
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (funnel.completionRate > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${funnel.completionRate.toStringAsFixed(1)}% completion',
                    style: theme.caption.copyWith(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final tileWidth = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final m in items)
                    SizedBox(
                      width: tileWidth,
                      child: _metricTile(theme, m),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metricTile(OneUITheme theme, _MetricSpec spec) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(spec.icon, size: 18, color: theme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${spec.value}',
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  spec.label,
                  style: theme.caption.copyWith(
                    color: theme.textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _seriesCard(
    OneUITheme theme,
    List<JobAnalyticsSeriesPointDto> series,
  ) {
    final maxVal = series
        .map(
          (p) => [p.views, p.clicks, p.applications].reduce((a, b) => a > b ? a : b),
        )
        .fold<int>(1, (a, b) => a > b ? a : b);
    final recent =
        series.length > 14 ? series.sublist(series.length - 14) : series;

    return AppSurfaceCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last ${recent.length} days',
            style: theme.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _legendDot(theme, theme.primary, 'Views'),
              _legendDot(theme, theme.success, 'Clicks'),
              _legendDot(theme, theme.warning, 'Applications'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in recent)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _bar(theme.primary, point.views, maxVal),
                          const SizedBox(width: 1.5),
                          _bar(theme.success, point.clicks, maxVal),
                          const SizedBox(width: 1.5),
                          _bar(theme.warning, point.applications, maxVal),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color, int value, int maxVal) {
    final height = maxVal == 0 ? 4.0 : (value / maxVal) * 120 + 4;
    return Container(
      width: 5,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _legendDot(OneUITheme theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.caption.copyWith(color: theme.textSecondary),
        ),
      ],
    );
  }
}

class _MetricSpec {
  const _MetricSpec(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}
