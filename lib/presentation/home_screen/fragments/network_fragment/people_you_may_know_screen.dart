import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/location_display.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/network_widgets.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/network_screen/bloc/network_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/widgets/one_ui_shimmer.dart';

import '../../../../localization/app_localization.dart';

/// ═══════════════════════════════════════════════════════
///  PEOPLE YOU MAY KNOW — Full screen with Grid / List toggle
///  Uses One UI 8.5 design system + DoctakAppBar.
///  Supports search, filtering, pagination, and view switching.
/// ═══════════════════════════════════════════════════════
class PeopleYouMayKnowScreen extends StatefulWidget {
  final String? initialSearch;
  final String initialEntityScope;
  const PeopleYouMayKnowScreen({
    super.key,
    this.initialSearch,
    this.initialEntityScope = 'all',
  });

  @override
  State<PeopleYouMayKnowScreen> createState() =>
      _PeopleYouMayKnowScreenState();
}

class _PeopleYouMayKnowScreenState extends State<PeopleYouMayKnowScreen> {
  final NetworkBloc _bloc = NetworkBloc();
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  String _currentQuery = '';
  String _entityScope = 'all';
  String _selectedSpecialty = '';
  String _selectedCountry = '';
  List<dynamic> _specialties = [];
  List<dynamic> _countries = [];
  bool _filtersLoaded = false;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    // If opened with a search query, pre-fill and trigger search
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _currentQuery = widget.initialSearch!;
      _searchCtrl.text = widget.initialSearch!;
      _entityScope = widget.initialEntityScope;
      _bloc.add(NetworkSearchEvent(
        query: _currentQuery,
        scope: _entityScope,
      ));
    } else {
      _bloc.add(const LoadSuggestionsEvent());
    }
    _scrollCtrl.addListener(_onScroll);
    preloadSpecialties().then((_) {
      if (mounted) setState(() {});
    });
    preloadLocations().then((_) {
      if (mounted) setState(() {});
    });
    _loadFilters();
  }

  bool get _hasFilters =>
      _selectedSpecialty.isNotEmpty || _selectedCountry.isNotEmpty;
  bool get _isSearchMode => _currentQuery.isNotEmpty || _hasFilters;

  /// Header height: search bar (44) + 10 gap + optional scope bar (36+10) + filter row (36) + 12 bottom
  double get _headerContentHeight {
    double h = 44 + 10 + 36 + 12; // search + gap + filter row + bottom pad
    if (_isSearchMode) h += 36 + 10; // scope bar + gap
    return h;
  }
  Future<void> _loadFilters() async {
    try {
      final sharedApi = SharedApiService();
      final specialtyResult = await sharedApi.getSpecialty();
      final countryResult = await sharedApi.getCountries();
      if (!mounted) return;
      setState(() {
        if (specialtyResult.success && specialtyResult.data != null) {
          _specialties = specialtyResult.data!;
        }
        if (countryResult.success && countryResult.data != null) {
          _countries = countryResult.data!.countries ?? [];
        }
        _filtersLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _filtersLoaded = true);
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (_bloc.isLoadingMore) return;
      if (_isSearchMode) {
        if (_bloc.searchHasMore) {
          _bloc.add(NetworkSearchEvent(
            query: _currentQuery,
            page: _bloc.searchPage + 1,
            specialty: _selectedSpecialty,
            country: _selectedCountry,
            scope: _entityScope,
          ));
        }
      } else {
        if (_bloc.suggestionsHasMore) {
          _bloc.add(LoadSuggestionsEvent(page: _bloc.suggestionsPage + 1));
        }
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    setState(() => _currentQuery = query.trim());
    _debounce = Timer(const Duration(milliseconds: 400), _triggerSearch);
  }

  void _triggerSearch() {
    if (!_isSearchMode) {
      if (_bloc.suggestions.isEmpty) {
        _bloc.add(const LoadSuggestionsEvent());
      }
      return;
    }
    _bloc.add(NetworkSearchEvent(
      query: _currentQuery,
      specialty: _selectedSpecialty,
      country: _selectedCountry,
      scope: _entityScope,
    ));
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _currentQuery = '');
    _triggerSearch();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedSpecialty = '';
      _selectedCountry = '';
    });
    _triggerSearch();
  }

  void _navigateToProfile(Map<String, dynamic> person) {
    ProfileNavigation.openFromMap(context, person);
  }

  void _openOrganization(Map<String, dynamic> org) {
    ProfileNavigation.openFromMap(context, org);
  }

  void _openSearchResultItem(Map<String, dynamic> item) {
    ProfileNavigation.openFromMap(context, item);
  }

  void _onEntityScopeChanged(String scope) {
    if (_entityScope == scope) return;
    setState(() => _entityScope = scope);
    if (_isSearchMode) {
      _triggerSearch();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    _bloc.close();
    super.dispose();
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(
          title: translation(context).lbl_people_you_may_know,
          actions: [
            _buildViewToggleGroup(theme),
            const SizedBox(width: 12),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(_headerContentHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchBar(theme),
                  const SizedBox(height: 10),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topLeft,
                    child: _isSearchMode
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NetworkEntityScopeBar(
                                selectedScope: _entityScope,
                                peopleCount: _bloc.searchPeopleCount,
                                organizationCount: _bloc.searchOrganizationCount,
                                onChanged: _onEntityScopeChanged,
                              ),
                              const SizedBox(height: 10),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  _buildFilterRow(theme),
                ],
              ),
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
              final items =
                  _isSearchMode ? _bloc.searchResults : _bloc.suggestions;
              final isLoading = _isSearchMode
                  ? (state is NetworkLoadingState &&
                      _bloc.searchResults.isEmpty)
                  : (!_bloc.hasLoadedSuggestions);

              if (isLoading && items.isEmpty) {
                return _isGridView
                    ? _buildGridShimmer(theme)
                    : const ProfileListShimmer();
              }

              if (items.isEmpty) {
                return _buildEmptyState(theme);
              }

              return RefreshIndicator(
                color: theme.primary,
                onRefresh: () async {
                  if (_isSearchMode) {
                    _bloc.add(NetworkSearchEvent(
                      query: _currentQuery,
                      specialty: _selectedSpecialty,
                      country: _selectedCountry,
                    ));
                  } else {
                    _bloc.add(const LoadSuggestionsEvent());
                  }
                  await Future.delayed(const Duration(milliseconds: 800));
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

  // ═══════════════════════════════════════════
  //  SEARCH BAR
  // ═══════════════════════════════════════════
  Widget _buildSearchBar(OneUITheme theme) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: theme.radiusFull,
        border: Border.all(color: theme.inputBorder),
      ),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: theme.bodyMedium.copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: translation(context).lbl_search_network,
          hintStyle: theme.bodySecondary.copyWith(fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
            child: Icon(CupertinoIcons.search,
                size: 20, color: theme.textTertiary),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.textTertiary.withValues(alpha: 0.2),
                    ),
                    child: Icon(Icons.close,
                        size: 14, color: theme.textSecondary),
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  FILTER ROW
  // ═══════════════════════════════════════════
  Widget _buildFilterRow(OneUITheme theme) {
    if (!_filtersLoaded) return const SizedBox.shrink();
    final showPeopleFilters = _entityScope != 'organizations';
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (showPeopleFilters) ...[
                  NetworkFilterChip(
                    icon: CupertinoIcons.briefcase,
                    label: _selectedSpecialty.isEmpty
                        ? translation(context).lbl_specialty
                        : _selectedSpecialty,
                    isActive: _selectedSpecialty.isNotEmpty,
                    onTap: () => showNetworkFilterSheet(
                      context: context,
                      title: translation(context).lbl_filter_by_specialty,
                      allLabel: translation(context).lbl_all_specialties,
                      items: _specialties,
                      selectedValue: _selectedSpecialty,
                      nameExtractor: (item) => item is Map
                          ? (item['name'] ?? '').toString()
                          : item.toString(),
                      onSelected: (value) {
                        setState(() => _selectedSpecialty = value);
                        _triggerSearch();
                      },
                    ),
                    onClear: _selectedSpecialty.isNotEmpty
                        ? () {
                            setState(() => _selectedSpecialty = '');
                            _triggerSearch();
                          }
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
                NetworkFilterChip(
                  icon: CupertinoIcons.globe,
                  label: _selectedCountry.isEmpty
                      ? translation(context).lbl_country
                      : _selectedCountry,
                  isActive: _selectedCountry.isNotEmpty,
                  onTap: () => showNetworkFilterSheet(
                    context: context,
                    title: translation(context).lbl_country,
                    allLabel: translation(context).lbl_all_countries,
                    items: _countries,
                    selectedValue: _selectedCountry,
                    nameExtractor: (item) => item is Map
                        ? (item['countryName'] ?? '').toString()
                        : item.toString(),
                    onSelected: (value) {
                      setState(() => _selectedCountry = value);
                      _triggerSearch();
                    },
                  ),
                  onClear: _selectedCountry.isNotEmpty
                      ? () {
                          setState(() => _selectedCountry = '');
                          _triggerSearch();
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (_hasFilters) ...[
          const SizedBox(width: 8),
          _buildClearAllButton(theme),
        ],
      ],
    );
  }

  Widget _buildClearAllButton(OneUITheme theme) {
    return GestureDetector(
      onTap: _clearAllFilters,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.error.withValues(alpha: 0.08),
          borderRadius: theme.radiusFull,
          border: Border.all(color: theme.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_off, size: 14, color: theme.error),
            const SizedBox(width: 4),
            Text(
              translation(context).lbl_clear_all,
              style: theme.caption.copyWith(
                color: theme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggleGroup(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: theme.radiusS,
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleButton(
            icon: CupertinoIcons.square_grid_2x2,
            isActive: _isGridView,
            onTap: () => setState(() => _isGridView = true),
          ),
          _ViewToggleButton(
            icon: CupertinoIcons.list_bullet,
            isActive: !_isGridView,
            onTap: () => setState(() => _isGridView = false),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════
  Widget _buildEmptyState(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withValues(alpha: 0.06),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              child: Icon(CupertinoIcons.person_2,
                  size: 38, color: theme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              _isSearchMode
                  ? translation(context).lbl_no_results_found
                  : translation(context).lbl_no_suggestions,
              style: theme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _isSearchMode
                  ? translation(context)
                      .msg_try_different_keywords_or_adjust_filters
                  : translation(context)
                      .msg_check_back_later_for_new_suggestions,
              textAlign: TextAlign.center,
              style: theme.bodySecondary,
            ),
            if (_hasFilters) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: Icon(Icons.filter_alt_off,
                    size: 18, color: theme.primary),
                label: Text(
                  translation(context).lbl_clear_filters,
                  style: theme.bodyMedium.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  GRID VIEW
  // ═══════════════════════════════════════════
  Widget _buildGridView(OneUITheme theme, List<Map<String, dynamic>> items) {
    final hasMore =
        _isSearchMode ? _bloc.searchHasMore : _bloc.suggestionsHasMore;
    final showLoadMoreShimmer = hasMore && _bloc.isLoadingMore;
    const loadMoreCount = 2;
    return GridView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length + (showLoadMoreShimmer ? loadMoreCount : 0),
      itemBuilder: (ctx, i) {
        if (i >= items.length) {
          return _buildGridLoadMoreShimmerCard(theme);
        }
        if (networkSearchItemIsOrganization(items[i])) {
          return NetworkOrganizationGridCard(
            organization: items[i],
            onFollowToggle: () => _bloc.add(
              ToggleOrganizationFollowEvent(
                organizationId: items[i]['id']?.toString() ?? '',
              ),
            ),
            onOpen: () => _openOrganization(items[i]),
          );
        }
        return NetworkUserGridCard(
          person: items[i],
          bloc: _bloc,
          onTap: () => _openSearchResultItem(items[i]),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  //  LIST VIEW
  // ═══════════════════════════════════════════
  Widget _buildListView(OneUITheme theme, List<Map<String, dynamic>> items) {
    final hasMore =
        _isSearchMode ? _bloc.searchHasMore : _bloc.suggestionsHasMore;
    final showLoadMoreShimmer = hasMore && _bloc.isLoadingMore;
    const loadMoreCount = 3;
    final totalCount = items.length + (showLoadMoreShimmer ? loadMoreCount : 0);
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: totalCount,
      separatorBuilder: (_, index) {
        if (index >= items.length - 1 || index >= totalCount - 1) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsetsDirectional.only(start: 78),
          child: Divider(color: theme.divider, height: 1),
        );
      },
      itemBuilder: (ctx, i) {
        if (i >= items.length) {
          return _buildListLoadMoreShimmerTile(theme);
        }
        if (networkSearchItemIsOrganization(items[i])) {
          return NetworkOrganizationListTile(
            organization: items[i],
            onFollowToggle: () => _bloc.add(
              ToggleOrganizationFollowEvent(
                organizationId: items[i]['id']?.toString() ?? '',
              ),
            ),
            onOpen: () => _openOrganization(items[i]),
          );
        }
        return NetworkUserListTile(
          person: items[i],
          bloc: _bloc,
          onTap: () => _navigateToProfile(items[i]),
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
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _buildGridLoadMoreShimmerCard(theme),
    );
  }

  Widget _buildGridLoadMoreShimmerCard(OneUITheme theme) {
    final base = theme.shimmerBase;
    return Container(
      decoration: theme.cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: OneUIShimmer(
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: base,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 14,
              width: 90,
              decoration: BoxDecoration(
                color: base,
                borderRadius: theme.radiusS,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 12,
              width: 70,
              decoration: BoxDecoration(
                color: base,
                borderRadius: theme.radiusS,
              ),
            ),
            const Spacer(),
            Container(
              height: 34,
              width: double.infinity,
              decoration: BoxDecoration(
                color: base,
                borderRadius: theme.radiusFull,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListLoadMoreShimmerTile(OneUITheme theme) {
    final base = theme.shimmerBase;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: OneUIShimmer(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: base,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 130,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: theme.radiusS,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 90,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: theme.radiusS,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 90,
              height: 32,
              decoration: BoxDecoration(
                color: base,
                borderRadius: theme.radiusFull,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  VIEW TOGGLE BUTTON
// ═══════════════════════════════════════════════════════
class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isActive
              ? theme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: theme.radiusXS,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? theme.primary : theme.textTertiary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED WIDGETS — reused by both this screen & network_tab
// ═══════════════════════════════════════════════════════════════

/// Shared filter bottom sheet for specialty / country selection
void showNetworkFilterSheet({
  required BuildContext context,
  required String title,
  required String allLabel,
  required List<dynamic> items,
  required String selectedValue,
  required String Function(dynamic item) nameExtractor,
  required ValueChanged<String> onSelected,
}) {
  final theme = OneUITheme.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      String filterText = '';
      return StatefulBuilder(builder: (ctx, setModalState) {
        final filtered = filterText.isEmpty
            ? items
            : items.where((item) {
                return nameExtractor(item)
                    .toLowerCase()
                    .contains(filterText.toLowerCase());
              }).toList();

        return Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: theme.elevatedShadow,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            minChildSize: 0.3,
            expand: false,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.border,
                    borderRadius: theme.radiusFull,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(title, style: theme.titleMedium)),
                      if (selectedValue.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            onSelected('');
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.error.withValues(alpha: 0.08),
                              borderRadius: theme.radiusFull,
                            ),
                            child: Text(
                              translation(context).lbl_clear,
                              style: theme.caption.copyWith(
                                color: theme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.inputBackground,
                      borderRadius: theme.radiusM,
                      border: Border.all(color: theme.inputBorder),
                    ),
                    child: TextField(
                      onChanged: (v) =>
                          setModalState(() => filterText = v),
                      style: theme.bodyMedium.copyWith(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: translation(context).lbl_search,
                        hintStyle:
                            theme.bodySecondary.copyWith(fontSize: 13),
                        prefixIcon: Icon(CupertinoIcons.search,
                            size: 18, color: theme.textSecondary),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 6),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${filtered.length} ${translation(context).lbl_results}',
                      style: theme.caption,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length + 1,
                    itemBuilder: (ctx, index) {
                      if (index == 0) {
                        return _FilterOptionTile(
                          label: allLabel,
                          isSelected: selectedValue.isEmpty,
                          onTap: () {
                            onSelected('');
                            Navigator.pop(ctx);
                          },
                        );
                      }
                      final name = nameExtractor(filtered[index - 1]);
                      return _FilterOptionTile(
                        label: name,
                        isSelected: selectedValue == name,
                        onTap: () {
                          onSelected(name);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

/// Filter option tile inside bottom sheets
class _FilterOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isSelected
            ? theme.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? theme.primary : theme.border,
                  width: isSelected ? 0 : 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: isSelected
                    ? theme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      )
                    : theme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter chip widget — used by both screens
class NetworkFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const NetworkFilterChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsetsDirectional.only(
          start: 10,
          end: onClear != null ? 4 : 10,
          top: 7,
          bottom: 7,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? theme.primary.withValues(alpha: 0.08)
              : theme.surfaceVariant,
          borderRadius: theme.radiusFull,
          border: Border.all(
            color: isActive
                ? theme.primary.withValues(alpha: 0.4)
                : theme.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? theme.primary : theme.textTertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.caption.copyWith(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? theme.primary : theme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 2),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primary.withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.close, size: 12, color: theme.primary),
                ),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isActive ? theme.primary : theme.textTertiary),
          ],
        ),
      ),
    );
  }
}

String _resolvePersonName(Map<String, dynamic> person) {
  final fullName =
      (person['fullName'] ?? person['name'] ?? '').toString().trim();
  if (fullName.isNotEmpty && fullName.toLowerCase() != 'unknown') {
    return fullName;
  }
  final firstLast =
      '${person['first_name'] ?? person['firstName'] ?? ''} ${person['last_name'] ?? person['lastName'] ?? ''}'
          .trim();
  if (firstLast.isNotEmpty) return firstLast;
  final username = (person['username'] ?? '').toString().trim();
  if (username.isNotEmpty) return username;
  return '';
}

/// Extracts common user data from person map
class NetworkUserData {
  final String name;
  final String specialty;
  final String location;
  final int mutualCount;
  final String? avatarUrl;
  final String status;
  final String requestId;
  final String userId;
  final bool isVerified;

  const NetworkUserData._({
    required this.name,
    required this.specialty,
    required this.location,
    required this.mutualCount,
    required this.avatarUrl,
    required this.status,
    required this.requestId,
    required this.userId,
    this.isVerified = false,
  });

  factory NetworkUserData.fromMap(Map<String, dynamic> person) {
    final name = _resolvePersonName(person);
    final specialty = networkPersonSpecialty(person);
    final location = networkPersonLocation(person);
    final mutualRaw = person['mutualCount'] ?? person['mutual_count'] ?? 0;
    final mutualCount =
        mutualRaw is int ? mutualRaw : int.tryParse(mutualRaw.toString()) ?? 0;
    final avatarUrl = AppData.fullImageUrl(
        person['profilePicUrl'] as String? ?? person['profile_pic'] as String?);
    final status = person['connection_status']?.toString() ??
        (person['friendRequestSent'] == true ? 'pending_sent' : 'none');
    final requestId = person['friend_request_id']?.toString() ??
        person['friendRequestId']?.toString() ??
        '';
    final userId = person['id']?.toString() ?? '';
    final isVerified = person['is_verified'] == true || person['is_verified'] == 1;

    return NetworkUserData._(
      name: name,
      specialty: specialty,
      location: location,
      mutualCount: mutualCount,
      avatarUrl: avatarUrl,
      status: status,
      requestId: requestId,
      userId: userId,
      isVerified: isVerified,
    );
  }
}

/// Grid card for user — used in People You May Know grid
class NetworkUserGridCard extends StatelessWidget {
  final Map<String, dynamic> person;
  final NetworkBloc bloc;
  final VoidCallback onTap;

  const NetworkUserGridCard({
    super.key,
    required this.person,
    required this.bloc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = NetworkUserData.fromMap(person);

    return NetworkPersonSuggestionCard(
      person: person,
      onTap: onTap,
      fillWidth: true,
      includeTrailingMargin: false,
      action: NetworkConnectionAction(
        person: person,
        bloc: bloc,
        status: data.status,
        requestId: data.requestId,
        isCompact: true,
      ),
    );
  }
}

/// List tile for user — used in People You May Know list
class NetworkUserListTile extends StatelessWidget {
  final Map<String, dynamic> person;
  final NetworkBloc bloc;
  final VoidCallback onTap;

  const NetworkUserListTile({
    super.key,
    required this.person,
    required this.bloc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final data = NetworkUserData.fromMap(person);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            NetworkUserAvatar(
              imageUrl: data.avatarUrl,
              name: data.name,
              size: 52,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          data.name.isNotEmpty ? data.name : translation(context).lbl_unknown,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall,
                        ),
                      ),
                      if (data.isVerified) ...[
                        const SizedBox(width: 4),
                        theme.buildVerifiedBadge(size: 16),
                      ],
                    ],
                  ),
                  if (data.specialty.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.specialty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySecondary.copyWith(fontSize: 12.5),
                    ),
                  ],
                  if (data.location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: theme.textTertiary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            data.location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.caption.copyWith(
                              fontSize: 11.5,
                              color: theme.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (data.mutualCount > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 13, color: theme.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${data.mutualCount} ${translation(context).lbl_mutual_connections}',
                          style: theme.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            NetworkConnectionAction(
              person: person,
              bloc: bloc,
              status: data.status,
              requestId: data.requestId,
              isCompact: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection action button — shared between grid and list
class NetworkConnectionAction extends StatelessWidget {
  final Map<String, dynamic> person;
  final NetworkBloc bloc;
  final String status;
  final String requestId;
  final bool isCompact;

  const NetworkConnectionAction({
    super.key,
    required this.person,
    required this.bloc,
    required this.status,
    required this.requestId,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final userId = person['id']?.toString() ?? '';

    switch (status) {
      case 'connected':
        return NetworkActionButton(
          label: translation(context).lbl_message,
          fullWidth: false,
          onTap: () {
            final name = _resolvePersonName(person);
            final profilePic = person['profilePicUrl'] as String? ??
                person['profile_pic'] as String? ??
                '';
            ChatRoomScreen(
              username: name,
              profilePic: profilePic,
              id: userId,
              conversationId: 0,
            ).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
          },
        );

      case 'pending_received':
        if (isCompact) {
          return Row(
            children: [
              Expanded(
                child: NetworkActionButton(
                  label: translation(context).lbl_accept,
                  fullWidth: false,
                  onTap: () {
                    if (requestId.isNotEmpty) {
                      bloc.add(AcceptFriendRequestEvent(requestId: requestId));
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: NetworkActionButton(
                  label: translation(context).lbl_ignore,
                  muted: true,
                  fullWidth: false,
                  onTap: () {
                    if (requestId.isNotEmpty) {
                      bloc.add(RejectFriendRequestEvent(requestId: requestId));
                    }
                  },
                ),
              ),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NetworkActionButton(
              label: translation(context).lbl_accept,
              fullWidth: false,
              onTap: () {
                if (requestId.isNotEmpty) {
                  bloc.add(AcceptFriendRequestEvent(requestId: requestId));
                }
              },
            ),
            const SizedBox(width: 6),
            NetworkActionButton(
              label: translation(context).lbl_ignore,
              muted: true,
              fullWidth: false,
              onTap: () {
                if (requestId.isNotEmpty) {
                  bloc.add(RejectFriendRequestEvent(requestId: requestId));
                }
              },
            ),
          ],
        );

      case 'pending_sent':
        return NetworkActionButton(
          label: translation(context).lbl_pending,
          muted: true,
          fullWidth: false,
          onTap: () {
            if (requestId.isNotEmpty) {
              bloc.add(CancelFriendRequestEvent(
                  requestId: requestId, userId: userId));
            }
          },
        );

      default:
        return NetworkActionButton(
          label: translation(context).lbl_connect,
          onTap: () {
            if (userId.isNotEmpty) {
              bloc.add(SendFriendRequestEvent(userId: userId));
            }
          },
        );
    }
  }
}
