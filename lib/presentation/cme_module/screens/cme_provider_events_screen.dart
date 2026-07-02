import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_detail_screen.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_event_card.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_shimmer_loader.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

enum CmeProviderEventsMode { all, open, closed }

class CmeProviderEventsScreen extends StatefulWidget {
  const CmeProviderEventsScreen({
    super.key,
    required this.mode,
    this.description,
    this.searchKeyword = '',
  });

  final CmeProviderEventsMode mode;
  final String? description;
  final String searchKeyword;

  @override
  State<CmeProviderEventsScreen> createState() => _CmeProviderEventsScreenState();
}

class CmeLearnerBrowseScreen extends StatefulWidget {
  const CmeLearnerBrowseScreen({
    super.key,
    required this.scope,
    this.segment = 'all',
    this.description,
    this.searchKeyword = '',
  });

  final String scope;
  final String segment;
  final String? description;
  final String searchKeyword;

  @override
  State<CmeLearnerBrowseScreen> createState() => _CmeLearnerBrowseScreenState();
}

class _CmeProviderEventsScreenState extends State<CmeProviderEventsScreen> {
  bool loading = true;
  bool loadingMore = false;
  String? error;
  String? cursor;
  List<CmeEventData> items = [];

  String get _status {
    switch (widget.mode) {
      case CmeProviderEventsMode.open:
        return 'open';
      case CmeProviderEventsMode.closed:
        return 'closed';
      case CmeProviderEventsMode.all:
        return 'all';
    }
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant CmeProviderEventsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchKeyword != widget.searchKeyword ||
        oldWidget.mode != widget.mode) {
      _load(reset: true);
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (loadingMore || cursor == null)) return;
    if (reset) {
      setState(() {
        loading = true;
        error = null;
        cursor = null;
        items = [];
        loadingMore = false;
      });
    } else {
      setState(() => loadingMore = true);
    }
    try {
      final page = await CmeNodeApiService.listEvents(
        scope: 'managed',
        status: _status,
        keyword: widget.searchKeyword,
        sort: widget.mode == CmeProviderEventsMode.open ? 'upcoming' : 'newest',
        cursor: reset ? null : cursor,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            items = page.items;
          } else {
            items = [...items, ...page.items];
          }
          cursor = page.nextCursor;
          loading = false;
          loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CmeEventsListBody(
      description: widget.description,
      loading: loading,
      loadingMore: loadingMore,
      error: error,
      items: items,
      hasMore: cursor != null,
      onRetry: () => _load(reset: true),
      onRefresh: () => _load(reset: true),
      onLoadMore: _load,
      showProviderMeta: true,
    );
  }
}

class _CmeLearnerBrowseScreenState extends State<CmeLearnerBrowseScreen> {
  bool loading = true;
  bool loadingMore = false;
  String? error;
  String? cursor;
  List<CmeEventData> items = [];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant CmeLearnerBrowseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchKeyword != widget.searchKeyword ||
        oldWidget.scope != widget.scope ||
        oldWidget.segment != widget.segment) {
      _load(reset: true);
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (loadingMore || cursor == null)) return;
    if (reset) {
      setState(() {
        loading = true;
        error = null;
        cursor = null;
        items = [];
        loadingMore = false;
      });
    } else {
      setState(() => loadingMore = true);
    }
    try {
      final page = await CmeNodeApiService.listEvents(
        scope: widget.scope,
        segment: widget.segment,
        keyword: widget.searchKeyword,
        cursor: reset ? null : cursor,
      );
      var nextItems = page.items;
      if (widget.segment != 'all') {
        nextItems = nextItems
            .where((e) => matchesLearningSegment(e, widget.segment))
            .toList();
      }
      if (mounted) {
        setState(() {
          if (reset) {
            items = nextItems;
          } else {
            items = [...items, ...nextItems];
          }
          cursor = page.nextCursor;
          loading = false;
          loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          loading = false;
          loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CmeEventsListBody(
      description: widget.description,
      loading: loading,
      loadingMore: loadingMore,
      error: error,
      items: items,
      hasMore: cursor != null,
      onRetry: () => _load(reset: true),
      onRefresh: () => _load(reset: true),
      onLoadMore: _load,
      showProviderMeta: false,
    );
  }
}

class _CmeEventsListBody extends StatelessWidget {
  const _CmeEventsListBody({
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.items,
    required this.hasMore,
    required this.onRetry,
    required this.onRefresh,
    required this.onLoadMore,
    required this.showProviderMeta,
    this.description,
  });

  final bool loading;
  final bool loadingMore;
  final String? error;
  final List<CmeEventData> items;
  final bool hasMore;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final Future<void> Function({bool reset}) onLoadMore;
  final bool showProviderMeta;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (loading && items.isEmpty) return const CmeShimmerLoader();
    if (error != null && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(error!, style: theme.bodySecondary, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 48, color: theme.textTertiary),
            const SizedBox(height: 12),
            Text('No activities found', style: theme.titleSmall),
            if (description != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(description!, style: theme.bodySecondary, textAlign: TextAlign.center),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: items.length + (hasMore ? 1 : 0) + (description != null ? 1 : 0),
        itemBuilder: (context, index) {
          var offset = 0;
          if (description != null) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(description!, style: theme.bodySecondary),
              );
            }
            offset = 1;
          }

          final itemIndex = index - offset;
          if (itemIndex >= items.length) {
            if (!loadingMore) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onLoadMore();
              });
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final event = items[itemIndex];
          return CmeEventCard(
            event: event,
            showProviderMeta: showProviderMeta,
            onTap: () => AppNavigator.push(
              context,
              CmeEventDetailScreen(eventId: event.id ?? ''),
            ),
          );
        },
      ),
    );
  }
}
