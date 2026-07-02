import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/screens/group_edit_screen.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_feed_tab.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_info_tab.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_invite_sheet.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_media_tab.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_members_tab.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_notification_sheet.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_options_menu.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_pending_invite_banner.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_polls_tab.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_profile_header.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_tab_bar_delegate.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String? pendingInvitationId;
  final String? inviterName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.pendingInvitationId,
    this.inviterName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with TickerProviderStateMixin {
  GroupDetailModel? _group;
  List<GroupFeedEntryModel> _feedItems = [];
  String? _feedCursor;
  bool _feedHasMore = false;
  bool _loading = true;
  bool _feedLoading = false;
  bool _feedLoadingMore = false;
  bool _membershipBusy = false;
  int _pendingPostCount = 0;
  String _membersInitialStatus = 'active';
  final GlobalKey<GroupMembersTabState> _membersTabKey = GlobalKey();
  String? _error;
  late TabController _tabController;

  static const _tabs = ['Posts', 'Members', 'Polls', 'Media', 'About'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadDetail();
  }

  @override
  void didUpdateWidget(covariant GroupDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _loadDetail();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _detailLoadSeq = 0;

  bool _matchesRequestedGroup(GroupDetailModel group, String requestedId) {
    final requested = requestedId.trim();
    if (requested.isEmpty) return false;
    return group.id.trim() == requested ||
        group.uuid?.trim() == requested ||
        group.routeId.trim() == requested;
  }

  Future<void> _loadDetail() async {
    final loadSeq = ++_detailLoadSeq;
    final requestedId = widget.groupId.trim();
    setState(() {
      _loading = true;
      _error = null;
      _group = null;
      _feedItems = [];
      _feedCursor = null;
      _feedHasMore = false;
    });
    try {
      final group = await GroupsNodeApiService.getGroupDetail(requestedId);
      if (!mounted || loadSeq != _detailLoadSeq) return;
      if (!_matchesRequestedGroup(group, requestedId)) {
        setState(() {
          _loading = false;
          _error = 'Loaded group does not match the selected card. Please try again.';
        });
        return;
      }
      setState(() {
        _group = group;
        _loading = false;
      });
      _loadFeed(refresh: true);
      _loadModerationCounts();
    } catch (e) {
      if (!mounted || loadSeq != _detailLoadSeq) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _loadFeed({bool refresh = false, bool loadMore = false}) async {
    if (loadMore && (!_feedHasMore || _feedLoadingMore)) return;
    final feedGroupId = widget.groupId.trim();
    setState(() {
      if (refresh) _feedLoading = true;
      if (loadMore) _feedLoadingMore = true;
    });
    try {
      final result = await GroupsNodeApiService.getGroupFeed(
        feedGroupId,
        cursor: loadMore ? _feedCursor : null,
      );
      if (!mounted || feedGroupId != widget.groupId.trim()) return;
      setState(() {
        _feedItems = loadMore ? [..._feedItems, ...result.items] : result.items;
        _feedCursor = result.nextCursor;
        _feedHasMore = result.nextCursor != null;
        _feedLoading = false;
        _feedLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _feedLoading = false;
        _feedLoadingMore = false;
      });
    }
  }

  Future<void> _loadModerationCounts() async {
    final group = _group;
    if (group == null || !group.capabilities.canModerate) return;
    try {
      final posts = await GroupsNodeApiService.getPosts(
        group.routeId,
        view: 'moderation',
        status: 'pending',
        limit: 1,
      );
      if (!mounted) return;
      setState(() => _pendingPostCount = posts.counts?['pending'] ?? 0);
    } catch (_) {}
  }

  Future<void> _toggleMembership() async {
    final group = _group;
    if (group == null || _membershipBusy) return;
    setState(() => _membershipBusy = true);
    try {
      if (group.membership?.isActiveMember == true) {
        await GroupsNodeApiService.leaveGroup(group.routeId);
        if (mounted) Navigator.of(context).maybePop();
        return;
      } else {
        await GroupsNodeApiService.joinGroup(group.routeId);
      }
      await _loadDetail();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _membershipBusy = false);
    }
  }

  void _openTab(int index) {
    _tabController.animateTo(index);
  }

  Future<void> _confirmLeaveGroup() async {
    final theme = OneUITheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text('Leave group?', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          'You will no longer see posts from this group.',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Leave', style: TextStyle(color: theme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _toggleMembership();
  }

  Future<void> _confirmDeleteGroup() async {
    final theme = OneUITheme.of(context);
    final group = _group;
    if (group == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text('Delete group?', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          'This permanently deletes "${group.name}" and all of its content. This cannot be undone.',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: theme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await GroupsNodeApiService.deleteGroup(group.routeId);
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _openOptionsMenu() {
    final group = _group;
    if (group == null) return;
    final isOwner = group.capabilities.isOwner;
    showGroupOptionsMenu(
      context,
      group: group,
      postRequestCount: _pendingPostCount,
      onManageNotifications: group.membership?.isActiveMember == true
          ? () => showGroupNotificationSheet(context, group: group)
          : null,
      onPostRequests: group.capabilities.canModerate
          ? () => _openTab(4)
          : null,
      onSettings: group.capabilities.canManage ? _openEditScreen : null,
      onDelete: isOwner ? _confirmDeleteGroup : null,
      onLeave: !isOwner && group.membership?.isActiveMember == true
          ? _confirmLeaveGroup
          : null,
    );
  }

  void _shareGroup() {
    final group = _group;
    if (group == null) return;
    final link = 'https://doctak.net/groups/${group.publicSlug}';
    Share.share('Join ${group.name} on Doctak\n$link');
  }

  void _openInviteSheet() {
    final group = _group;
    if (group == null) return;
    showGroupInviteSheet(context, group: group);
  }

  void _openEditScreen() {
    final group = _group;
    if (group == null || !group.capabilities.canManage) return;
    AppNavigator.push(context, GroupEditScreen(group: group)).then((saved) {
      if (saved == true) _loadDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        AppButton(text: 'Retry', onTap: _loadDetail),
                      ],
                    ),
                  ),
                )
              : _group == null
                  ? const SizedBox.shrink()
                  : NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        final group = _group!;
                        final showCollapsed = innerBoxIsScrolled;
                        return [
                          SliverToBoxAdapter(
                            child: GroupProfileHeader(
                              group: group,
                              showCoverActions: !showCollapsed,
                              onBack: () => Navigator.of(context).maybePop(),
                              onMenuTap: _openOptionsMenu,
                              onInviteTap: _openInviteSheet,
                              onShareTap: _shareGroup,
                              onJoinTap: _toggleMembership,
                              membershipBusy: _membershipBusy,
                            ),
                          ),
                          if (widget.pendingInvitationId != null &&
                              widget.pendingInvitationId!.isNotEmpty)
                            SliverToBoxAdapter(
                              child: GroupPendingInviteBanner(
                                invitationId: widget.pendingInvitationId!,
                                inviterName: widget.inviterName,
                                onResponded: _loadDetail,
                              ),
                            ),
                          SliverOverlapAbsorber(
                            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                              context,
                            ),
                            sliver: SliverMainAxisGroup(
                              slivers: [
                                SliverAppBar(
                                  pinned: true,
                                  primary: false,
                                  stretch: false,
                                  automaticallyImplyLeading: false,
                                  backgroundColor: theme.cardBackground,
                                  surfaceTintColor: Colors.transparent,
                                  elevation: 0,
                                  scrolledUnderElevation: showCollapsed ? 0.5 : 0,
                                  forceElevated: showCollapsed,
                                  toolbarHeight: showCollapsed ? kToolbarHeight : 0,
                                  expandedHeight: showCollapsed ? kToolbarHeight : 0,
                                  collapsedHeight: showCollapsed ? kToolbarHeight : 0,
                                  leading: showCollapsed
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).maybePop(),
                                        )
                                      : null,
                                  title: showCollapsed
                                      ? Text(
                                          group.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: theme.textPrimary,
                                          ),
                                        )
                                      : null,
                                  centerTitle: false,
                                  titleSpacing: showCollapsed ? 0 : null,
                                  actions: showCollapsed
                                      ? [
                                          IconButton(
                                            icon: const Icon(Icons.share_outlined),
                                            onPressed: _shareGroup,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.more_horiz_rounded),
                                            onPressed: _openOptionsMenu,
                                          ),
                                        ]
                                      : null,
                                ),
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: GroupTabBarHeaderDelegate(
                                    tabController: _tabController,
                                    tabs: _tabs,
                                    theme: theme,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                      body: ColoredBox(
                        color: theme.scaffoldBackground,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            GroupFeedTab(
                              group: _group!,
                              items: _feedItems,
                              loading: _feedLoading,
                              loadingMore: _feedLoadingMore,
                              hasMore: _feedHasMore,
                              onRefresh: () => _loadFeed(refresh: true),
                              onLoadMore: () => _loadFeed(loadMore: true),
                              onPosted: () => _loadFeed(refresh: true),
                              nested: true,
                            ),
                            GroupMembersTab(
                              key: _membersTabKey,
                              group: _group!,
                              nested: true,
                              initialStatus: _membersInitialStatus,
                            ),
                            GroupPollsTab(group: _group!, nested: true),
                            GroupMediaTab(groupId: _group!.routeId, nested: true),
                            GroupInfoTab(group: _group!, nested: true),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

void openGroupDetail(
  BuildContext context,
  GroupSummaryModel group, {
  String? pendingInvitationId,
  String? inviterName,
}) {
  openGroupDetailById(
    context,
    group.routeId,
    pendingInvitationId: pendingInvitationId,
    inviterName: inviterName,
  );
}

void openGroupDetailById(
  BuildContext context,
  String groupId, {
  String? pendingInvitationId,
  String? inviterName,
}) {
  final routeId = groupId.trim();
  if (routeId.isEmpty) return;

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: 'group-detail/$routeId'),
      builder: (_) => GroupDetailScreen(
        key: ValueKey('group-detail-$routeId'),
        groupId: routeId,
        pendingInvitationId: pendingInvitationId,
        inviterName: inviterName,
      ),
    ),
  );
}
