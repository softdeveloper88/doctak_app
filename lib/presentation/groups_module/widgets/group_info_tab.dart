import 'package:doctak_app/presentation/groups_module/widgets/group_nested_tab_scroll.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_tab_shimmers.dart';
import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:flutter/material.dart';

class GroupInfoTab extends StatefulWidget {
  final GroupDetailModel group;
  final bool nested;

  const GroupInfoTab({super.key, required this.group, this.nested = false});

  @override
  State<GroupInfoTab> createState() => _GroupInfoTabState();
}

class _GroupInfoTabState extends State<GroupInfoTab> {
  List<GroupFeedPostModel> _pendingPosts = [];
  bool _loadingModeration = false;
  bool _loadingAnalytics = false;
  Map<String, int> _memberCounts = {};
  Map<String, int> _postCounts = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    if (widget.group.capabilities.canModerate) {
      _loadModeration();
    }
  }

  Future<void> _loadAnalytics() async {
    if (!widget.group.capabilities.canModerate) return;
    setState(() => _loadingAnalytics = true);
    try {
      final members = await GroupsNodeApiService.getMembers(
        widget.group.routeId,
        limit: 1,
      );
      Map<String, int>? postCounts;
      final posts = await GroupsNodeApiService.getPosts(
        widget.group.routeId,
        view: 'moderation',
        status: 'all',
        limit: 1,
      );
      postCounts = posts.counts;
      if (!mounted) return;
      setState(() {
        _memberCounts = members.counts;
        _postCounts = postCounts ?? {};
        _loadingAnalytics = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAnalytics = false);
    }
  }

  Future<void> _loadModeration() async {
    setState(() => _loadingModeration = true);
    try {
      final result = await GroupsNodeApiService.getPosts(
        widget.group.routeId,
        view: 'moderation',
        status: 'pending',
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _pendingPosts = result.items;
        _postCounts = result.counts ?? _postCounts;
        _loadingModeration = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingModeration = false);
    }
  }

  Future<void> _reviewPost(String postId, String decision) async {
    try {
      await GroupsNodeApiService.moderatePost(
        widget.group.routeId,
        postId: postId,
        decision: decision,
      );
      await _loadModeration();
      await _loadAnalytics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final group = widget.group;

    final children = <Widget>[
        _Section(
          theme: theme,
          title: 'Privacy',
          body: _privacyDescription(group.privacy),
          chips: [
            formatGroupPrivacy(group.privacy),
            if (group.settings.requirePostApproval) 'Posts require approval',
            if (!group.settings.allowMemberPosts) 'Only admins can post',
          ],
        ),
        if (group.capabilities.canModerate) ...[
          if (_loadingAnalytics)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: GroupAnalyticsSectionShimmer(),
            )
          else
            _Section(
              theme: theme,
              title: 'Analytics',
              child: _AnalyticsGrid(
                theme: theme,
                items: [
                  _Kpi('Members', group.membersCount, '${_memberCounts['active'] ?? group.membersCount} active'),
                  _Kpi('Posts', group.postsCount, '${_postCounts['approved'] ?? group.postsCount} approved'),
                  _Kpi('Polls', group.pollsCount, 'Group polls'),
                  _Kpi('Pending', _postCounts['pending'] ?? 0, 'Awaiting review'),
                ],
              ),
            ),
        ],
        if (group.description?.trim().isNotEmpty == true)
          _Section(theme: theme, title: 'About', body: group.description!.trim()),
        if (group.communityGuidelines?.trim().isNotEmpty == true)
          _Section(theme: theme, title: 'Guidelines', body: group.communityGuidelines!.trim()),
        if (group.capabilities.canManage || group.capabilities.canModerate) ...[
          const SizedBox(height: 4),
          Text(
            'Manage',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textPrimary),
          ),
          const SizedBox(height: 10),
          if (_loadingModeration)
            const GroupModerationSectionShimmer()
          else if (_pendingPosts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: theme.cardDecoration,
              child: Text(
                'No posts waiting for moderation.',
                style: TextStyle(color: theme.textSecondary),
              ),
            )
          else
            ..._pendingPosts.map((post) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: theme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.displayText.isEmpty ? 'Media post' : post.displayText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Reject',
                            height: 36,
                            color: theme.surfaceVariant,
                            textColor: theme.textPrimary,
                            onTap: () => _reviewPost(post.id, 'rejected'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            text: 'Approve',
                            height: 36,
                            onTap: () => _reviewPost(post.id, 'approved'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
    ];

    if (widget.nested) {
      return GroupNestedTabScroll(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate(children)),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  String _privacyDescription(String privacy) {
    switch (privacy) {
      case 'private':
        return 'Only members can see posts and member list. Join requests are reviewed by admins.';
      case 'invitation_only':
        return 'People can only join when invited by a group admin or moderator.';
      default:
        return 'Anyone can discover this group and see public content. Members can post and interact.';
    }
  }
}

class _Kpi {
  final String label;
  final int value;
  final String meta;

  const _Kpi(this.label, this.value, this.meta);
}

class _AnalyticsGrid extends StatelessWidget {
  final OneUITheme theme;
  final List<_Kpi> items;

  const _AnalyticsGrid({required this.theme, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: items.map((kpi) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kpi.label, style: TextStyle(fontSize: 12, color: theme.textSecondary)),
              const Spacer(),
              Text(
                '${kpi.value}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.textPrimary),
              ),
              Text(kpi.meta, style: TextStyle(fontSize: 11, color: theme.textTertiary)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Section extends StatelessWidget {
  final OneUITheme theme;
  final String title;
  final String? body;
  final List<String>? chips;
  final Widget? child;

  const _Section({
    required this.theme,
    required this.title,
    this.body,
    this.chips,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: theme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: theme.textPrimary)),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!, style: TextStyle(color: theme.textSecondary, height: 1.45)),
            ],
            if (chips != null && chips!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: chips!
                    .map(
                      (c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(c, style: TextStyle(fontSize: 11, color: theme.textSecondary)),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (child != null) ...[
              const SizedBox(height: 12),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
