import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/network_screen/bloc/network_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

class NetworkScreen extends StatefulWidget {
  final int initialTab;
  const NetworkScreen({super.key, this.initialTab = 0});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NetworkBloc _bloc = NetworkBloc();
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _selectIndex = widget.initialTab;
    _tabController.addListener(_onTabChanged);
    _loadCurrentTab();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectIndex = _tabController.index;
      });
      _searchCtrl.clear();
      _loadCurrentTab();
    }
  }

  void _loadCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _bloc.add(const LoadSuggestionsEvent());
        break;
      case 1:
        _bloc.add(const LoadFriendRequestsEvent(type: 'received'));
        break;
      case 2:
        _bloc.add(const LoadFriendRequestsEvent(type: 'sent'));
        break;
      case 3:
        _bloc.add(LoadConnectionsEvent(search: _searchCtrl.text));
        break;
    }
  }

  void _onSearch(String query) {
    switch (_tabController.index) {
      case 0:
        _bloc.add(LoadSuggestionsEvent(search: query));
        break;
      case 1:
        _bloc.add(LoadFriendRequestsEvent(type: 'received', search: query));
        break;
      case 2:
        _bloc.add(LoadFriendRequestsEvent(type: 'sent', search: query));
        break;
      case 3:
        _bloc.add(LoadConnectionsEvent(search: query));
        break;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<NetworkBloc, NetworkState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is NetworkActionSuccessState) {
            toast(state.message);
          } else if (state is NetworkErrorState) {
            toast(state.message);
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackground,
          appBar: DoctakSearchableAppBar(
            title: 'Network',
            searchHint: 'Search network...',
            searchController: _searchCtrl,
            onSearchChanged: _onSearch,
            startWithSearch: false,
            showBackButton: true,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildTabWidget(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabWidget(OneUITheme theme) {
    return Expanded(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            height: 52,
            decoration: BoxDecoration(
              color: theme.inputBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.border, width: 0.5),
            ),
            child: TabBar(
              controller: _tabController,
              dividerHeight: 0,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.primary.withValues(alpha: 0.85)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              unselectedLabelColor: theme.textSecondary,
              labelColor: Colors.white,
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              labelPadding: EdgeInsets.zero,
              tabs: [
                _buildTabItem(
                  icon: Icons.person_search_rounded,
                  label: 'Suggestions',
                  isSelected: _selectIndex == 0,
                  theme: theme,
                ),
                _buildTabItem(
                  icon: Icons.mail_outline_rounded,
                  label: 'Requests',
                  isSelected: _selectIndex == 1,
                  theme: theme,
                ),
                _buildTabItem(
                  icon: Icons.send_rounded,
                  label: 'Sent',
                  isSelected: _selectIndex == 2,
                  theme: theme,
                ),
                _buildTabItem(
                  icon: Icons.people_outline_rounded,
                  label: 'Connections',
                  isSelected: _selectIndex == 3,
                  theme: theme,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _SuggestionsTab(bloc: _bloc, searchQuery: _searchCtrl.text),
                _RequestsTab(bloc: _bloc, type: 'received', searchQuery: _searchCtrl.text),
                _RequestsTab(bloc: _bloc, type: 'sent', searchQuery: _searchCtrl.text),
                _ConnectionsTab(bloc: _bloc, searchQuery: _searchCtrl.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required OneUITheme theme,
  }) {
    return Tab(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(3),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: theme.primary),
              ),
            Text(
              label,
              style: TextStyle(fontSize: isSelected ? 12 : 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SUGGESTIONS TAB (People You May Know)
// ═══════════════════════════════════════════════════════
class _SuggestionsTab extends StatefulWidget {
  final NetworkBloc bloc;
  final String searchQuery;
  const _SuggestionsTab({required this.bloc, this.searchQuery = ''});

  @override
  State<_SuggestionsTab> createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends State<_SuggestionsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = widget.bloc;
      if (bloc.suggestionsHasMore && !bloc.isLoadingMore) {
        bloc.add(LoadSuggestionsEvent(
          search: widget.searchQuery,
          page: bloc.suggestionsPage + 1,
        ));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return BlocBuilder<NetworkBloc, NetworkState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final bloc = widget.bloc;
        // Show shimmer only when this specific tab is loading (first page)
        final isLoading =
            state is NetworkLoadingState &&
            bloc.activeLoadType == 'suggestions';
        if (isLoading || !bloc.hasLoadedSuggestions) {
          return const ProfileListShimmer();
        }
        final items = bloc.suggestions;
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.person_search_rounded,
            message: 'No suggestions right now',
            onRetry: () => bloc.add(const LoadSuggestionsEvent()),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          key: const PageStorageKey<String>('suggestions_list'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const ClampingScrollPhysics(),
          cacheExtent: 500,
          itemCount: items.length + (bloc.suggestionsHasMore ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i >= items.length) {
              return const _LoadMoreIndicator();
            }
            final person = items[i];
            final mutualCount = person['mutualCount'] ?? person['mutual_count'];
            return _PersonCard(
              name:
                  person['fullName'] as String? ??
                  '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'
                      .trim(),
              specialty: person['specialty'] as String? ?? '',
              avatarUrl:
                  AppData.fullImageUrl(person['profilePicUrl'] as String? ??
                  person['profile_pic'] as String?),
              subtitle: mutualCount != null && mutualCount != 0
                  ? '$mutualCount mutual connections'
                  : person['country'] as String? ?? '',
              userId: person['id']?.toString() ?? '',
              trailing: (person['friendRequestSent'] == true)
                  ? _ActionButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      color: theme.error,
                      onTap: () => bloc.add(
                        CancelFriendRequestEvent(
                          requestId:
                              person['friendRequestId']?.toString() ?? '',
                          userId: person['id']?.toString() ?? '',
                        ),
                      ),
                    )
                  : _ActionButton(
                      label: 'Connect',
                      icon: Icons.person_add_rounded,
                      color: theme.primary,
                      onTap: () => bloc.add(
                        SendFriendRequestEvent(
                          userId: person['id']?.toString() ?? '',
                        ),
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  REQUESTS TAB (Received / Sent)
// ═══════════════════════════════════════════════════════
class _RequestsTab extends StatefulWidget {
  final NetworkBloc bloc;
  final String type;
  final String searchQuery;
  const _RequestsTab({required this.bloc, required this.type, this.searchQuery = ''});

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = widget.bloc;
      if (bloc.requestsHasMore && !bloc.isLoadingMore) {
        bloc.add(LoadFriendRequestsEvent(
          type: widget.type,
          search: widget.searchQuery,
          page: bloc.requestsPage + 1,
        ));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return BlocBuilder<NetworkBloc, NetworkState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final bloc = widget.bloc;
        // Show shimmer only when this specific tab is loading
        final isLoading =
            state is NetworkLoadingState && bloc.activeLoadType == widget.type;
        if (isLoading || !bloc.hasLoadedRequests) {
          return const ProfileListShimmer();
        }
        final items = bloc.friendRequests;
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.mail_outline_rounded,
            message: widget.type == 'received'
                ? 'No pending friend requests'
                : 'No sent requests',
            onRetry: () => bloc.add(LoadFriendRequestsEvent(type: widget.type)),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          key: const PageStorageKey<String>('requests_list'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const ClampingScrollPhysics(),
          cacheExtent: 500,
          itemCount: items.length + (bloc.requestsHasMore ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i >= items.length) {
              return const _LoadMoreIndicator();
            }
            final request = items[i];
            // For received requests, the sender is the other person
            // For sent requests, the receiver is the other person
            final person = widget.type == 'received'
                ? request['sender'] as Map<String, dynamic>? ?? request
                : request['receiver'] as Map<String, dynamic>? ?? request;
            final requestId = request['id']?.toString() ?? '0';

            return _PersonCard(
              name: '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'
                  .trim(),
              specialty: person['specialty'] as String? ?? '',
              avatarUrl: AppData.fullImageUrl(person['profile_pic'] as String?),
              subtitle: request['created_at'] != null
                  ? 'Sent ${_formatDate(request['created_at'].toString())}'
                  : '',
              userId: person['id']?.toString() ?? '',
              trailing: widget.type == 'received'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          label: 'Accept',
                          icon: Icons.check_rounded,
                          color: theme.success,
                          onTap: () => bloc.add(
                            AcceptFriendRequestEvent(requestId: requestId),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          label: 'Reject',
                          icon: Icons.close_rounded,
                          color: theme.error,
                          onTap: () => bloc.add(
                            RejectFriendRequestEvent(requestId: requestId),
                          ),
                        ),
                      ],
                    )
                  : _ActionButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      color: theme.error,
                      onTap: () => bloc.add(
                        CancelFriendRequestEvent(requestId: requestId),
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════
//  CONNECTIONS TAB
// ═══════════════════════════════════════════════════════
class _ConnectionsTab extends StatefulWidget {
  final NetworkBloc bloc;
  final String searchQuery;
  const _ConnectionsTab({required this.bloc, this.searchQuery = ''});

  @override
  State<_ConnectionsTab> createState() => _ConnectionsTabState();
}

class _ConnectionsTabState extends State<_ConnectionsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final bloc = widget.bloc;
      if (bloc.connectionsHasMore && !bloc.isLoadingMore) {
        bloc.add(LoadConnectionsEvent(
          search: widget.searchQuery,
          page: bloc.connectionsPage + 1,
        ));
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return BlocBuilder<NetworkBloc, NetworkState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final bloc = widget.bloc;
        // Show shimmer only when this specific tab is loading
        final isLoading =
            state is NetworkLoadingState &&
            bloc.activeLoadType == 'connections';
        if (isLoading || !bloc.hasLoadedConnections) {
          return const ProfileListShimmer();
        }
        final items = bloc.connections;
        if (items.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outline_rounded,
            message: 'No connections yet',
            onRetry: () => bloc.add(const LoadConnectionsEvent()),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          key: const PageStorageKey<String>('connections_list'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const ClampingScrollPhysics(),
          cacheExtent: 500,
          itemCount: items.length + (bloc.connectionsHasMore ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i >= items.length) {
              return const _LoadMoreIndicator();
            }
            final person = items[i];
            return _PersonCard(
              name: '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'
                  .trim(),
              specialty: person['specialty'] as String? ?? '',
              avatarUrl: AppData.fullImageUrl(person['profile_pic'] as String?),
              subtitle: person['country'] as String? ?? '',
              userId: person['id']?.toString() ?? '',
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.textSecondary),
                onSelected: (v) {
                  if (v == 'remove') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove Connection'),
                        content: Text(
                          'Remove ${person['first_name']} from your connections?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              bloc.add(
                                RemoveConnectionEvent(
                                  userId: person['id']?.toString() ?? '',
                                ),
                              );
                              Navigator.pop(ctx);
                            },
                            child: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove Connection'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SHARED COMPONENTS
// ═══════════════════════════════════════════════════════

class _PersonCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String? avatarUrl;
  final String subtitle;
  final String userId;
  final Widget trailing;

  const _PersonCard({
    required this.name,
    required this.specialty,
    required this.avatarUrl,
    required this.subtitle,
    required this.userId,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: theme.cardDecoration,
      child: ClipRRect(
        borderRadius: theme.radiusL,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          color: theme.cardBackground,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          // Profile Picture — same as SVSearchCardComponent
          GestureDetector(
            onTap: () => SVProfileFragment(userId: userId)
                .launch(context, pageRouteAnimation: PageRouteAnimation.Slide),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.avatarBorder, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primary.withValues(alpha: 0.15),
                              theme.secondary.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                            style: TextStyle(
                              color: theme.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: avatarUrl!,
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: theme.avatarBackground,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: theme.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: theme.avatarBackground,
                          child: Center(
                            child: Icon(Icons.person, color: theme.primary, size: 28),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Info — same as SVSearchCardComponent
          Expanded(
            child: GestureDetector(
              onTap: () => SVProfileFragment(userId: userId)
                  .launch(context, pageRouteAnimation: PageRouteAnimation.Slide),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name.isNotEmpty ? name : 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  if (specialty.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      capitalizeWords(specialty),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySecondary,
                    ),
                  ],
                  if (subtitle.isNotEmpty && subtitle != specialty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: theme.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Action button
          trailing,
        ],
      ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bool isFilled = label == 'Connect' || label == 'Accept';
    return InkWell(
      onTap: onTap,
      borderRadius: theme.radiusFull,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isFilled
              ? LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isFilled ? null : color.withValues(alpha: 0.1),
          borderRadius: theme.radiusFull,
          border: Border.all(
            color: isFilled ? Colors.transparent : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isFilled ? Colors.white : color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _EmptyState({required this.icon, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.textTertiary),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: theme.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: theme.primary),
              label: Text(
                'Retry',
                style: TextStyle(fontFamily: 'Poppins', color: theme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
