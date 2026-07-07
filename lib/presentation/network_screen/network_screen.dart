import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/network_screen/bloc/network_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/profile_list_item_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

class NetworkScreen extends StatefulWidget {
  final int initialTab;
  final String viewUserId;
  const NetworkScreen({super.key, this.initialTab = 0, this.viewUserId = ''});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final NetworkBloc _bloc = NetworkBloc();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    preloadSpecialties().then((_) {
      if (mounted) setState(() {});
    });
    _bloc.add(LoadConnectionsEvent(viewUserId: widget.viewUserId));
    _scrollController.addListener(_onScroll);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _bloc.add(LoadConnectionsEvent(
      search: _searchCtrl.text,
      viewUserId: widget.viewUserId,
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_bloc.connectionsHasMore && !_bloc.isLoadingMore) {
        _bloc.add(LoadConnectionsEvent(
          search: _searchCtrl.text,
          page: _bloc.connectionsPage + 1,
          viewUserId: widget.viewUserId,
        ));
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _scrollController.dispose();
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
          if (state is NetworkActionSuccessState) toast(state.message);
          if (state is NetworkErrorState) toast(state.message);
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackground,
          body: BlocBuilder<NetworkBloc, NetworkState>(
            bloc: _bloc,
            builder: (context, state) {
              final bloc = _bloc;
              final isLoading = state is NetworkLoadingState &&
                  bloc.activeLoadType == 'connections';
              return Column(
                children: [
                  // ── AppBar inside body (same pattern as FollowerScreen) ──
                  _ConnectionsAppBar(count: bloc.connections.length),
                  // ── Search bar sharing same cardBackground ──
                  Container(
                    color: theme.cardBackground,
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.inputBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(fontSize: 13.5, color: theme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search connections...',
                          hintStyle: TextStyle(fontSize: 13, color: theme.textSecondary),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: theme.textSecondary,
                          ),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchCtrl,
                            builder: (_, val, __) => val.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: theme.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _bloc.add(LoadConnectionsEvent(
                                        viewUserId: widget.viewUserId,
                                      ));
                                    },
                                  )
                                : const SizedBox.shrink(),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  // ── Connections list ──────────────────────
                  Expanded(
                    child: _buildList(context, state, bloc, isLoading),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, NetworkState state, NetworkBloc bloc, bool isLoading) {
    if (isLoading || !bloc.hasLoadedConnections) {
      return const ProfileListShimmer();
    }
    final items = bloc.connections;
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.people_outline_rounded,
        message: 'No connections yet',
        onRetry: () => bloc.add(LoadConnectionsEvent(viewUserId: widget.viewUserId)),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      key: const PageStorageKey<String>('connections_list'),
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      physics: const BouncingScrollPhysics(),
      cacheExtent: 500,
      itemCount: items.length + (bloc.connectionsHasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= items.length) return const _LoadMoreIndicator();
        final person = items[i];
        return _ConnectionCard(
          name: _resolveName(person),
          specialty: _resolveSpecialty(person),
          avatarUrl: AppData.fullImageUrl(person['profile_pic'] as String?),
          userId: person['id']?.toString() ?? '',
          isVerified: person['is_verified'] == true || person['is_verified'] == 1,
          onRemove: () => _confirmRemove(context, bloc, person),
        );
      },
    );
  }

  void _confirmRemove(BuildContext context, NetworkBloc bloc,
      Map<String, dynamic> person) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Connection'),
        content: Text('Remove ${_resolveName(person)} from your connections?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              bloc.add(RemoveConnectionEvent(
                  userId: person['id']?.toString() ?? ''));
              Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Specialty resolver ───────────────────────────────────────────────────
String _resolveSpecialty(Map<String, dynamic> person) {
  final raw = (person['specialty'] ?? person['speciality'] ?? person['title'] ?? '')
      .toString()
      .trim();
  return specialtyLabelOrNull(raw) ?? '';
}

// ── Name resolver ────────────────────────────────────────────────────────
String _resolveName(Map<String, dynamic> person) {
  final fullName =
      (person['fullName'] ?? person['name'] ?? '').toString().trim();
  if (fullName.isNotEmpty) return fullName;
  final firstLast =
      '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'.trim();
  if (firstLast.isNotEmpty) return firstLast;
  final username = (person['username'] ?? '').toString().trim();
  if (username.isNotEmpty) return username;
  return 'Unknown';
}

// ═══════════════════════════════════════════════════════
//  CUSTOM APP BAR
// ═══════════════════════════════════════════════════════
class _ConnectionsAppBar extends StatelessWidget {
  final int count;
  const _ConnectionsAppBar({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return DoctakAppBar(
      title: 'Connections',
      titleIcon: Icons.people_outline_rounded,
      actions: [
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          icon: Icon(CupertinoIcons.search, size: 20, color: theme.iconColor),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  CONNECTION CARD  (matches screenshot)
// ═══════════════════════════════════════════════════════
class _ConnectionCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String? avatarUrl;
  final String userId;
  final bool isVerified;
  final VoidCallback onRemove;

  const _ConnectionCard({
    required this.name,
    required this.specialty,
    required this.avatarUrl,
    required this.userId,
    required this.isVerified,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileListItemCard(
      title: name,
      subtitle: specialty.isNotEmpty ? capitalizeWords(specialty) : null,
      metaText: '✓ Connected',
      avatarUrl: avatarUrl,
      titleSuffix: isVerified ? const VerifiedBadge(size: 15) : null,
      onTap: () => ProfileNavigation.openUser(context, userId),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: OneUITheme.of(context).textSecondary),
        onSelected: (v) {
          if (v == 'remove') onRemove();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'remove',
            child: Text('Remove Connection'),
          ),
        ],
      ),
    );
  }
}

// ── Load more indicator ───────────────────────────────────────────────────
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

// ── Empty state ───────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;
  const _EmptyState(
      {required this.icon, required this.message, this.onRetry});

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
              label: Text('Retry',
                  style: TextStyle(
                      fontFamily: 'Poppins', color: theme.primary)),
            ),
          ],
        ],
      ),
    );
  }
}
