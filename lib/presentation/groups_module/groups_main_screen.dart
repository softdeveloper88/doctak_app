import 'dart:async';

import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/bloc/groups_bloc.dart';
import 'package:doctak_app/presentation/groups_module/bloc/groups_event.dart';
import 'package:doctak_app/presentation/groups_module/bloc/groups_state.dart';
import 'package:doctak_app/presentation/groups_module/screens/group_create_screen.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_summary_card.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_tab_shimmers.dart';
import 'package:doctak_app/presentation/groups_module/widgets/groups_empty_state.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/one_ui_tab_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Groups hub — Browse | My Groups | Invitations (web `/groups` parity).
class GroupsMainScreen extends StatefulWidget {
  const GroupsMainScreen({super.key});

  @override
  State<GroupsMainScreen> createState() => _GroupsMainScreenState();
}

class _GroupsMainScreenState extends State<GroupsMainScreen>
    with TickerProviderStateMixin {
  late final GroupsBloc _bloc;
  late TabController _tabController;
  TabController? _mineSubTabController;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  TabController get _mineSubTabs => _mineSubTabController!;

  void _ensureMineSubTabController() {
    if (_mineSubTabController != null) return;
    _mineSubTabController = TabController(length: 2, vsync: this)
      ..addListener(_onHubTabChanged);
  }

  @override
  void initState() {
    super.initState();
    _bloc = GroupsBloc()
      ..add(const GroupsBrowseRequested())
      ..add(const GroupsMineRequested())
      ..add(const GroupsCreatedRequested())
      ..add(const GroupsInvitationsRequested())
      ..add(const GroupsSuggestionsRequested());
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onHubTabChanged);
    _ensureMineSubTabController();
    _searchController.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    if (mounted) setState(() {});
  }

  void _onHubTabChanged() {
    if (mounted) setState(() {});
  }

  void _handleSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _bloc.add(GroupsSearchChanged(value));
      if (value.trim().isNotEmpty && _tabController.index != 0) {
        _tabController.animateTo(0);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _bloc.add(const GroupsSearchChanged(''));
  }

  @override
  void dispose() {
    _tabController.removeListener(_onHubTabChanged);
    _mineSubTabController?.removeListener(_onHubTabChanged);
    _searchController.removeListener(_onSearchTextChanged);
    _searchDebounce?.cancel();
    _tabController.dispose();
    _mineSubTabController?.dispose();
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _openCreate() {
    AppNavigator.push(context, const GroupCreateScreen()).then((created) {
      if (created == true) {
        _bloc
          ..add(const GroupsBrowseRequested(refresh: true))
          ..add(const GroupsMineRequested(refresh: true))
          ..add(const GroupsCreatedRequested(refresh: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    _ensureMineSubTabController();

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<GroupsBloc, GroupsState>(
        listener: (context, state) {
          if (state is GroupsLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final loaded = state is GroupsLoaded ? state : null;
          final pendingCount = loaded?.facets?.pendingInvitations ??
              loaded?.invitations.length ??
              0;

          return Scaffold(
            backgroundColor: theme.scaffoldBackground,
            floatingActionButton: FloatingActionButton(
              onPressed: _openCreate,
              backgroundColor: theme.primary,
              foregroundColor: theme.buttonPrimaryText,
              elevation: 2,
              child: const Icon(Icons.group_add_rounded, size: 24),
            ),
            body: Column(
              children: [
                _GroupsHubChrome(
                  searchController: _searchController,
                  onSearchChanged: _handleSearch,
                  onClearSearch: _clearSearch,
                  hubTabIndex: _tabController.index,
                  onHubTabSelected: (index) => _tabController.animateTo(index),
                  pendingInviteCount: pendingCount,
                  showMineSubTabs: _tabController.index == 1,
                  mineSubTabIndex: _mineSubTabs.index,
                  onMineSubTabSelected: (index) =>
                      _mineSubTabs.animateTo(index),
                ),
                Expanded(
                  child: ColoredBox(
                    color: theme.scaffoldBackground,
                    child: state is GroupsFailure
                        ? GroupsEmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Could not load groups',
                            subtitle: state.message,
                            actionLabel: 'Retry',
                            onAction: () => _bloc.add(
                              const GroupsBrowseRequested(refresh: true),
                            ),
                          )
                        : (state is GroupsLoading || state is GroupsInitial)
                            ? const GroupsListShimmer()
                            : TabBarView(
                                controller: _tabController,
                                children: [
                                  _BrowseTab(state: loaded),
                                  _MineTab(
                                    state: loaded,
                                    subTabController: _mineSubTabs,
                                  ),
                                  _InvitationsTab(state: loaded),
                                ],
                              ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BrowseTab extends StatelessWidget {
  final GroupsLoaded? state;

  const _BrowseTab({required this.state});

  List<GroupSummaryModel> _discoverItems(
    List<GroupSummaryModel> suggestions,
    List<GroupSummaryModel> browse,
  ) {
    if (suggestions.isEmpty) return browse;
    final suggestedIds = <String>{
      for (final g in suggestions) g.id.trim(),
      for (final g in suggestions) g.routeId.trim(),
    };
    return browse
        .where(
          (g) =>
              !suggestedIds.contains(g.id.trim()) &&
              !suggestedIds.contains(g.routeId.trim()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroupsBloc>();
    final suggestions = state?.suggestions ?? [];
    final items = _discoverItems(suggestions, state?.browseItems ?? []);
    final isSearching = (state?.searchKeyword.trim().isNotEmpty ?? false);
    final isLoading =
        (state?.browseLoading ?? true) || (state?.suggestionsLoading ?? true);

    if (items.isEmpty && suggestions.isEmpty) {
      if (isLoading) return const GroupsListShimmer();
      return RefreshIndicator(
        onRefresh: () async =>
            bloc.add(const GroupsBrowseRequested(refresh: true)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (suggestions.isNotEmpty) ...[
              const _SectionTitle('Suggested for you'),
              const SizedBox(height: 10),
              ...suggestions.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GroupSummaryCard(
                    key: ValueKey('suggested-${g.id}-${g.name}'),
                    group: g,
                    variant: GroupCardVariant.suggested,
                    isJoining: state?.joiningGroupIds.contains(g.routeId) == true,
                    onJoin: (group) => bloc.add(GroupJoinRequested(group)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            const GroupsEmptyState(
              icon: Icons.groups_outlined,
              title: 'No groups found',
              subtitle: 'Try a different search or create a new community.',
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240 &&
            state?.browseHasMore == true &&
            state?.browseLoadingMore != true) {
          bloc.add(const GroupsBrowseLoadMore());
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async =>
            bloc.add(const GroupsBrowseRequested(refresh: true)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          children: [
            if (suggestions.isNotEmpty && !isSearching) ...[
              const _SectionTitle('Suggested for you'),
              const SizedBox(height: 10),
              ...suggestions.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GroupSummaryCard(
                    key: ValueKey('suggested-${g.id}-${g.name}'),
                    group: g,
                    variant: GroupCardVariant.suggested,
                    isJoining: state?.joiningGroupIds.contains(g.routeId) == true,
                    onJoin: (group) => bloc.add(GroupJoinRequested(group)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (items.isNotEmpty) const _SectionTitle('Discover groups'),
              if (items.isNotEmpty) const SizedBox(height: 10),
            ],
            ...items.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GroupSummaryCard(
                  key: ValueKey('browse-${group.id}-${group.name}'),
                  group: group,
                  variant: GroupCardVariant.browse,
                  isJoining: state?.joiningGroupIds.contains(group.routeId) == true,
                  onJoin: (g) => bloc.add(GroupJoinRequested(g)),
                ),
              ),
            ),
            if (items.isEmpty && isSearching && !isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: GroupsEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No groups found',
                  subtitle: 'Try a different search term.',
                ),
              ),
            if (state?.browseLoadingMore == true)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _MineTab extends StatelessWidget {
  final GroupsLoaded? state;
  final TabController subTabController;

  const _MineTab({
    required this.state,
    required this.subTabController,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroupsBloc>();
    final joined = state?.mineItems ?? [];
    final created = state?.createdItems ?? [];

    return TabBarView(
      controller: subTabController,
      children: [
        _GroupList(
          items: joined,
          isLoading: state?.mineLoading ?? true,
          emptyTitle: 'No joined groups',
          emptySubtitle:
              'Browse communities and join groups that interest you.',
          onRefresh: () async {
            bloc.add(const GroupsMineRequested(refresh: true));
          },
        ),
        _GroupList(
          items: created,
          isLoading: state?.createdLoading ?? true,
          emptyTitle: 'No created groups',
          emptySubtitle: 'Create a group to build your own community.',
          onRefresh: () async {
            bloc.add(const GroupsCreatedRequested(refresh: true));
          },
        ),
      ],
    );
  }
}

class _GroupList extends StatelessWidget {
  final List<GroupSummaryModel> items;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;

  const _GroupList({
    required this.items,
    required this.isLoading,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && isLoading) {
      return const GroupsListShimmer();
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            GroupsEmptyState(
              icon: Icons.group_outlined,
              title: emptyTitle,
              subtitle: emptySubtitle,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final group = items[index];
          return GroupSummaryCard(
            key: ValueKey('mine-${group.id}-${group.name}'),
            group: group,
            variant: GroupCardVariant.mine,
          );
        },
      ),
    );
  }
}

class _InvitationsTab extends StatelessWidget {
  final GroupsLoaded? state;

  const _InvitationsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroupsBloc>();
    final invitations = state?.invitations ?? [];

    if (invitations.isEmpty && (state?.invitationsLoading ?? true)) {
      return const GroupsListShimmer();
    }
    if (invitations.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async =>
            bloc.add(const GroupsInvitationsRequested(refresh: true)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            GroupsEmptyState(
              icon: Icons.mail_outline_rounded,
              title: 'No invitations',
              subtitle: 'When someone invites you to a group, it will appear here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          bloc.add(const GroupsInvitationsRequested(refresh: true)),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: invitations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final inv = invitations[index];
          final group = inv.group ??
              GroupSummaryModel(
                id: inv.groupId,
                uuid: inv.groupId,
                name: inv.groupName ?? 'Group',
                privacy: 'invitation_only',
                groupType: 'general',
                logoImage: inv.groupLogo,
              );

          return GroupSummaryCard(
            key: ValueKey('invite-${inv.id}-${group.id}-${group.name}'),
            group: group,
            variant: GroupCardVariant.invitation,
            pendingInvitationId: inv.id,
            inviterName: inv.inviter?.name,
            onAccept: () => bloc.add(
              GroupInvitationRespondRequested(
                invitationId: inv.id,
                accept: true,
                group: group,
              ),
            ),
            onDecline: () => bloc.add(
              GroupInvitationRespondRequested(
                invitationId: inv.id,
                accept: false,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: theme.textPrimary,
      ),
    );
  }
}

class _GroupsHubChrome extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final int hubTabIndex;
  final ValueChanged<int> onHubTabSelected;
  final int pendingInviteCount;
  final bool showMineSubTabs;
  final int mineSubTabIndex;
  final ValueChanged<int> onMineSubTabSelected;

  const _GroupsHubChrome({
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.hubTabIndex,
    required this.onHubTabSelected,
    required this.pendingInviteCount,
    required this.showMineSubTabs,
    required this.mineSubTabIndex,
    required this.onMineSubTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(bottom: BorderSide(color: theme.border, width: 0.8)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GroupsHubHeader(
              searchController: searchController,
              onSearchChanged: onSearchChanged,
              onClearSearch: onClearSearch,
            ),
            OneUISegmentedTabBar(
              tabs: const ['Browse', 'My Groups', 'Invites'],
              selectedIndex: hubTabIndex,
              onSelected: onHubTabSelected,
              badgeCounts: [
                null,
                null,
                pendingInviteCount > 0 ? pendingInviteCount : null,
              ],
              isScrollable: false,
              compact: true,
              matchAppBar: false,
              backgroundColor: theme.cardBackground,
            ),
            if (showMineSubTabs)
              OneUIProfileTabBar(
                tabs: const ['Joined', 'Created'],
                selectedIndex: mineSubTabIndex,
                onSelected: onMineSubTabSelected,
                matchAppBar: false,
                backgroundColor: theme.cardBackground,
                expandTabs: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupsHubHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const _GroupsHubHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(CupertinoIcons.back, color: theme.iconColor, size: 22),
                  tooltip: 'Back',
                ),
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.searchFieldBackground,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: theme.border.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          CupertinoIcons.search,
                          color: theme.textTertiary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: TextStyle(fontSize: 14, color: theme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search specialty groups, topics…',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: theme.textTertiary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: onSearchChanged,
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        if (searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: onClearSearch,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: theme.textTertiary,
                                size: 18,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
  }
}
