import 'package:doctak_app/data/apiClient/drugs_v6_api_service.dart';
import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'drugs_event.dart';
import 'drugs_state.dart';

class DrugsBloc extends Bloc<DrugsEvent, DrugsState> {
  final DrugsV6ApiService _api = DrugsV6ApiService.instance;

  // ── State tracked in the BLoC (not only in states) ────────────────────────
  List<DrugV6Item> drugsData = [];
  List<DrugV6Item> featuredData = [];
  DrugV6Filters? availableFilters;
  DrugAIUsage? aiUsage;
  DrugV6Meta _meta = DrugV6Meta.empty();
  DrugActiveFilters _activeFilters = const DrugActiveFilters();
  String _countryId = '1';
  String _currency = '';
  bool _isLoadingMore = false;

  // Expose for virtualized list backward compat
  int get pageNumber => (_meta.currentPage) + (_isLoadingMore ? 0 : 1);
  int get numberOfPage => _meta.lastPage;
  int get nextPageTrigger => 3; // start prefetch 3 items before end
  DrugV6Meta get currentMeta => _meta;

  DrugsBloc() : super(DrugsInitial()) {
    on<LoadDrugsEvent>(_onLoadDrugs);
    on<LoadMoreDrugsEvent>(_onLoadMore);
    on<LoadDrugFiltersEvent>(_onLoadFilters);
    on<LoadFeaturedDrugsEvent>(_onLoadFeatured);
    on<LoadSearchSuggestionsEvent>(_onLoadSuggestions);
    on<ClearSuggestionsEvent>((_, emit) => emit(DrugsSuggestionsLoaded([])));
    on<LoadAIUsageEvent>(_onLoadAIUsage);

    // ── Legacy event handlers (keep existing screen working) ──────────────
    on<LoadPageEvent>(_onLegacyLoadPage);
    on<CheckIfNeedMoreDataEvent>(_onLegacyCheckMore);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD DRUGS (page 1)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLoadDrugs(LoadDrugsEvent event, Emitter<DrugsState> emit) async {
    emit(DrugsLoading());
    _activeFilters = event.filters;
    if (event.countryId != null) _countryId = event.countryId!;
    drugsData.clear();
    try {
      final resp = await _api.getDrugs(
        countryId: _countryId,
        page: 1,
        filters: _activeFilters,
      );
      drugsData = List<DrugV6Item>.from(resp.data);
      _meta = resp.meta;
      _currency = resp.currency;
      emit(DrugsLoaded(drugs: drugsData, meta: _meta, currency: _currency, appliedFilters: _activeFilters));
    } catch (e) {
      emit(DrugsError('Failed to load drugs: $e'));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD MORE (pagination)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLoadMore(LoadMoreDrugsEvent event, Emitter<DrugsState> emit) async {
    if (_isLoadingMore || !_meta.hasMore) return;
    _isLoadingMore = true;
    final nextPage = _meta.currentPage + 1;
    emit(DrugsLoaded(drugs: drugsData, meta: _meta, currency: _currency, appliedFilters: _activeFilters, isLoadingMore: true));
    try {
      final resp = await _api.getDrugs(
        countryId: _countryId,
        page: nextPage,
        filters: _activeFilters,
      );
      drugsData = [...drugsData, ...resp.data];
      _meta = resp.meta;
    } catch (_) {
      // silently ignore pagination errors, keep existing data
    } finally {
      _isLoadingMore = false;
      emit(DrugsLoaded(drugs: drugsData, meta: _meta, currency: _currency, appliedFilters: _activeFilters));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD FILTERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLoadFilters(LoadDrugFiltersEvent event, Emitter<DrugsState> emit) async {
    try {
      availableFilters = await _api.getFilters(countryId: event.countryId ?? _countryId);
      emit(DrugsFiltersLoaded(availableFilters!));
    } catch (e) {
      availableFilters = null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD FEATURED
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLoadFeatured(LoadFeaturedDrugsEvent event, Emitter<DrugsState> emit) async {
    try {
      final resp = await _api.getFeatured(countryId: event.countryId ?? _countryId);
      featuredData = resp.data;
      emit(DrugsFeaturedLoaded(featuredData));
    } catch (_) {
      featuredData = [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEARCH SUGGESTIONS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLoadSuggestions(LoadSearchSuggestionsEvent event, Emitter<DrugsState> emit) async {
    if (event.query.length < 2) {
      emit(DrugsSuggestionsLoaded([]));
      return;
    }
    try {
      final resp = await _api.getSearchSuggestions(
        q: event.query,
        type: event.type,
        countryId: event.countryId ?? _countryId,
      );
      emit(DrugsSuggestionsLoaded(resp.data));
    } catch (_) {
      emit(DrugsSuggestionsLoaded([]));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI USAGE
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLoadAIUsage(LoadAIUsageEvent event, Emitter<DrugsState> emit) async {
    try {
      aiUsage = await _api.getAIUsage();
      emit(DrugsAIUsageLoaded(aiUsage!));
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LEGACY HANDLERS (bridge to new API so existing screen compiles)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onLegacyLoadPage(LoadPageEvent event, Emitter<DrugsState> emit) async {
    final keyword = event.searchTerm ?? '';
    final country = event.countryId ?? '1';
    final filters = DrugActiveFilters(keyword: keyword.isEmpty ? null : keyword);

    if ((event.page ?? 1) == 1) {
      add(LoadDrugsEvent(countryId: country, filters: filters));
      // Also kick off featured/filters in parallel
      add(LoadFeaturedDrugsEvent(countryId: country));
      add(LoadDrugFiltersEvent(countryId: country));
    } else {
      add(const LoadMoreDrugsEvent());
    }
  }

  Future<void> _onLegacyCheckMore(CheckIfNeedMoreDataEvent event, Emitter<DrugsState> emit) async {
    if (drugsData.isNotEmpty && event.index >= drugsData.length - nextPageTrigger) {
      add(const LoadMoreDrugsEvent());
    }
  }
}
