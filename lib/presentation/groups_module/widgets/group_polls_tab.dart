import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_nested_tab_scroll.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_tab_shimmers.dart';
import 'package:doctak_app/presentation/groups_module/screens/group_poll_create_screen.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_poll_card.dart';
import 'package:doctak_app/presentation/groups_module/widgets/groups_empty_state.dart';
import 'package:flutter/material.dart';

class GroupPollsTab extends StatefulWidget {
  final GroupDetailModel group;
  final bool nested;

  const GroupPollsTab({super.key, required this.group, this.nested = false});

  @override
  State<GroupPollsTab> createState() => _GroupPollsTabState();
}

class _GroupPollsTabState extends State<GroupPollsTab> {
  List<GroupPollModel> _polls = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final polls = await GroupsNodeApiService.getPolls(widget.group.routeId);
      if (!mounted) return;
      setState(() {
        _polls = polls.where((p) => p.status != 'draft' && p.status != 'archived').toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GroupPollCreateScreen(group: widget.group),
      ),
    );
    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = groupCanCreatePoll(widget.group);

    if (_loading) {
      const shimmer = GroupPollsTabShimmer();
      if (widget.nested) {
        return const GroupTabShimmerScroll(shimmer: shimmer);
      }
      return shimmer;
    }

    Widget body;
    if (_error != null) {
      body = GroupsEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load polls',
        subtitle: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    } else if (_polls.isEmpty) {
      body = GroupsEmptyState(
        icon: Icons.poll_outlined,
        title: 'No polls yet',
        subtitle: canCreate
            ? 'Create the first poll for this group.'
            : 'Polls created in this group will appear here.',
        actionLabel: canCreate ? 'Create poll' : null,
        onAction: canCreate ? _openCreate : null,
      );
    } else if (widget.nested) {
      body = GroupNestedTabScroll(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            sliver: SliverList.separated(
              itemCount: _polls.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return GroupPollCard(
                  poll: _polls[index],
                  groupId: widget.group.routeId,
                  canModerate: widget.group.capabilities.canModerate,
                  onVoted: _load,
                  onClosed: _load,
                );
              },
            ),
          ),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: _polls.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return GroupPollCard(
              poll: _polls[index],
              groupId: widget.group.routeId,
              canModerate: widget.group.capabilities.canModerate,
              onVoted: _load,
              onClosed: _load,
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        if (widget.nested && body is! GroupNestedTabScroll && body is! RefreshIndicator)
          GroupNestedTabScroll(
            slivers: [
              SliverFillRemaining(hasScrollBody: false, child: body),
            ],
          )
        else
          body,
        if (canCreate && _polls.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create poll'),
            ),
          ),
      ],
    );
  }
}
