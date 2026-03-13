import 'package:doctak_app/data/models/cme/cme_analytics_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_analytics_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_analytics_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_analytics_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CmeAnalyticsScreen extends StatelessWidget {
  const CmeAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeAnalyticsBloc()
        ..add(CmeLoadCreditAnalyticsEvent())
        ..add(CmeLoadComplianceAnalyticsEvent())
        ..add(CmeLoadPerformanceAnalyticsEvent()),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: const Text('CME Analytics',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 18)),
        actions: [
          BlocBuilder<CmeAnalyticsBloc, CmeAnalyticsState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: state is CmeAnalyticsLoadingState
                    ? null
                    : () => context
                        .read<CmeAnalyticsBloc>()
                        .add(CmeExportAnalyticsEvent()),
                tooltip: 'Export PDF',
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<CmeAnalyticsBloc, CmeAnalyticsState>(
        listener: (context, state) {
          if (state is CmeAnalyticsExportedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Report exported successfully'),
                backgroundColor: const Color(0xFF34C759),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is CmeAnalyticsErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFFF3B30),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<CmeAnalyticsBloc>();

          if (state is CmeAnalyticsLoadingState &&
              bloc.creditAnalytics == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              bloc.add(CmeLoadCreditAnalyticsEvent());
              bloc.add(CmeLoadComplianceAnalyticsEvent());
              bloc.add(CmeLoadPerformanceAnalyticsEvent());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCreditOverview(theme, bloc.creditAnalytics),
                const SizedBox(height: 14),
                _buildCreditsByType(theme, bloc.creditAnalytics),
                const SizedBox(height: 14),
                _buildMonthlyChart(theme, bloc.creditAnalytics),
                const SizedBox(height: 14),
                _buildComplianceSection(theme, bloc.complianceAnalytics),
                const SizedBox(height: 14),
                _buildPerformanceSection(theme, bloc.performanceAnalytics),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreditOverview(OneUITheme theme, CmeCreditAnalytics? data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Credit Overview', style: theme.titleSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              _overviewStat(theme, '${data?.totalCredits ?? 0}',
                  'Total Credits', theme.primary),
              _overviewStat(theme, '${data?.requiredCredits ?? 0}',
                  'Required', const Color(0xFFFF9500)),
              _overviewStat(theme, '${data?.remainingCredits ?? 0}',
                  'Remaining', const Color(0xFFFF3B30)),
            ],
          ),
          if (data != null && data.requiredCredits != null && data.requiredCredits! > 0) ...[
            const SizedBox(height: 14),
            _progressWithLabel(
              theme,
              'Overall Progress',
              (data.totalCredits ?? 0) / data.requiredCredits!,
              '${(((data.totalCredits ?? 0) / data.requiredCredits!) * 100).clamp(0, 100).toStringAsFixed(0)}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _overviewStat(
      OneUITheme theme, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(label, style: theme.caption),
        ],
      ),
    );
  }

  Widget _buildCreditsByType(OneUITheme theme, CmeCreditAnalytics? data) {
    final types = data?.byType ?? [];
    if (types.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Credits by Type', style: theme.titleSmall),
          const SizedBox(height: 12),
          ...types.map((type) => _creditTypeRow(theme, type)),
        ],
      ),
    );
  }

  Widget _creditTypeRow(OneUITheme theme, CmeCreditByType type) {
    final color = _typeColor(type.type ?? '');
    final progress = type.percentage != null ? (type.percentage! / 100).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(type.type ?? '',
                    style: theme.bodyMedium),
              ),
              Text(
                '${type.credits ?? 0}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: theme.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'category 1':
      case 'ama pra category 1':
        return const Color(0xFF0A84FF);
      case 'category 2':
      case 'ama pra category 2':
        return const Color(0xFF5856D6);
      case 'self-assessment':
        return const Color(0xFFFF9500);
      case 'patient safety':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF34C759);
    }
  }

  Widget _buildMonthlyChart(OneUITheme theme, CmeCreditAnalytics? data) {
    final months = data?.byMonth ?? [];
    if (months.isEmpty) return const SizedBox();

    final maxCredits =
        months.fold<double>(0, (m, e) => (e.credits ?? 0) > m ? (e.credits ?? 0).toDouble() : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Credits', style: theme.titleSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final height = maxCredits > 0
                    ? ((m.credits ?? 0) / maxCredits) * 110
                    : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${m.credits ?? 0}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          height: height.clamp(2.0, 110.0),
                          decoration: BoxDecoration(
                            color: theme.primary,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _shortMonth(m.month ?? ''),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 8,
                            color: theme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _shortMonth(String month) {
    // Expects "2024-01" format
    final parts = month.split('-');
    if (parts.length < 2) return month;
    const months = [
      'J', 'F', 'M', 'A', 'M', 'J',
      'J', 'A', 'S', 'O', 'N', 'D'
    ];
    final idx = int.tryParse(parts[1]);
    if (idx != null && idx >= 1 && idx <= 12) return months[idx - 1];
    return month;
  }

  Widget _buildComplianceSection(
      OneUITheme theme, CmeComplianceAnalytics? data) {
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Compliance', style: theme.titleSmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: data.isCompliant == true
                      ? const Color(0xFF34C759).withValues(alpha: 0.1)
                      : const Color(0xFFFF3B30).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.isCompliant == true ? 'Compliant' : 'Non-Compliant',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: data.isCompliant == true
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF3B30),
                  ),
                ),
              ),
            ],
          ),
          if (data.complianceRate != null) ...[
            const SizedBox(height: 12),
            _progressWithLabel(
              theme,
              'Overall Compliance',
              (data.complianceRate! / 100).clamp(0.0, 1.0),
              '${data.complianceRate!.toStringAsFixed(0)}%',
            ),
          ],
          if (data.requirements != null && data.requirements!.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...data.requirements!.map((r) => _requirementRow(theme, r)),
          ],
        ],
      ),
    );
  }

  Widget _requirementRow(OneUITheme theme, CmeComplianceRequirement req) {
    final met = req.earned != null && req.required != null && req.earned! >= req.required!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: met ? const Color(0xFF34C759) : theme.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.name ?? '', style: theme.bodyMedium),
                if (req.earned != null && req.required != null)
                  Text(
                    '${req.earned}/${req.required} credits',
                    style: theme.caption,
                  ),
              ],
            ),
          ),
          if (req.deadline != null)
            Text(
              _formatDate(req.deadline!),
              style: theme.caption,
            ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      return '${d.month}/${d.day}/${d.year}';
    } catch (_) {
      return date;
    }
  }

  Widget _buildPerformanceSection(
      OneUITheme theme, CmePerformanceAnalytics? data) {
    if (data == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Metrics', style: theme.titleSmall),
          const SizedBox(height: 14),
          Row(
            children: [
              _performanceCard(theme, '${data.averageQuizScore?.toStringAsFixed(0) ?? 0}%',
                  'Avg Score', Icons.grade_outlined, theme.primary),
              const SizedBox(width: 10),
              _performanceCard(
                  theme,
                  '${data.eventsAttended ?? 0}',
                  'Attended',
                  Icons.event_available_outlined,
                  const Color(0xFF34C759)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _performanceCard(
                  theme,
                  '${data.eventsRegistered ?? 0}',
                  'Registered',
                  Icons.check_circle_outline,
                  const Color(0xFF5856D6)),
              const SizedBox(width: 10),
              _performanceCard(
                  theme,
                  '${data.quizzesPassed ?? 0}',
                  'Quizzes Passed',
                  Icons.quiz_outlined,
                  const Color(0xFFFF9500)),
            ],
          ),
          if (data.completionRate != null) ...[
            const SizedBox(height: 14),
            _progressWithLabel(
              theme,
              'Completion Rate',
              (data.completionRate! / 100).clamp(0.0, 1.0),
              '${data.completionRate!.toStringAsFixed(0)}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _performanceCard(
      OneUITheme theme, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(label, style: theme.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressWithLabel(
      OneUITheme theme, String label, double value, String valueText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.bodySecondary),
            Text(
              valueText,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: theme.divider,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
