import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/network_widgets.dart';
import 'package:doctak_app/presentation/network_screen/bloc/network_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/widgets/one_ui_shimmer.dart';
import 'package:doctak_app/presentation/organization_profile/organization_profile_screen.dart';

class OrganizationsDiscoverScreen extends StatefulWidget {
  const OrganizationsDiscoverScreen({super.key});

  @override
  State<OrganizationsDiscoverScreen> createState() =>
      _OrganizationsDiscoverScreenState();
}

class _OrganizationsDiscoverScreenState
    extends State<OrganizationsDiscoverScreen> {
  final NetworkBloc _bloc = NetworkBloc();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  String _currentQuery = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _bloc.add(const LoadOrganizationsEvent());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_bloc.organizationsHasMore && !_bloc.isLoadingMore) {
        _bloc.add(
          LoadOrganizationsEvent(
            page: _bloc.organizationsPage + 1,
            search: _currentQuery,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    setState(() => _currentQuery = query.trim());
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _bloc.add(LoadOrganizationsEvent(search: _currentQuery));
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _currentQuery = '');
    _bloc.add(const LoadOrganizationsEvent());
  }

  void _openOrganization(Map<String, dynamic> org) {
    final slug = org['slug']?.toString();
    final id = org['id']?.toString() ?? '';
    final identifier = (slug != null && slug.isNotEmpty) ? slug : id;
    if (identifier.isEmpty) return;
    OrganizationProfileScreen(identifier: identifier).launch(
      context,
      pageRouteAnimation: PageRouteAnimation.Slide,
    );
  }

  void _toggleFollow(Map<String, dynamic> org) {
    _bloc.add(
      ToggleOrganizationFollowEvent(
        organizationId: org['id']?.toString() ?? '',
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(
          title: 'Organizations',
          titleFontSize: NetworkTypography.screenTitle,
          titleFontWeight: FontWeight.w700,
          onBackPressed: () => Navigator.pop(context),
          actions: [
            NetworkViewToggleGroup(
              isGridView: _isGridView,
              onChanged: (isGrid) => setState(() => _isGridView = isGrid),
            ),
            const SizedBox(width: 12),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildSearchBar(theme),
            ),
          ),
        ),
        body: BlocListener<NetworkBloc, NetworkState>(
          bloc: _bloc,
          listener: (context, state) {
            if (state is NetworkActionSuccessState) {
              toast(state.message);
            } else if (state is NetworkErrorState) {
              toast(state.message);
            }
          },
          child: BlocBuilder<NetworkBloc, NetworkState>(
            bloc: _bloc,
            builder: (context, state) {
              final items = _bloc.organizations;
              final isLoading =
                  !_bloc.hasLoadedOrganizations && items.isEmpty;

              if (isLoading) {
                return _isGridView
                    ? _buildGridShimmer(theme)
                    : _buildListShimmer(theme);
              }

              if (items.isEmpty) {
                return _buildEmptyState(theme);
              }

              return RefreshIndicator(
                color: theme.primary,
                onRefresh: () async {
                  _bloc.add(LoadOrganizationsEvent(search: _currentQuery));
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: _isGridView
                    ? _buildGridView(theme, items)
                    : _buildListView(theme, items),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(OneUITheme theme) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: theme.radiusFull,
        border: Border.all(color: theme.inputBorder),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: theme.bodyMedium.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search hospitals, clinics, recruiters...',
          hintStyle: theme.bodySecondary.copyWith(fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
            child: Icon(
              CupertinoIcons.search,
              size: 18,
              color: theme.textTertiary,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 16, color: theme.textSecondary),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildEmptyState(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 48,
              color: theme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _currentQuery.isNotEmpty
                  ? 'No organizations found'
                  : 'No organizations to show yet',
              style: theme.titleSmall.copyWith(
                fontSize: NetworkTypography.sectionTitle,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(OneUITheme theme, List<Map<String, dynamic>> items) {
    final showLoadMore = _bloc.organizationsHasMore && _bloc.isLoadingMore;
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: items.length + (showLoadMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return _buildGridShimmerCard(theme);
        }
        final org = items[index];
        return NetworkOrganizationGridCard(
          organization: org,
          onFollowToggle: () => _toggleFollow(org),
          onOpen: () => _openOrganization(org),
        );
      },
    );
  }

  Widget _buildListView(OneUITheme theme, List<Map<String, dynamic>> items) {
    final showLoadMore = _bloc.organizationsHasMore && _bloc.isLoadingMore;
    final total = items.length + (showLoadMore ? 2 : 0);
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: total,
      separatorBuilder: (_, index) {
        if (index >= items.length - 1) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.only(start: 72),
          child: Divider(color: theme.divider, height: 1),
        );
      },
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return _buildListShimmerTile(theme);
        }
        final org = items[index];
        return NetworkOrganizationListTile(
          organization: org,
          onFollowToggle: () => _toggleFollow(org),
          onOpen: () => _openOrganization(org),
        );
      },
    );
  }

  Widget _buildGridShimmer(OneUITheme theme) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _buildGridShimmerCard(theme),
    );
  }

  Widget _buildGridShimmerCard(OneUITheme theme) {
    final base = theme.shimmerBase;
    return OneUIShimmer(
      child: Container(
        decoration: networkSurfaceCard(theme),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: base,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 12, width: 90, color: base),
            const SizedBox(height: 6),
            Container(height: 10, width: 70, color: base),
            const Spacer(),
            Container(
              height: 30,
              width: double.infinity,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListShimmer(OneUITheme theme) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: 8,
      itemBuilder: (_, __) => _buildListShimmerTile(theme),
    );
  }

  Widget _buildListShimmerTile(OneUITheme theme) {
    final base = theme.shimmerBase;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: OneUIShimmer(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: base,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 120, color: base),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 90, color: base),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
