import 'dart:async';

import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_detail_screen.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card_shimmer.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_motion.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_empty_state.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_filter_sheet.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:nb_utils/nb_utils.dart';

class JobsBrowseTab extends StatefulWidget {
  const JobsBrowseTab({
    super.key,
    required this.searchController,
    required this.filters,
    this.onFacetsUpdated,
    this.onFiltersCleared,
  });

  final TextEditingController searchController;
  final JobsFilterState filters;
  final ValueChanged<JobFacetsDto>? onFacetsUpdated;
  final VoidCallback? onFiltersCleared;

  @override
  State<JobsBrowseTab> createState() => _JobsBrowseTabState();
}

class _JobsBrowseTabState extends State<JobsBrowseTab>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  List<JobCardDto> _items = [];
  JobFacetsDto _facets = const JobFacetsDto();
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  List<String> _suggestions = [];
  Timer? _debounce;
  Timer? _reloadDebounce;
  int _suggestReqId = 0;
  String _lastKeyword = '';
  int _lastFilterStamp = 0;
  bool _loadQueued = false;

  @override
  bool get wantKeepAlive => true;

  int get _filterStamp => Object.hash(
        widget.filters.specialties.join(','),
        widget.filters.locations.join(','),
        widget.filters.jobTypes.join(','),
        widget.filters.applyTypes.join(','),
        widget.filters.postedWithin,
        widget.filters.sort,
        widget.filters.locationQ,
      );

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    widget.searchController.addListener(_onSearchControllerChanged);
    _lastKeyword = widget.searchController.text.trim();
    _lastFilterStamp = _filterStamp;
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(covariant JobsBrowseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onSearchControllerChanged);
      widget.searchController.addListener(_onSearchControllerChanged);
      _lastKeyword = widget.searchController.text.trim();
    }
    final stamp = _filterStamp;
    if (stamp != _lastFilterStamp) {
      _lastFilterStamp = stamp;
      _scheduleLoad();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _reloadDebounce?.cancel();
    widget.searchController.removeListener(_onSearchControllerChanged);
    _scroll.dispose();
    super.dispose();
  }

  void _scheduleLoad() {
    if (_loadQueued) return;
    _loadQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQueued = false;
      if (!mounted) return;
      _load(reset: true);
    });
  }

  void _onSearchControllerChanged() {
    if (!mounted) return;
    final query = widget.searchController.text.trim();
    _updateSuggestions(query);

    if (query == _lastKeyword) return;
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final next = widget.searchController.text.trim();
      if (next == _lastKeyword) return;
      _lastKeyword = next;
      _load(reset: true);
    });
  }

  void _updateSuggestions(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      if (_suggestions.isNotEmpty && mounted) {
        setState(() => _suggestions = []);
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final reqId = ++_suggestReqId;
      try {
        final results = await JobsNodeApiService.autocomplete(q: query);
        if (!mounted || reqId != _suggestReqId) return;
        setState(() => _suggestions = results.take(6).toList());
      } catch (_) {
        /* non-blocking */
      }
    });
  }

  void _selectSuggestion(String value) {
    widget.searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _suggestions = []);
    _lastKeyword = value.trim();
    _load(reset: true);
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    }
    try {
      final filters = widget.filters;
      final result = await JobsNodeApiService.browseJobs(
        keyword: widget.searchController.text.trim(),
        locationQ: filters.locationQ,
        specialties: filters.specialties,
        locations: filters.locations,
        jobTypes: filters.jobTypes,
        applyTypes: filters.applyTypes,
        postedWithin: filters.postedWithin,
        sort: filters.sort,
        page: _page,
        limit: 12,
      );
      if (!mounted) return;
      setState(() {
        _items = reset ? result.items : [..._items, ...result.items];
        _facets = result.facets;
        _hasMore = result.items.length >= 12 &&
            (_items.length < result.total || result.nextCursor != null);
        _loading = false;
        _loadingMore = false;
      });
      // Do not setState the parent during this frame — only cache facets.
      widget.onFacetsUpdated?.call(result.facets);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _loadingMore = true;
      _page += 1;
    });
    await _load(reset: false);
  }

  Future<void> _toggleBookmark(JobCardDto job) async {
    try {
      final booked = await JobsNodeApiService.toggleBookmark(job.id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((j) => j.id == job.id ? j.copyWith(isBookmarked: booked) : j)
            .toList();
      });
    } catch (e) {
      toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = OneUITheme.of(context);

    return ColoredBox(
      color: theme.scaffoldBackground,
      child: Column(
        children: [
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: theme.surfaceCardDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final suggestion in _suggestions)
                    InkWell(
                      onTap: () => _selectSuggestion(suggestion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              size: 16,
                              color: JobsTheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: JobsTheme.body,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_facets.total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_facets.total} open role${_facets.total == 1 ? '' : 's'}',
                  style: theme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const JobCardShimmerList()
                : _error != null
                    ? JobsEmptyState(
                        title: 'Couldn’t load jobs',
                        subtitle: _error,
                        actionLabel: 'Retry',
                        onAction: () => _load(reset: true),
                      )
                    : _items.isEmpty
                        ? JobsEmptyState(
                            title: 'No jobs found',
                            subtitle: 'Try different keywords or filters.',
                            actionLabel: 'Clear filters',
                            onAction: () {
                              widget.searchController.clear();
                              _lastKeyword = '';
                              widget.onFiltersCleared?.call();
                            },
                          )
                        : RefreshIndicator(
                            color: theme.primary,
                            onRefresh: () => _load(reset: true),
                            child: AnimationLimiter(
                              child: ListView.builder(
                                controller: _scroll,
                                padding: JobsTheme.listPadding(context, top: 4),
                                itemCount:
                                    _items.length + (_loadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _items.length) {
                                    return const JobCardShimmer();
                                  }
                                  final job = _items[index];
                                  return FeedCardEntrance(
                                    listIndex: index,
                                    child: JobCard(
                                      job: job,
                                      onTap: () async {
                                        await JobDetailScreen(jobId: job.id)
                                            .launch(context);
                                        if (mounted) _load(reset: true);
                                      },
                                      onBookmark: () => _toggleBookmark(job),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
