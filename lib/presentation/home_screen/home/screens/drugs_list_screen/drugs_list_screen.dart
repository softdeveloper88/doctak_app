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
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/shimmer_widget/drugs_shimmer_loader.dart';

class DrugsListScreen extends StatefulWidget {
  const DrugsListScreen({super.key});

  @override
  State<DrugsListScreen> createState() => _DrugsListScreenState();
}

class _DrugsListScreenState extends State<DrugsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final DrugsBloc _drugsBloc = DrugsBloc();

  // Search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  // Filters
  DrugActiveFilters _activeFilters = const DrugActiveFilters();
  DrugV6Filters _availableFilters = const DrugV6Filters();

  // Drug type toggle: 0=Brand, 1=Generic
  int _selectedTypeIndex = 0;

  String _currency = '';
  String _countryId = '1';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _drugsBloc.close();
    super.dispose();
  }


  void _reload({String? countryId}) {
    final cid = countryId ?? _countryId;
    final kw = _searchController.text.trim();
    final filters =
        kw.isNotEmpty ? _activeFilters.copyWith(keyword: kw) : _activeFilters;
    _drugsBloc.add(LoadDrugsEvent(countryId: cid, filters: filters));
    _drugsBloc.add(LoadFeaturedDrugsEvent(countryId: cid));
    _drugsBloc.add(LoadDrugFiltersEvent(countryId: cid));
  }

  void _onCountrySelected(Countries country, SplashBloc splashBloc) {
    final cid = country.id.toString();
    setState(() => _countryId = cid);
    splashBloc.add(LoadDropdownData(
        cid,
        _selectedTypeIndex == 0 ? 'Brand' : 'Generic',
        _searchController.text.trim(),
        ''));
    _reload(countryId: cid);
  }

  void _onFiltersApplied(DrugActiveFilters f) {
    setState(() => _activeFilters = f);
    _drugsBloc.add(LoadDrugsEvent(countryId: _countryId, filters: f));
  }

  void _onSearchChanged(String val) {
    if (val.length >= 2) {
      _drugsBloc.add(LoadSearchSuggestionsEvent(
          query: val,
          type: _selectedTypeIndex == 0 ? 'Brand' : 'Generic',
          countryId: _countryId));
      setState(() => _showSuggestions = true);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
    if (val.length >= 3 || val.isEmpty) {
      _drugsBloc.add(LoadDrugsEvent(
          countryId: _countryId,
          filters:
              _activeFilters.copyWith(keyword: val.isEmpty ? null : val)));
    }
  }

  void _onSuggestionTapped(String s) {
    _searchController.text = s;
    setState(() => _showSuggestions = false);
    FocusScope.of(context).unfocus();
    _drugsBloc.add(LoadDrugsEvent(
        countryId: _countryId,
        filters: _activeFilters.copyWith(keyword: s)));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
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
                final countriesState =
                    state is CountriesDataLoaded ? state : null;
                // If SplashBloc just transitioned to CountriesDataLoaded and
                // we hadn't initialised yet (edge case), pick up the country.
                if (countriesState != null && !_initialized) {
                  _initialized = true;
                  _countryId = countriesState.countryFlag.isNotEmpty
                      ? countriesState.countryFlag
                      : '${countriesState.countriesModel.countries?.first.id ?? 1}';
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _reload(countryId: _countryId));
                }
                return _buildAppBar(context, theme, countriesState);
              },
            ),
            _buildTypeToggle(theme),
            if (_isSearchVisible) _buildSearchField(theme),
            Expanded(
              child: Stack(
                children: [
                  _buildContent(theme),
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

  // ── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(
      BuildContext context, OneUITheme theme, CountriesDataLoaded? state) {
    return DoctakAppBar(
      title: translation(context).lbl_drug_list,
      titleIcon: Icons.medication_rounded,
      actions: [
        DoctakSearchToggleButton(
          isSearching: _isSearchVisible,
          onTap: () {
            setState(() {
              _isSearchVisible = !_isSearchVisible;
              if (!_isSearchVisible) {
                _searchController.clear();
                _suggestions = [];
                _showSuggestions = false;
                _drugsBloc.add(LoadDrugsEvent(
                    countryId: _countryId,
                    filters: _activeFilters.copyWith(keyword: null)));
              }
            });
          },
        ),
        Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: Icon(Icons.tune_rounded,
                    color: theme.primary, size: 20),
                padding: EdgeInsets.zero,
                onPressed: () => DrugFilterSheet.show(
                  context,
                  filters: _availableFilters,
                  activeFilters: _activeFilters,
                  onApply: _onFiltersApplied,
                ),
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
                      color: theme.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${_activeFilters.activeFilterCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        if (state != null)
          PopupMenuButton<Countries>(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            offset: const Offset(0, 50),
            elevation: 8,
            color: theme.cardBackground,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(_currentFlag(state),
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            itemBuilder: (_) =>
                state.countriesModel.countries?.map((c) {
                  return PopupMenuItem<Countries>(
                    value: c,
                    height: 48,
                    child: Row(children: [
                      Text(c.flag ?? '',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.countryName ?? '',
                          style: TextStyle(
                              color: theme.textPrimary,
                              fontFamily: 'Poppins',
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  );
                }).toList() ??
                [],
            onSelected: (c) =>
                _onCountrySelected(c, BlocProvider.of<SplashBloc>(context)),
          )
        else
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(12)),
            child: const Center(
              child: Text('🌐', style: TextStyle(fontSize: 18)),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _currentFlag(CountriesDataLoaded state) {
    if (state.countriesModel.countries == null) return '🌐';
    try {
      return state.countriesModel.countries!
              .firstWhere((e) => e.id.toString() == _countryId,
                  orElse: () => state.countriesModel.countries!.first)
              .flag ??
          '🌐';
    } catch (_) {
      return '🌐';
    }
  }

  // ── Type toggle ────────────────────────────────────────────────────────────

  // ── Brand / Generic toggle — matches subscription billing-period style ──────

  Widget _buildTypeToggle(OneUITheme theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.border),
      ),
      child: Row(children: [
        _typeTab(theme, translation(context).lbl_brand, Icons.medical_services_outlined, 0),
        _typeTab(theme, translation(context).lbl_generic, Icons.local_pharmacy_outlined, 1),
      ]),
    );
  }

  Widget _typeTab(OneUITheme theme, String label, IconData icon, int index) {
    final selected = _selectedTypeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTypeIndex == index) return;
          setState(() => _selectedTypeIndex = index);
          _reload();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.cardBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: selected && !theme.isDark
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? theme.primary : theme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? theme.textPrimary : theme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search field ───────────────────────────────────────────────────────────

  Widget _buildSearchField(OneUITheme theme) {
    return DoctakCollapsibleSearchField(
      isVisible: _isSearchVisible,
      hintText: translation(context).lbl_search,
      controller: _searchController,
      height: 72,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      onChanged: _onSearchChanged,
      onClear: () {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        _drugsBloc.add(LoadDrugsEvent(
            countryId: _countryId,
            filters: _activeFilters.copyWith(keyword: null)));
      },
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
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: theme.divider),
        itemBuilder: (_, i) => ListTile(
          dense: true,
          leading: Icon(Icons.search_rounded,
              size: 18, color: theme.textTertiary),
          title: Text(_suggestions[i],
              style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary)),
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
        final isLoadingMore =
            state is DrugsLoaded && state.isLoadingMore;

        return RefreshIndicator(
          color: theme.primary,
          onRefresh: () async => _reload(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (featured.isNotEmpty && !_isSearchVisible)
                SliverToBoxAdapter(
                    child: _buildFeaturedSection(theme, featured)),
              if (_activeFilters.hasActiveFilters)
                SliverToBoxAdapter(
                    child: _buildActiveFilterChips(theme)),
              SliverToBoxAdapter(child: _buildStatsBar(theme)),
              if (drugs.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(theme))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      if (i >=
                              drugs.length -
                                  _drugsBloc.nextPageTrigger &&
                          _drugsBloc.currentMeta.hasMore) {
                        _drugsBloc.add(const LoadMoreDrugsEvent());
                      }
                      return MemoryOptimizedDrugItem(
                          drug: drugs[i], currency: _currency);
                    },
                    childCount: drugs.length,
                  ),
                ),
              if (isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: theme.primary, strokeWidth: 2)),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 32),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Featured carousel ──────────────────────────────────────────────────────

  Widget _buildFeaturedSection(
      OneUITheme theme, List<DrugV6Item> featured) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Icon(Icons.star_rounded, size: 16, color: theme.warning),
            const SizedBox(width: 6),
            Text('Featured Drugs',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                    fontFamily: 'Poppins')),
            const Spacer(),
            Text('${featured.length} drugs',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.textTertiary,
                    fontFamily: 'Poppins')),
          ]),
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
                  fontFamily: 'Poppins'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(children: [
              Icon(Icons.auto_awesome_rounded, size: 12, color: theme.primary),
              const SizedBox(width: 3),
              Text('Ask AI',
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.primary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Active filter chips ────────────────────────────────────────────────────

  Widget _buildActiveFilterChips(OneUITheme theme) {
    final chips = <(String, VoidCallback)>[];
    if (_activeFilters.category != null) {
      chips.add((_activeFilters.category!,
          () => _onFiltersApplied(_activeFilters.copyWith(clearCategory: true))));
    }
    if (_activeFilters.manufacturer != null) {
      chips.add((_activeFilters.manufacturer!,
          () => _onFiltersApplied(_activeFilters.copyWith(clearManufacturer: true))));
    }
    if (_activeFilters.strength != null) {
      chips.add((_activeFilters.strength!,
          () => _onFiltersApplied(_activeFilters.copyWith(clearStrength: true))));
    }
    if (_activeFilters.formulation != null) {
      chips.add((_activeFilters.formulation!,
          () => _onFiltersApplied(_activeFilters.copyWith(clearFormulation: true))));
    }
    if (_activeFilters.priceRange != null) {
      chips.add((_activeFilters.priceRange!,
          () => _onFiltersApplied(_activeFilters.copyWith(clearPriceRange: true))));
    }
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: chips.length,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(right: 8),
          child: InputChip(
            label: Text(chips[i].$1,
                style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: theme.primary)),
            deleteIcon:
                Icon(Icons.close, size: 14, color: theme.primary),
            onDeleted: chips[i].$2,
            onPressed: chips[i].$2,
            backgroundColor: theme.primary.withValues(alpha: 0.1),
            side: BorderSide(
                color: theme.primary.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ),
      ),
    );
  }

  // ── Stats bar ──────────────────────────────────────────────────────────────

  Widget _buildStatsBar(OneUITheme theme) {
    final total = _drugsBloc.currentMeta.total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(children: [
        if (total > 0)
          Text('$total results',
              style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  color: theme.textTertiary)),
        const Spacer(),
        if (_currency.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(8)),
            child: Text(_currency,
                style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary)),
          ),
      ]),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined,
              size: 72, color: theme.textTertiary),
          const SizedBox(height: 16),
          Text('No drugs found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Text('Try a different search or adjust your filters',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.textTertiary,
                  fontFamily: 'Poppins'),
              textAlign: TextAlign.center),
          if (_activeFilters.hasActiveFilters) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primary),
              onPressed: () =>
                  _onFiltersApplied(const DrugActiveFilters()),
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
            Icon(Icons.wifi_off_rounded,
                size: 64, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text('Failed to load drugs',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                    fontSize: 13,
                    color: theme.textTertiary,
                    fontFamily: 'Poppins'),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              onPressed: _reload,
            ),
          ],
        ),
      ),
    );
  }
}
