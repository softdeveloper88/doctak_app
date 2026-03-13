import 'package:doctak_app/presentation/cme_module/bloc/cme_dashboard_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_dashboard_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_dashboard_state.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_detail_screen.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_event_card.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_shimmer_loader.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CmeMyEventsScreen extends StatefulWidget {
  const CmeMyEventsScreen({super.key});

  @override
  State<CmeMyEventsScreen> createState() => _CmeMyEventsScreenState();
}

class _CmeMyEventsScreenState extends State<CmeMyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<_TabConfig> _tabs = [
    _TabConfig('Registered', 'registered', Icons.how_to_reg_outlined),
    _TabConfig('Upcoming', 'upcoming', Icons.event_outlined),
    _TabConfig('Attended', 'attended', Icons.check_circle_outline),
    _TabConfig('Created', 'created', Icons.add_circle_outline),
  ];

  CmeDashboardBloc get _bloc => context.read<CmeDashboardBloc>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load dashboard stats + first tab
    _bloc.add(CmeLoadDashboardEvent());
    _bloc.add(CmeLoadMyEventsEvent(tab: 'registered', page: 1));
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _bloc.add(
          CmeLoadMyEventsEvent(tab: _tabs[_tabController.index].key, page: 1));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _bloc.add(CmeLoadMyEventsEvent(
      tab: _tabs[_tabController.index].key,
      page: 1,
      search: query.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Column(
      children: [
        // Dashboard stats
        _buildDashboardStats(theme),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearch,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: theme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search my events...',
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: theme.textTertiary,
              ),
              prefixIcon: Icon(Icons.search, color: theme.textTertiary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: theme.textTertiary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.cardBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.textTertiary.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.textTertiary.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primary, width: 1.5),
              ),
            ),
          ),
        ),

        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            border: Border(
              bottom: BorderSide(
                  color: theme.textTertiary.withValues(alpha: 0.15)),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: theme.primary,
            unselectedLabelColor: theme.textSecondary,
            indicatorColor: theme.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            tabs: _tabs
                .map((t) => Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(t.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabs
                .map((t) => _buildTabContent(theme, t.key))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardStats(OneUITheme theme) {
    return BlocBuilder<CmeDashboardBloc, CmeDashboardState>(
      buildWhen: (prev, curr) =>
          curr is CmeDashboardLoadedState || curr is CmeDashboardLoadingState,
      builder: (context, state) {
        final data = _bloc.dashboardData;
        if (data == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: theme.cardDecoration,
          child: Row(
            children: [
              _statItem(theme, '${data.totalCredits ?? 0}', 'Total\nCredits',
                  const Color(0xFF0A84FF)),
              _divider(theme),
              _statItem(theme, '${data.eventsAttended ?? 0}', 'Events\nAttended',
                  const Color(0xFF34C759)),
              _divider(theme),
              _statItem(theme, '${data.certificatesEarned ?? 0}',
                  'Certificates', const Color(0xFFFF9500)),
              _divider(theme),
              _statItem(theme, '${data.upcomingEvents ?? 0}', 'Upcoming',
                  const Color(0xFF6366F1)),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(
      OneUITheme theme, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(OneUITheme theme) {
    return Container(
      width: 1,
      height: 40,
      color: theme.textTertiary.withValues(alpha: 0.15),
    );
  }

  Widget _buildTabContent(OneUITheme theme, String tab) {
    return BlocBuilder<CmeDashboardBloc, CmeDashboardState>(
      buildWhen: (prev, curr) =>
          curr is CmeMyEventsLoadedState ||
          curr is CmeMyEventsLoadingState ||
          curr is CmeDashboardErrorState,
      builder: (context, state) {
        if (state is CmeMyEventsLoadingState) {
          return const CmeShimmerLoader();
        }

        if (state is CmeDashboardErrorState && _bloc.myEventsList.isEmpty) {
          return _buildErrorContent(theme, state.errorMessage);
        }

        if (_bloc.myEventsList.isEmpty) {
          return _buildEmptyContent(theme, tab);
        }

        return RefreshIndicator(
          onRefresh: () async {
            _bloc.add(CmeLoadMyEventsEvent(tab: tab, page: 1));
          },
          child: ListView.builder(
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            itemCount: _bloc.myEventsList.length,
            itemBuilder: (context, index) {
              if (_bloc.pageNumber <= _bloc.numberOfPage) {
                if (index ==
                    _bloc.myEventsList.length - _bloc.nextPageTrigger) {
                  _bloc.add(CmeMyEventsCheckMoreEvent(
                      index: index, tab: tab));
                }
              }

              final event = _bloc.myEventsList[index];
              return CmeEventCard(
                event: event,
                onTap: () {
                  if (event.id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CmeEventDetailScreen(eventId: event.id!),
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyContent(OneUITheme theme, String tab) {
    final config = _emptyConfig(tab);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(config.icon, size: 48, color: theme.primary),
          ),
          const SizedBox(height: 16),
          Text(config.title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              )),
          const SizedBox(height: 8),
          Text(config.subtitle,
              textAlign: TextAlign.center, style: theme.caption),
        ],
      ),
    );
  }

  _EmptyConfig _emptyConfig(String tab) {
    switch (tab) {
      case 'upcoming':
        return _EmptyConfig(Icons.event_outlined, 'No upcoming events',
            'Register for events to see them here');
      case 'attended':
        return _EmptyConfig(Icons.check_circle_outline,
            'No attended events', 'Complete events to track your progress');
      case 'created':
        return _EmptyConfig(Icons.add_circle_outline, 'No created events',
            'Create a CME event to get started');
      default:
        return _EmptyConfig(Icons.how_to_reg_outlined,
            'No registered events', 'Browse events and register');
    }
  }

  Widget _buildErrorContent(OneUITheme theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: theme.bodySecondary),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _bloc.add(
                  CmeLoadMyEventsEvent(tab: _tabs[_tabController.index].key)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: theme.radiusS),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final String key;
  final IconData icon;
  _TabConfig(this.label, this.key, this.icon);
}

class _EmptyConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  _EmptyConfig(this.icon, this.title, this.subtitle);
}
