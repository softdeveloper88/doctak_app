import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';

abstract class DrugsState {}

// ──────────────────── Initial ───────────────────────────────────────────────

class DrugsInitial extends DrugsState {}

// ──────────────────── Loading ───────────────────────────────────────────────

/// First-page load spinner.
class DrugsLoading extends DrugsState {}

/// Loading more pages at end of list.
class DrugsLoadingMore extends DrugsState {
  final List<DrugV6Item> currentData;
  DrugsLoadingMore(this.currentData);
}

// ──────────────────── Loaded ────────────────────────────────────────────────

/// Main state: list is ready.
class DrugsLoaded extends DrugsState {
  final List<DrugV6Item> drugs;
  final DrugV6Meta meta;
  final String currency;
  final DrugActiveFilters appliedFilters;
  final bool isLoadingMore;

  DrugsLoaded({
    required this.drugs,
    required this.meta,
    this.currency = '',
    this.appliedFilters = const DrugActiveFilters(),
    this.isLoadingMore = false,
  });

  DrugsLoaded copyWith({
    List<DrugV6Item>? drugs,
    DrugV6Meta? meta,
    String? currency,
    DrugActiveFilters? appliedFilters,
    bool? isLoadingMore,
  }) {
    return DrugsLoaded(
      drugs: drugs ?? this.drugs,
      meta: meta ?? this.meta,
      currency: currency ?? this.currency,
      appliedFilters: appliedFilters ?? this.appliedFilters,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ──────────────────── Filters ───────────────────────────────────────────────

class DrugsFiltersLoaded extends DrugsState {
  final DrugV6Filters filters;
  DrugsFiltersLoaded(this.filters);
}

// ──────────────────── Featured ──────────────────────────────────────────────

class DrugsFeaturedLoaded extends DrugsState {
  final List<DrugV6Item> featured;
  DrugsFeaturedLoaded(this.featured);
}

// ──────────────────── Suggestions ───────────────────────────────────────────

class DrugsSuggestionsLoaded extends DrugsState {
  final List<String> suggestions;
  DrugsSuggestionsLoaded(this.suggestions);
}

// ──────────────────── AI ────────────────────────────────────────────────────

class DrugsAIUsageLoaded extends DrugsState {
  final DrugAIUsage usage;
  DrugsAIUsageLoaded(this.usage);
}

// ──────────────────── Error ─────────────────────────────────────────────────

class DrugsError extends DrugsState {
  final String message;
  DrugsError(this.message);
}

// ─── Legacy aliases for backward compat ─────────────────────────────────────

class PaginationInitialState extends DrugsState {}
class PaginationLoadingState extends DrugsState {}
class PaginationLoadedState extends DrugsState {}
class PaginationErrorState extends DrugsState {}
class DataError extends DrugsState {
  final String errorMessage;
  DataError(this.errorMessage);
}
