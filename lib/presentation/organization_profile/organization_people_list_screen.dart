import 'package:doctak_app/data/apiClient/services/organization_profile_api_service.dart';
import 'package:doctak_app/data/models/organization_profile/organization_public_profile_model.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/profile_list_item_card.dart';
import 'package:flutter/material.dart';

/// Lists users who follow an organization or are members of it.
class OrganizationPeopleListScreen extends StatefulWidget {
  const OrganizationPeopleListScreen({
    required this.organizationId,
    required this.kind,
    this.initialCount,
    super.key,
  });

  final String organizationId;
  final OrganizationPeopleListKind kind;
  final int? initialCount;

  @override
  State<OrganizationPeopleListScreen> createState() =>
      _OrganizationPeopleListScreenState();
}

class _OrganizationPeopleListScreenState
    extends State<OrganizationPeopleListScreen> {
  final OrganizationProfileApiService _api = OrganizationProfileApiService();
  final ScrollController _scrollController = ScrollController();
  final List<OrganizationPersonSummary> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _error = false;
  int _page = 1;
  int _total = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _total = widget.initialCount ?? 0;
    _scrollController.addListener(_onScroll);
    _load(page: 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading || _loadingMore) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 240) {
      return;
    }
    _load(page: _page + 1);
  }

  Future<void> _load({required int page}) async {
    if (page > 1) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = false;
      });
    }

    try {
      final result = await _api.getOrganizationPeople(
        organizationId: widget.organizationId,
        kind: widget.kind,
        page: page,
      );

      if (!mounted) return;
      setState(() {
        if (page == 1) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          final seen = _items.map((item) => item.userId).toSet();
          _items.addAll(
            result.items.where((item) => !seen.contains(item.userId)),
          );
        }
        _page = result.page;
        _total = result.total;
        _hasMore = result.hasMore;
        _loading = false;
        _loadingMore = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = _items.isEmpty;
      });
    }
  }

  String get _title =>
      widget.kind == OrganizationPeopleListKind.followers
          ? 'Followers'
          : 'Members';

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final countLabel = _formatCount(_total > 0 ? _total : widget.initialCount ?? 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          DoctakAppBar(
            title: _title,
            titleIcon: widget.kind == OrganizationPeopleListKind.followers
                ? Icons.people_rounded
                : Icons.groups_rounded,
            actions: [
              if (countLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        countLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(OneUITheme theme) {
    if (_loading) {
      return const ProfileListShimmer();
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Could not load $_title', style: theme.titleSmall),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _load(page: 1),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.kind == OrganizationPeopleListKind.followers
                  ? Icons.people_outline_rounded
                  : Icons.groups_outlined,
              size: 48,
              color: theme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              widget.kind == OrganizationPeopleListKind.followers
                  ? 'No followers yet'
                  : 'No members yet',
              style: theme.titleSmall,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(page: 1),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: 4,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          }

          final person = _items[index];
          final subtitle = widget.kind == OrganizationPeopleListKind.members
              ? (person.role ?? 'Member')
              : (person.username != null && person.username!.isNotEmpty
                  ? '@${person.username}'
                  : 'Follower');

          return ProfileListItemCard(
            title: person.name,
            subtitle: subtitle,
            avatarUrl: person.profilePic ?? '',
            onTap: () =>
                ProfileNavigation.openUser(context, person.userId),
          );
        },
      ),
    );
  }
}

String _formatCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return '$value';
}
