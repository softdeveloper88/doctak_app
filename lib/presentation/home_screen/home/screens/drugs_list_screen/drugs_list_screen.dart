import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_state.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drug_detail_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/drug_filter_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/memory_optimized_drug_item.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/shimmer_widget/drugs_shimmer_loader.dart';

class DrugsListScreen extends StatefulWidget {
  const DrugsListScreen({super.key});

  @override
  State<DrugsListScreen> createState() => _DrugsListScreenState();
}

class _DrugsListScreenState extends State<DrugsListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final DrugsBloc _drugsBloc = DrugsBloc();

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchVisible = false;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  // Filters
  DrugActiveFilters _activeFilters = const DrugActiveFilters();
  DrugV6Filters _availableFilters = const DrugV6Filters();

  // Drug type toggle: 0=Brand, 1=Generic
  int _selectedTypeIndex = 0;
  late final TabController _tabController;

  String _currency = '';
  String _countryId = '1';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabSwiped);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  /// Initialise country + load drugs/filters regardless of SplashBloc state.
  void _initializeData() {
    if (_initialized) return;
    _initialized = true;

    final splashState = context.read<SplashBloc>().state;
    if (splashState is CountriesDataLoaded) {
      _countryId = splashState.countryFlag.isNotEmpty
          ? splashState.countryFlag
          : '${splashState.countriesModel.countries?.first.id ?? 1}';
    } else {
      // Ensure SplashBloc loads countries so the country picker appears
      context.read<SplashBloc>().add(LoadDropdownData('', '', '', ''));
    }
    _reload(countryId: _countryId);
  }

  void _onTabSwiped() {
    if (!_tabController.indexIsChanging &&
        _tabController.index != _selectedTypeIndex) {
      setState(() => _selectedTypeIndex = _tabController.index);
      _reload();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabSwiped);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _drugsBloc.close();
    super.dispose();
  }

  void _reload({String? countryId}) {
    final cid = countryId ?? _countryId;
    final kw = _searchController.text.trim();
    final filters = kw.isNotEmpty
        ? _activeFilters.copyWith(keyword: kw)
        : _activeFilters;
    _drugsBloc.add(LoadDrugsEvent(countryId: cid, filters: filters));
    _drugsBloc.add(LoadFeaturedDrugsEvent(countryId: cid));
    _drugsBloc.add(LoadDrugFiltersEvent(countryId: cid));
  }

  void _onCountrySelected(Countries country, SplashBloc splashBloc) {
    final cid = country.id.toString();
    setState(() => _countryId = cid);
    splashBloc.add(
      LoadDropdownData(
        cid,
        _selectedTypeIndex == 0 ? 'Brand' : 'Generic',
        _searchController.text.trim(),
        '',
      ),
    );
    _reload(countryId: cid);
  }

  void _onFiltersApplied(DrugActiveFilters f) {
    setState(() => _activeFilters = f);
    _drugsBloc.add(LoadDrugsEvent(countryId: _countryId, filters: f));
  }

  void _onSearchChanged(String val) {
    if (val.length >= 2) {
      _drugsBloc.add(
        LoadSearchSuggestionsEvent(
          query: val,
          type: _selectedTypeIndex == 0 ? 'Brand' : 'Generic',
          countryId: _countryId,
        ),
      );
      setState(() => _showSuggestions = true);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
    if (val.length >= 3 || val.isEmpty) {
      _drugsBloc.add(
        LoadDrugsEvent(
          countryId: _countryId,
          filters: _activeFilters.copyWith(keyword: val.isEmpty ? null : val),
        ),
      );
    }
  }

  void _onSuggestionTapped(String s) {
    _searchController.text = s;
    setState(() => _showSuggestions = false);
    FocusScope.of(context).unfocus();
    _drugsBloc.add(
      LoadDrugsEvent(
        countryId: _countryId,
        filters: _activeFilters.copyWith(keyword: s),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.isDark
          ? theme.scaffoldBackground
          : const Color(0xFFF6F6F8),
      body: BlocListener<DrugsBloc, DrugsState>(
        bloc: _drugsBloc,
        listener: (context, state) {
          if (state is DrugsLoaded) {
            setState(() => _currency = state.currency);
          } else if (state is DrugsFiltersLoaded) {
            setState(() => _availableFilters = state.filters);
          } else if (state is DrugsSuggestionsLoaded) {
            setState(() {
              _suggestions = state.suggestions;
              _showSuggestions = state.suggestions.isNotEmpty;
            });
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<SplashBloc, SplashState>(
              builder: (context, state) {
                final countriesState = state is CountriesDataLoaded
                    ? state
                    : null;
                if (countriesState != null && !_initialized) {
                  _initialized = true;
                  _countryId = countriesState.countryFlag.isNotEmpty
                      ? countriesState.countryFlag
                      : '${countriesState.countriesModel.countries?.first.id ?? 1}';
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _reload(countryId: _countryId),
                  );
                }
                return _buildHeader(context, theme, countriesState);
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: [_buildContent(theme), _buildContent(theme)],
                  ),
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 16,
                      right: 16,
                      child: _buildSuggestionsOverlay(theme),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sticky Header (AppBar + Search + Chips + Tabs) ─────────────────────────

  Widget _buildHeader(
    BuildContext context,
    OneUITheme theme,
    CountriesDataLoaded? state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: theme.isDark ? theme.border : Colors.grey.shade200,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row
            _buildTitleRow(context, theme, state),
            // Search bar (toggle-based)
            if (_isSearchVisible) _buildSearchBar(theme),
            // Filter chips (only if there are chips)
            if (_availableFilters.categories.isNotEmpty ||
                _activeFilters.manufacturer != null ||
                _activeFilters.formulation != null)
              _buildFilterChips(theme),
            // Brand / Generic tabs
            _buildTypeToggle(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(
    BuildContext context,
    OneUITheme theme,
    CountriesDataLoaded? state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          // Back button (Cupertino style)
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.textSecondary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 22,
          ),
          // Title (left-aligned)
          Text(
            translation(context).lbl_drug_list,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          // Action buttons
          _buildHeaderActions(context, theme, state),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(
    BuildContext context,
    OneUITheme theme,
    CountriesDataLoaded? state,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Search toggle button
        _headerActionButton(
          theme,
          icon: _isSearchVisible ? Icons.close_rounded : Icons.search_rounded,
          onTap: () {
            setState(() {
              _isSearchVisible = !_isSearchVisible;
              if (!_isSearchVisible) {
                _searchController.clear();
                _suggestions = [];
                _showSuggestions = false;
                _drugsBloc.add(
                  LoadDrugsEvent(
                    countryId: _countryId,
                    filters: _activeFilters.copyWith(keyword: null),
                  ),
                );
              } else {
                // Auto-focus when opening search
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _searchFocusNode.requestFocus();
                });
              }
            });
          },
        ),
        const SizedBox(width: 2),
        // Filter button
        Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            _headerActionButton(
              theme,
              icon: Icons.tune_rounded,
              onTap: () => DrugFilterSheet.show(
                context,
                filters: _availableFilters,
                activeFilters: _activeFilters,
                onApply: _onFiltersApplied,
              ),
            ),
            if (_activeFilters.activeFilterCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_activeFilters.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        // Country picker
        if (state != null)
          PopupMenuButton<Countries>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            offset: const Offset(0, 50),
            elevation: 8,
            color: theme.cardBackground,
            child: _headerActionButton(
              theme,
              child: Text(
                _currentFlag(state),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            itemBuilder: (_) =>
                state.countriesModel.countries?.map((c) {
                  return PopupMenuItem<Countries>(
                    value: c,
                    height: 48,
                    child: Row(
                      children: [
                        Text(
                          c.flag ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.countryName ?? '',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList() ??
                [],
            onSelected: (c) =>
                _onCountrySelected(c, BlocProvider.of<SplashBloc>(context)),
          )
        else
          _headerActionButton(
            theme,
            child: const Text('🌐', style: TextStyle(fontSize: 18)),
          ),
      ],
    );
  }

  Widget _headerActionButton(
    OneUITheme theme, {
    IconData? icon,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child ?? Icon(icon, color: theme.textSecondary, size: 22),
      ),
    );
  }

  String _currentFlag(CountriesDataLoaded state) {
    if (state.countriesModel.countries == null) return '🌐';
    try {
      return state.countriesModel.countries!
              .firstWhere(
                (e) => e.id.toString() == _countryId,
                orElse: () => state.countriesModel.countries!.first,
              )
              .flag ??
          '🌐';
    } catch (_) {
      return '🌐';
    }
  }

  // ── Search bar (always visible) ────────────────────────────────────────────

  Widget _buildSearchBar(OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.isDark ? theme.surfaceVariant : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search drugs, compositions, molecules...',
            hintStyle: TextStyle(
              color: theme.textTertiary,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: theme.textTertiary,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.textTertiary,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                      });
                      _drugsBloc.add(
                        LoadDrugsEvent(
                          countryId: _countryId,
                          filters: _activeFilters.copyWith(keyword: null),
                        ),
                      );
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 11,
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter chips ───────────────────────────────────────────────────────────

  Widget _buildFilterChips(OneUITheme theme) {
    // Build chip data from available filters
    final chips = <_FilterChipData>[];

    // Category chips from available filters
    for (final cat in _availableFilters.categories.take(5)) {
      if (cat.genericName.isEmpty) continue;
      chips.add(
        _FilterChipData(
          label: cat.genericName,
          isActive: _activeFilters.category == cat.genericName,
          onTap: () {
            if (_activeFilters.category == cat.genericName) {
              _onFiltersApplied(_activeFilters.copyWith(clearCategory: true));
            } else {
              _onFiltersApplied(
                _activeFilters.copyWith(category: cat.genericName),
              );
            }
          },
        ),
      );
    }

    // Active filter chips for non-category filters
    if (_activeFilters.manufacturer != null) {
      chips.add(
        _FilterChipData(
          label: _activeFilters.manufacturer!,
          isActive: true,
          onTap: () => _onFiltersApplied(
            _activeFilters.copyWith(clearManufacturer: true),
          ),
          showClose: true,
        ),
      );
    }
    if (_activeFilters.formulation != null) {
      chips.add(
        _FilterChipData(
          label: _activeFilters.formulation!,
          isActive: true,
          onTap: () => _onFiltersApplied(
            _activeFilters.copyWith(clearFormulation: true),
          ),
          showClose: true,
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        itemBuilder: (_, i) {
          final chip = chips[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: chip.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: chip.isActive
                      ? theme.primary
                      : (theme.isDark
                            ? theme.surfaceVariant
                            : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chip.label,
                      style: TextStyle(
                        color: chip.isActive
                            ? Colors.white
                            : theme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (chip.showClose) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.close,
                        size: 12,
                        color: chip.isActive
                            ? Colors.white
                            : theme.textSecondary,
                      ),
                    ] else if (chip.isActive && chips.indexOf(chip) == 0) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, size: 14, color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Type toggle (Brand / Generic tabs — underline style) ───────────────────

  Widget _buildTypeToggle(OneUITheme theme) {
    return Container(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          _typeTab(theme, translation(context).lbl_brand, 0),
          _typeTab(theme, translation(context).lbl_generic, 1),
        ],
      ),
    );
  }

  Widget _typeTab(OneUITheme theme, String label, int index) {
    final selected = _selectedTypeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTypeIndex == index) return;
          setState(() => _selectedTypeIndex = index);
          _tabController.animateTo(index);
          _reload();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: selected ? theme.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? theme.primary : theme.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ── Suggestions overlay ────────────────────────────────────────────────────

  Widget _buildSuggestionsOverlay(OneUITheme theme) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: theme.cardBackground,
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _suggestions.length > 8 ? 8 : _suggestions.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: theme.divider),
        itemBuilder: (_, i) => ListTile(
          dense: true,
          leading: Icon(
            Icons.search_rounded,
            size: 18,
            color: theme.textTertiary,
          ),
          title: Text(
            _suggestions[i],
            style: TextStyle(
              fontSize: 14,
              color: theme.textPrimary,
            ),
          ),
          onTap: () => _onSuggestionTapped(_suggestions[i]),
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────

  Widget _buildContent(OneUITheme theme) {
    return BlocBuilder<DrugsBloc, DrugsState>(
      bloc: _drugsBloc,
      builder: (context, state) {
        if (state is DrugsLoading) return const DrugsShimmerLoader();
        if (state is DrugsError) return _buildErrorState(theme, state.message);

        final drugs = _drugsBloc.drugsData;
        final featured = _drugsBloc.featuredData;
        final isLoadingMore = state is DrugsLoaded && state.isLoadingMore;

        return RefreshIndicator(
          color: theme.primary,
          onRefresh: () async => _reload(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (featured.isNotEmpty && _searchController.text.isEmpty)
                SliverToBoxAdapter(
                  child: _buildFeaturedSection(theme, featured),
                ),
              SliverToBoxAdapter(child: _buildStatsBar(theme)),
              if (drugs.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(theme))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    if (i >= drugs.length - _drugsBloc.nextPageTrigger &&
                        _drugsBloc.currentMeta.hasMore) {
                      _drugsBloc.add(const LoadMoreDrugsEvent());
                    }
                    return MemoryOptimizedDrugItem(
                      drug: drugs[i],
                      currency: _currency,
                    );
                  }, childCount: drugs.length),
                ),
              if (isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 32,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Featured carousel ──────────────────────────────────────────────────────

  Widget _buildFeaturedSection(OneUITheme theme, List<DrugV6Item> featured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Icon(Icons.star_rounded, size: 16, color: theme.warning),
              const SizedBox(width: 6),
              Text(
                'Featured Drugs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${featured.length} drugs',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTertiary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featured.length,
            itemBuilder: (_, i) => _featuredCard(theme, featured[i]),
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: theme.divider),
      ],
    );
  }

  Widget _featuredCard(OneUITheme theme, DrugV6Item drug) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DrugDetailScreen(drug: drug, currency: _currency),
        ),
      ),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primary.withValues(alpha: 0.12),
              theme.secondary.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.medication_rounded, size: 20, color: theme.primary),
            const SizedBox(height: 6),
            Text(
              drug.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: theme.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  'Ask AI',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats bar ──────────────────────────────────────────────────────────────

  Widget _buildStatsBar(OneUITheme theme) {
    final total = _drugsBloc.currentMeta.total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          if (total > 0)
            Text(
              '$total drugs found',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
            ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // Could open sort selection in the future
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 14, color: theme.primary),
                const SizedBox(width: 4),
                Text(
                  'Relevance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 72, color: theme.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No drugs found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search or adjust your filters',
            style: TextStyle(
              fontSize: 13,
              color: theme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_activeFilters.hasActiveFilters) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(foregroundColor: theme.primary),
              onPressed: () => _onFiltersApplied(const DrugActiveFilters()),
            ),
          ],
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState(OneUITheme theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Failed to load drugs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: _reload,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper class for filter chips ──────────────────────────────────────────

class _FilterChipData {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool showClose;

  const _FilterChipData({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.showClose = false,
  });
}
