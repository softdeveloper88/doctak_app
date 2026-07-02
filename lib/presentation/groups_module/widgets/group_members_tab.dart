import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_circle_avatar.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_member_options_sheet.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_nested_tab_scroll.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_tab_shimmers.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class GroupMembersTab extends StatefulWidget {
  final GroupDetailModel group;
  final bool nested;
  final String initialStatus;

  const GroupMembersTab({
    super.key,
    required this.group,
    this.nested = false,
    this.initialStatus = 'active',
  });

  @override
  State<GroupMembersTab> createState() => GroupMembersTabState();
}

class GroupMembersTabState extends State<GroupMembersTab> {
  final _searchController = TextEditingController();
  List<GroupMemberModel> _items = [];
  Map<String, int> _counts = {};
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  late String _statusFilter;
  String _roleFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus;
    preloadSpecialties().then((_) {
      if (mounted) setState(() {});
    });
    _load(refresh: true);
    _searchController.addListener(() {
      final q = _searchController.text.trim();
      if (q != _searchQuery) setState(() => _searchQuery = q);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void applyStatusFilter(String status) {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
    _load(refresh: true);
  }

  Future<void> _load({bool refresh = false, bool loadMore = false}) async {
    if (!widget.group.capabilities.canViewMembers) {
      setState(() {
        _loading = false;
        _error = 'Member list is not visible for this group.';
      });
      return;
    }
    if (loadMore && (!_hasMore || _loadingMore)) return;

    setState(() {
      if (refresh) _loading = true;
      if (loadMore) _loadingMore = true;
      _error = null;
    });

    try {
      final result = await GroupsNodeApiService.getMembers(
        widget.group.routeId,
        status: _statusFilter,
        role: _roleFilter,
        cursor: loadMore ? _cursor : null,
      );
      if (!mounted) return;
      setState(() {
        _items = loadMore ? [..._items, ...result.items] : result.items;
        _cursor = result.nextCursor;
        _hasMore = result.nextCursor != null;
        _counts = result.counts;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = '$e';
      });
    }
  }

  List<GroupMemberModel> get _filteredItems {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((m) {
      final haystack = [
        m.name,
        m.specialtyLabel ?? '',
        m.role,
        _roleLabel(m.role),
      ]
          .join(' ')
          .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      default:
        return 'Member';
    }
  }

  Future<void> _handleMemberAction(GroupMemberModel member, String action) async {
    final theme = OneUITheme.of(context);
    final groupId = widget.group.routeId;

    Future<bool> confirm(String title, String message) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardBackground,
          title: Text(title, style: TextStyle(color: theme.textPrimary)),
          content: Text(message, style: TextStyle(color: theme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Confirm', style: TextStyle(color: theme.error)),
            ),
          ],
        ),
      );
      return ok == true;
    }

    try {
      switch (action) {
        case 'approve':
        case 'reject':
        case 'suspend':
        case 'remove':
          final labels = {
            'approve': 'approve ${member.name}',
            'reject': 'reject ${member.name}',
            'suspend': 'block ${member.name}',
            'remove': 'remove ${member.name} from this group',
          };
          if (!await confirm('Confirm action', 'Do you want to ${labels[action]}?')) return;
          await GroupsNodeApiService.updateMemberStatus(
            groupId,
            memberId: member.memberId,
            action: action,
          );
          if (action == 'suspend') {
            applyStatusFilter('suspended');
          } else {
            await _load(refresh: true);
          }
        case 'make_admin':
          if (!await confirm('Make admin', 'Promote ${member.name} to admin?')) return;
          await GroupsNodeApiService.setMemberRole(
            groupId,
            memberId: member.memberId,
            role: 'admin',
          );
          await _load(refresh: true);
        case 'remove_admin':
          if (!await confirm('Remove admin', 'Remove admin role from ${member.name}?')) return;
          await GroupsNodeApiService.setMemberRole(
            groupId,
            memberId: member.memberId,
            role: 'member',
          );
          await _load(refresh: true);
        case 'make_moderator':
          if (!await confirm('Make moderator', 'Promote ${member.name} to moderator?')) return;
          await GroupsNodeApiService.setMemberRole(
            groupId,
            memberId: member.memberId,
            role: 'moderator',
          );
          await _load(refresh: true);
        case 'remove_moderator':
          if (!await confirm('Remove moderator', 'Remove moderator role from ${member.name}?')) return;
          await GroupsNodeApiService.setMemberRole(
            groupId,
            memberId: member.memberId,
            role: 'member',
          );
          await _load(refresh: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      const shimmer = GroupMembersTabShimmer();
      if (widget.nested) return const GroupTabShimmerScroll(shimmer: shimmer);
      return shimmer;
    }

    final scroll = NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 && _hasMore) {
          _load(loadMore: true);
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: widget.nested
            ? GroupNestedTabScroll(slivers: _buildSlivers(context))
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: _buildFlatChildren(context),
              ),
      ),
    );

    return scroll;
  }

  List<Widget> _buildSlivers(BuildContext context) {
    final theme = OneUITheme.of(context);
    final items = _filteredItems;

    return [
      SliverToBoxAdapter(child: _buildHeader(theme)),
      if (_error != null)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!))),
        )
      else if (items.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              _searchQuery.isNotEmpty ? 'No members match your search.' : 'No members in this list.',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: items.length + (_loadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: GroupMemberRowShimmer(),
                );
              }
              return _memberTile(theme, items[index]);
            },
          ),
        ),
    ];
  }

  List<Widget> _buildFlatChildren(BuildContext context) {
    final theme = OneUITheme.of(context);
    final items = _filteredItems;
    return [
      _buildHeader(theme),
      if (_error != null)
        Padding(padding: const EdgeInsets.all(24), child: Text(_error!))
      else if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _searchQuery.isNotEmpty ? 'No members match your search.' : 'No members in this list.',
            style: TextStyle(color: theme.textSecondary),
          ),
        )
      else ...[
        ...items.map((m) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _memberTile(theme, m),
            )),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GroupMemberRowShimmer(),
          ),
      ],
    ];
  }

  Widget _buildHeader(OneUITheme theme) {
    final canModerate = widget.group.capabilities.canModerate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, specialty, or role…',
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              filled: true,
              fillColor: theme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.divider),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        if (canModerate) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _statusChip(theme, 'active', 'Approved', _counts['active']),
                _statusChip(theme, 'pending', 'Pending', _counts['pending']),
                _statusChip(theme, 'suspended', 'Blocked', _counts['suspended']),
                _statusChip(theme, 'rejected', 'Rejected', _counts['rejected']),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _roleChip(theme, 'all', 'All roles'),
              _roleChip(theme, 'admin', 'Admins'),
              _roleChip(theme, 'moderator', 'Moderators'),
              _roleChip(theme, 'member', 'Members'),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _statusChip(OneUITheme theme, String status, String label, int? count) {
    final selected = _statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(count != null && count > 0 ? '$label ($count)' : label),
        selected: selected,
        onSelected: (_) => applyStatusFilter(status),
        selectedColor: theme.primary.withValues(alpha: 0.12),
        checkmarkColor: theme.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? theme.primary : theme.textSecondary,
        ),
      ),
    );
  }

  Widget _roleChip(OneUITheme theme, String role, String label) {
    final selected = _roleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          if (_roleFilter == role) return;
          setState(() => _roleFilter = role);
          _load(refresh: true);
        },
        selectedColor: theme.primary.withValues(alpha: 0.12),
        checkmarkColor: theme.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? theme.primary : theme.textSecondary,
        ),
      ),
    );
  }

  Widget _memberTile(OneUITheme theme, GroupMemberModel person) {
    final canShowMenu = widget.group.capabilities.canModerate && person.role != 'owner';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.divider),
      ),
      child: Row(
        children: [
          GroupCircleAvatar(imageUrl: person.avatar, name: person.name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: TextStyle(fontWeight: FontWeight.w600, color: theme.textPrimary),
                ),
                if (person.specialtyLabel != null)
                  Text(
                    person.specialtyLabel!,
                    style: TextStyle(fontSize: 12, color: theme.textSecondary),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _roleLabel(person.role),
              style: TextStyle(fontSize: 11, color: theme.textSecondary),
            ),
          ),
          if (canShowMenu) ...[
            const SizedBox(width: 4),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.more_horiz_rounded, color: theme.textSecondary),
              onPressed: () => showGroupMemberOptionsSheet(
                context,
                member: person,
                group: widget.group,
                onAction: (action) => _handleMemberAction(person, action),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
