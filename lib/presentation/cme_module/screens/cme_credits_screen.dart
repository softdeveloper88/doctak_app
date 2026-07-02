import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_credit_history_model.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CmeCreditsScreen extends StatefulWidget {
  const CmeCreditsScreen({super.key});

  @override
  State<CmeCreditsScreen> createState() => _CmeCreditsScreenState();
}

class _CmeCreditsScreenState extends State<CmeCreditsScreen> {
  bool loading = true;
  String? error;
  List<CmeCreditHistoryItem> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      items = await CmeNodeApiService.getCreditHistory();
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!, style: theme.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu_outlined, size: 48, color: theme.textTertiary),
            const SizedBox(height: 12),
            Text('No credit history yet', style: theme.titleSmall),
            const SizedBox(height: 4),
            Text('Complete CME activities to earn credits.',
                style: theme.bodySecondary),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: theme.cardDecoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: theme.radiusM,
                  ),
                  child: Icon(Icons.school_outlined, color: theme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.eventTitle, style: theme.titleSmall, maxLines: 2),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(item.earnedAt),
                        style: theme.caption,
                      ),
                      if (item.creditType != null) ...[
                        const SizedBox(height: 2),
                        Text(item.creditType!, style: theme.caption),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${item.credits} cr',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat.yMMMd().format(dt.toLocal());
  }
}
