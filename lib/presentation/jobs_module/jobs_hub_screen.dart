import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/data/apiClient/jobs/jobs_node_api_service.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/screens/job_post_wizard_screen.dart';
import 'package:doctak_app/presentation/jobs_module/tabs/jobs_applications_tab.dart';
import 'package:doctak_app/presentation/jobs_module/tabs/jobs_browse_tab.dart';
import 'package:doctak_app/presentation/jobs_module/tabs/jobs_manage_tab.dart';
import 'package:doctak_app/presentation/jobs_module/tabs/jobs_saved_tab.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_active_filters.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_filter_sheet.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card_shimmer.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

enum _JobsHubTab { browse, saved, applications, manage }

/// Jobs module hub — Browse / Saved / Applications / Manage.
class JobsHubScreen extends StatefulWidget {
  const JobsHubScreen({super.key, this.initialTab = 0, this.manageJobId});

  final int initialTab;
  final String? manageJobId;

  @override
  State<JobsHubScreen> createState() => _JobsHubScreenState();
}

class _JobsHubScreenState extends State<JobsHubScreen> {
  final _searchCtrl = TextEditingController();

  JobCapabilitiesDto _caps = const JobCapabilitiesDto();
  bool _loadingCaps = true;
  bool _isSearchVisible = false;
  JobsFilterState _filters = JobsFilterState();
  JobFacetsDto _facets = const JobFacetsDto();
  _JobsHubTab _activeTab = _JobsHubTab.browse;

  /// Applications are personal-only — hidden on hospital/recruiter business pages.
  bool get _hideApplicationsTab =>
      ActingContextService.instance.organization?.canPostJobs == true;

  /// Manage is recruiter/hospital only — hidden for personal accounts.
  bool get _showManageTab {
    if (_loadingCaps) {
      return ActingContextService.instance.organization?.canPostJobs == true;
    }
    return _caps.canPost;
  }

  List<_JobsHubTab> get _visibleTabs {
    final tabs = <_JobsHubTab>[_JobsHubTab.browse, _JobsHubTab.saved];
    if (!_hideApplicationsTab) tabs.add(_JobsHubTab.applications);
    if (_showManageTab) tabs.add(_JobsHubTab.manage);
    return tabs;
  }

  bool get _onBrowse => _effectiveTab == _JobsHubTab.browse;

  _JobsHubTab get _effectiveTab {
    final tabs = _visibleTabs;
    return tabs.contains(_activeTab) ? _activeTab : tabs.first;
  }

  void _syncActiveTabIfNeeded() {
    if (!_visibleTabs.contains(_activeTab)) {
      _activeTab = _JobsHubTab.browse;
    }
  }

  _JobsHubTab _resolveInitialTab() {
    if (widget.manageJobId != null && _showManageTab) {
      return _JobsHubTab.manage;
    }
    switch (widget.initialTab) {
      case 1:
        return _JobsHubTab.saved;
      case 2:
        return _hideApplicationsTab ? _JobsHubTab.browse : _JobsHubTab.applications;
      case 3:
        return _showManageTab ? _JobsHubTab.manage : _JobsHubTab.browse;
      default:
        return _JobsHubTab.browse;
    }
  }

  void _ensureActiveTabVisible() {
    _syncActiveTabIfNeeded();
  }

  @override
  void initState() {
    super.initState();
    _activeTab = _resolveInitialTab();
    _ensureActiveTabVisible();
    ActingContextService.instance.addListener(_onActingChanged);
    _loadCaps();
  }

  void _onActingChanged() {
    if (!mounted || ActingContextService.instance.isSwitching) return;
    setState(_syncActiveTabIfNeeded);
    _loadCaps();
  }

  void _selectTab(_JobsHubTab tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      if (tab != _JobsHubTab.browse && _isSearchVisible) {
        _isSearchVisible = false;
      }
    });
  }

  Future<void> _loadCaps() async {
    try {
      final caps = await JobsNodeApiService.getCapabilities();
      if (!mounted) return;
      setState(() {
        _caps = caps;
        _loadingCaps = false;
      });
      if (widget.manageJobId != null &&
          caps.canPost &&
          _activeTab != _JobsHubTab.manage) {
        _selectTab(_JobsHubTab.manage);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCaps = false);
    }
  }

  Future<void> _openFilters() async {
    final next = await showJobsFilterSheet(
      context: context,
      initial: _filters,
      facets: _facets,
    );
    if (next == null || !mounted) return;
    setState(() => _filters = next);
  }

  void _clearSearch() {
    _searchCtrl.clear();
  }

  String _tabLabel(_JobsHubTab tab) {
    switch (tab) {
      case _JobsHubTab.browse:
        return 'Browse';
      case _JobsHubTab.saved:
        return 'Saved';
      case _JobsHubTab.applications:
        return 'Applications';
      case _JobsHubTab.manage:
        return 'Manage';
    }
  }

  Widget _buildTabContent(_JobsHubTab tab) {
    switch (tab) {
      case _JobsHubTab.browse:
        return JobsBrowseTab(
          key: const ValueKey('jobs-browse'),
          searchController: _searchCtrl,
          filters: _filters,
          onFacetsUpdated: (facets) => _facets = facets,
          onFiltersCleared: () {
            setState(() => _filters = JobsFilterState());
          },
        );
      case _JobsHubTab.saved:
        return const JobsSavedTab();
      case _JobsHubTab.applications:
        return const JobsApplicationsTab();
      case _JobsHubTab.manage:
        if (_loadingCaps) {
          return const JobCardShimmerList();
        }
        // Tab is only listed when canPost; keep manage UI as the sole content.
        return JobsManageTab(highlightJobId: widget.manageJobId);
    }
  }

  @override
  void dispose() {
    ActingContextService.instance.removeListener(_onActingChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleTabs = _visibleTabs;
    final effectiveTab = _effectiveTab;
    if (effectiveTab != _activeTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeTab != effectiveTab) {
          setState(() => _activeTab = effectiveTab);
        }
      });
    }
    final selectedIndex = visibleTabs.indexOf(effectiveTab);
    final canPost = !_loadingCaps && _caps.canPost;
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Jobs',
        subtitle: canPost ? 'Find roles · Hire talent' : 'Find your next role',
        backgroundColor: theme.cardBackground,
        showShadow: false,
        titleColor: theme.textPrimary,
        titleFontWeight: FontWeight.w700,
        titleFontSize: 20,
        searchField: _onBrowse && _isSearchVisible
            ? DoctakCollapsibleSearchField(
                isVisible: true,
                hintText: 'Role, specialty, hospital…',
                controller: _searchCtrl,
                searchDebounce: const Duration(milliseconds: 300),
                onClear: _clearSearch,
              )
            : null,
        actions: [
          if (_onBrowse) ...[
            DoctakSearchToggleButton(
              isSearching: _isSearchVisible,
              onTap: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) _clearSearch();
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Badge(
                isLabelVisible: _filters.activeCount > 0,
                backgroundColor: theme.primary,
                alignment: AlignmentDirectional.topEnd,
                offset: const Offset(-2, 6),
                label: Text('${_filters.activeCount}'),
                child: IconButton(
                  tooltip: 'Filters',
                  onPressed: _openFilters,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.tune_rounded,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
          ],
          if (canPost)
            IconButton(
              tooltip: 'Post a job',
              onPressed: () async {
                final created =
                    await const JobPostWizardScreen().launch(context);
                if (created == true && mounted) {
                  _selectTab(_JobsHubTab.manage);
                }
              },
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: theme.primary,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          OneUIProfileTabBar(
            tabs: visibleTabs.map(_tabLabel).toList(),
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            onSelected: (index) => _selectTab(visibleTabs[index]),
            expandTabs: true,
            showBottomBorder: false,
            backgroundColor: theme.cardBackground,
            matchAppBar: false,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          if (_onBrowse && _filters.activeCount > 0)
            JobsActiveFiltersRow(
              filters: _filters,
              onChanged: (next) => setState(() => _filters = next),
              onClearAll: () {
                _clearSearch();
                setState(() => _filters = JobsFilterState());
              },
            ),
          Expanded(
            child: ColoredBox(
              color: theme.scaffoldBackground,
              child: IndexedStack(
                index: selectedIndex < 0 ? 0 : selectedIndex,
                children: visibleTabs
                    .map((tab) => _buildTabContent(tab))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
