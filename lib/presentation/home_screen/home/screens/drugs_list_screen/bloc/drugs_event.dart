import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';
import 'package:equatable/equatable.dart';

abstract class DrugsEvent extends Equatable {
  const DrugsEvent();
}

/// Load (or reload) the drugs list from page 1.
class LoadDrugsEvent extends DrugsEvent {
  final String? countryId;
  final DrugActiveFilters filters;
  const LoadDrugsEvent({this.countryId, this.filters = const DrugActiveFilters()});
  @override
  List<Object?> get props => [countryId, filters];
}

/// Load next page (infinite scroll).
class LoadMoreDrugsEvent extends DrugsEvent {
  const LoadMoreDrugsEvent();
  @override
  List<Object?> get props => [];
}

/// Load filter options for a country.
class LoadDrugFiltersEvent extends DrugsEvent {
  final String? countryId;
  const LoadDrugFiltersEvent({this.countryId});
  @override
  List<Object?> get props => [countryId];
}

/// Load featured drugs.
class LoadFeaturedDrugsEvent extends DrugsEvent {
  final String? countryId;
  const LoadFeaturedDrugsEvent({this.countryId});
  @override
  List<Object?> get props => [countryId];
}

/// Fetch autocomplete search suggestions.
class LoadSearchSuggestionsEvent extends DrugsEvent {
  final String query;
  final String type;
  final String? countryId;
  const LoadSearchSuggestionsEvent({required this.query, this.type = 'Brand', this.countryId});
  @override
  List<Object?> get props => [query, type, countryId];
}

/// Clear suggestions list.
class ClearSuggestionsEvent extends DrugsEvent {
  const ClearSuggestionsEvent();
  @override
  List<Object?> get props => [];
}

/// Load AI usage stats.
class LoadAIUsageEvent extends DrugsEvent {
  const LoadAIUsageEvent();
  @override
  List<Object?> get props => [];
}

// ─── Legacy events kept for backward compatibility ────────────────────────────

class LoadPageEvent extends DrugsEvent {
  final int? page;
  final String? countryId;
  final String? type;
  final String? searchTerm;
  LoadPageEvent({this.page, this.countryId, this.type, this.searchTerm});
  @override
  List<Object?> get props => [page, countryId, type, searchTerm];
}

class CheckIfNeedMoreDataEvent extends DrugsEvent {
  final int index;
  CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
