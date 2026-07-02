import 'package:doctak_app/presentation/cme_module/bloc/cme_certificates_bloc.dart';
import 'package:doctak_app/presentation/cme_module/cme_hub_controller.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_certificates_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_credits_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_creation_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_provider_events_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_speaking_screen.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_credit_summary_card.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_workspace_sheet.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_workspace_switcher.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// CME hub — swipeable tabs + workspace switcher (web `CmeSidebar` parity).
class CmeMainScreen extends StatefulWidget {
  const CmeMainScreen({super.key});

  @override
  State<CmeMainScreen> createState() => _CmeMainScreenState();
}

class _CmeMainScreenState extends State<CmeMainScreen>
    with TickerProviderStateMixin {
  final _hub = CmeHubController();
  final _searchController = TextEditingController();
  late final CmeCertificatesBloc _certificatesBloc;
  TabController? _tabController;
  bool? _tabProviderMode;
  bool _isSearchVisible = false;
  String _searchKeyword = '';

  static const _learnerTabs = [
    'Browse',
    'Registered',
    'In progress',
    'Completed',
    'Certificates',
    'Speaking',
    'Invites',
  ];

  static const _providerTabs = ['All', 'Open', 'Closed'];

  @override
  void initState() {
    super.initState();
    _certificatesBloc = CmeCertificatesBloc();
    _hub.addListener(_onHubChanged);
    _hub.initialize();
  }

  @override
  void dispose() {
    _hub.removeListener(_onHubChanged);
    _tabController?.removeListener(_onTabIndexChanged);
    _tabController?.dispose();
    _searchController.dispose();
    _hub.dispose();
    _certificatesBloc.close();
    super.dispose();
  }

  void _onHubChanged() {
    _syncTabController(forceReset: _tabProviderMode != _hub.isProviderMode);
    if (mounted) setState(() {});
  }

  void _syncTabController({bool forceReset = false}) {
    final providerMode = _hub.isProviderMode;
    if (!forceReset &&
        _tabController != null &&
        _tabProviderMode == providerMode) {
      return;
    }

    _tabController?.removeListener(_onTabIndexChanged);
    _tabController?.dispose();

    _tabProviderMode = providerMode;
    final length = providerMode ? _providerTabs.length : _learnerTabs.length;
    _tabController = TabController(length: length, vsync: this);
    _tabController!.addListener(_onTabIndexChanged);
  }

  void _onTabIndexChanged() {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    final index = _tabController!.index;
    final dest = _hub.isProviderMode
        ? _providerDestinations[index]
        : _learnerDestinations[index];
    if (_hub.destination != dest) {
      _hub.selectDestination(dest);
      if (!_supportsSearchFor(dest)) _clearSearch();
    }
    setState(() {});
  }

  static const _learnerDestinations = [
    CmeHubDestination.browse,
    CmeHubDestination.myRegistrations,
    CmeHubDestination.inProgress,
    CmeHubDestination.completed,
    CmeHubDestination.certificates,
    CmeHubDestination.speaking,
    CmeHubDestination.invitations,
  ];

  static const _providerDestinations = [
    CmeHubDestination.providerAll,
    CmeHubDestination.providerOpen,
    CmeHubDestination.providerClosed,
  ];

  bool get _supportsSearch {
    if (_tabController == null) return false;
    final dest = _hub.isProviderMode
        ? _providerDestinations[_tabController!.index]
        : _learnerDestinations[_tabController!.index];
    return _supportsSearchFor(dest);
  }

  bool _supportsSearchFor(CmeHubDestination dest) {
    switch (dest) {
      case CmeHubDestination.certificates:
      case CmeHubDestination.credits:
      case CmeHubDestination.speaking:
      case CmeHubDestination.invitations:
        return false;
      default:
        return true;
    }
  }

  void _onCreateEvent(BuildContext context) {
    if (_hub.capabilities?.canCreate == true || _hub.isProviderMode) {
      AppNavigator.push(context, const CmeEventCreationScreen());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Switch to a CME provider workspace to create activities.',
          ),
        ),
      );
    }
  }

  void _openCredits(BuildContext context) {
    final theme = OneUITheme.of(context);
    AppNavigator.push(
      context,
      Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: const DoctakAppBar(title: 'Credit history'),
        body: const CmeCreditsScreen(),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    if (_searchKeyword.isNotEmpty || _isSearchVisible) {
      setState(() {
        _searchKeyword = '';
        _isSearchVisible = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    final next = value.trim();
    if (next != _searchKeyword) {
      setState(() => _searchKeyword = next);
    }
  }

  List<int?> _learnerBadgeCounts() {
    final n = _hub.navCounts;
    return [
      null,
      n.registrations,
      n.inProgress,
      n.completed,
      n.certificates,
      n.speaking,
      n.invitations,
    ];
  }

  List<int?> _providerBadgeCounts() {
    final p = _hub.providerCounts;
    return [p.all, p.open, p.closed];
  }

  List<Widget> _learnerTabViews() {
    final keyword = _searchKeyword;
    return [
      CmeLearnerBrowseScreen(
        scope: 'all',
        segment: 'browse',
        searchKeyword: keyword,
        description: 'Live and on-demand CME activities you can register for.',
      ),
      CmeLearnerBrowseScreen(
        scope: 'registered',
        segment: 'registered',
        searchKeyword: keyword,
        description: 'CME activities you have registered for.',
      ),
      CmeLearnerBrowseScreen(
        scope: 'registered',
        segment: 'progress',
        searchKeyword: keyword,
        description: 'Finish these activities to earn CME credit.',
      ),
      CmeLearnerBrowseScreen(
        scope: 'registered',
        segment: 'completed',
        searchKeyword: keyword,
        description: 'Activities you completed and earned credit for.',
      ),
      const CmeCertificatesScreen(),
      const CmeSpeakingScreen(),
      const CmeSpeakingScreen(invitationsOnly: true),
    ];
  }

  List<Widget> _providerTabViews() {
    final keyword = _searchKeyword;
    return [
      CmeProviderEventsScreen(
        mode: CmeProviderEventsMode.all,
        searchKeyword: keyword,
        description: 'Every CME activity your provider organization created.',
      ),
      CmeProviderEventsScreen(
        mode: CmeProviderEventsMode.open,
        searchKeyword: keyword,
        description: 'Draft and live activities that are not closed yet.',
      ),
      CmeProviderEventsScreen(
        mode: CmeProviderEventsMode.closed,
        searchKeyword: keyword,
        description: 'Ended or closed CME activities.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    _syncTabController();

    return ListenableBuilder(
      listenable: _hub,
      builder: (context, _) {
        final tabController = _tabController;
        if (tabController == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final providerMode = _hub.isProviderMode;
        final tabs = providerMode ? _providerTabs : _learnerTabs;
        final badgeCounts =
            providerMode ? _providerBadgeCounts() : _learnerBadgeCounts();

        return BlocProvider.value(
          value: _certificatesBloc,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackground,
            floatingActionButton: _hub.capabilities?.canCreate == true
                ? FloatingActionButton.extended(
                    onPressed: () => _onCreateEvent(context),
                    backgroundColor: theme.primary,
                    icon: Icon(Icons.add, color: theme.buttonPrimaryText),
                    label: Text(
                      'Create',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: theme.buttonPrimaryText,
                      ),
                    ),
                  )
                : null,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    border: Border(
                      bottom: BorderSide(color: theme.border, width: 0.8),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DoctakAppBar(
                        title: 'CME',
                        subtitle: providerMode
                            ? (_hub.activeOrg?.name ?? 'Provider workspace')
                            : 'Personal learning',
                        showBackButton: true,
                        showShadow: false,
                        backgroundColor: theme.cardBackground,
                        onBackPressed: () => Navigator.pop(context),
                        searchField: _supportsSearch
                            ? DoctakCollapsibleSearchField(
                                isVisible: _isSearchVisible,
                                hintText: 'Search CME activities...',
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                onClear: _clearSearch,
                              )
                            : null,
                        actions: [
                          if (_supportsSearch)
                            DoctakSearchToggleButton(
                              isSearching: _isSearchVisible,
                              onTap: () {
                                setState(() {
                                  _isSearchVisible = !_isSearchVisible;
                                  if (!_isSearchVisible) _clearSearch();
                                });
                              },
                            ),
                          CmeWorkspaceSwitcher(
                            hub: _hub,
                            onTap: () => showCmeWorkspaceSheet(context, hub: _hub),
                          ),
                        ],
                      ),
                      OneUIProfileTabBar(
                        tabs: tabs,
                        badgeCounts: badgeCounts,
                        selectedIndex: tabController.index,
                        onSelected: tabController.animateTo,
                        expandTabs: providerMode,
                        showBottomBorder: false,
                        backgroundColor: theme.cardBackground,
                        matchAppBar: false,
                      ),
                    ],
                  ),
                ),
                if (_hub.error != null)
                  MaterialBanner(
                    content: Text(
                      _hub.error!,
                      style: TextStyle(color: theme.error, fontSize: 13),
                    ),
                    leading: Icon(Icons.warning_amber_rounded, color: theme.error),
                    actions: [
                      TextButton(
                        onPressed: _hub.refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                if (_hub.loading)
                  const LinearProgressIndicator(minHeight: 2),
                if (!providerMode && !_hub.loading && _hub.error == null)
                  CmeCreditSummaryCard(
                    hub: _hub,
                    onTap: () => _openCredits(context),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    physics: const BouncingScrollPhysics(),
                    children: providerMode
                        ? _providerTabViews()
                        : _learnerTabViews(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
