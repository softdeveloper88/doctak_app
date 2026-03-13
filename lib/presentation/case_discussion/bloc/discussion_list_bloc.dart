// ============================================================================
// Discussion List BLoC - v6 API
// Handles list loading, pagination, filtering (tabs + search + specialty/country/sort),
// and optimistic like/bookmark actions.
// ============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/case_discussion_repository.dart';
import '../models/case_discussion_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────────────────────────

abstract class DiscussionListEvent extends Equatable {
  const DiscussionListEvent();
  @override
  List<Object?> get props => [];
}

class LoadDiscussionList extends DiscussionListEvent {
  final bool refresh;
  final CaseDiscussionFilters? filters;
  const LoadDiscussionList({this.refresh = false, this.filters});
  @override
  List<Object?> get props => [refresh, filters];
}

class LoadMoreDiscussions extends DiscussionListEvent {}

class RefreshDiscussionList extends DiscussionListEvent {}

class UpdateFilters extends DiscussionListEvent {
  final CaseDiscussionFilters filters;
  const UpdateFilters(this.filters);
  @override
  List<Object?> get props => [filters];
}

class LoadFilterData extends DiscussionListEvent {}

class ToggleLikeDiscussion extends DiscussionListEvent {
  final int caseId;
  const ToggleLikeDiscussion(this.caseId);
  @override
  List<Object> get props => [caseId];
}

class ToggleBookmarkDiscussion extends DiscussionListEvent {
  final int caseId;
  const ToggleBookmarkDiscussion(this.caseId);
  @override
  List<Object> get props => [caseId];
}

class DeleteDiscussion extends DiscussionListEvent {
  final int caseId;
  const DeleteDiscussion(this.caseId);
  @override
  List<Object> get props => [caseId];
}

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────

abstract class DiscussionListState extends Equatable {
  const DiscussionListState();
  @override
  List<Object?> get props => [];
}

class DiscussionListInitial extends DiscussionListState {}

class DiscussionListLoading extends DiscussionListState {}

class DiscussionListLoaded extends DiscussionListState {
  final List<CaseDiscussionListItem> discussions;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final List<SpecialtyFilter> specialties;
  final List<CountryFilter> countries;
  final CaseDiscussionFilters currentFilters;

  const DiscussionListLoaded({
    required this.discussions,
    required this.hasReachedMax,
    this.isLoadingMore = false,
    this.specialties = const [],
    this.countries = const [],
    this.currentFilters = const CaseDiscussionFilters(),
  });

  @override
  List<Object> get props => [
        discussions,
        hasReachedMax,
        isLoadingMore,
        specialties,
        countries,
        currentFilters,
      ];

  DiscussionListLoaded copyWith({
    List<CaseDiscussionListItem>? discussions,
    bool? hasReachedMax,
    bool? isLoadingMore,
    List<SpecialtyFilter>? specialties,
    List<CountryFilter>? countries,
    CaseDiscussionFilters? currentFilters,
  }) {
    return DiscussionListLoaded(
      discussions: discussions ?? this.discussions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      specialties: specialties ?? this.specialties,
      countries: countries ?? this.countries,
      currentFilters: currentFilters ?? this.currentFilters,
    );
  }
}

class DiscussionListError extends DiscussionListState {
  final String message;
  const DiscussionListError(this.message);
  @override
  List<Object> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────────────────────────────────────

class DiscussionListBloc
    extends Bloc<DiscussionListEvent, DiscussionListState> {
  final CaseDiscussionRepository repository;

  int _currentPage = 1;
  List<CaseDiscussionListItem> _discussions = [];
  CaseDiscussionFilters _currentFilters = const CaseDiscussionFilters();
  List<SpecialtyFilter> _specialties = [];
  List<CountryFilter> _countries = [];

  DiscussionListBloc({required this.repository})
      : super(DiscussionListInitial()) {
    on<LoadDiscussionList>(_onLoadDiscussionList);
    on<LoadMoreDiscussions>(_onLoadMoreDiscussions);
    on<RefreshDiscussionList>(_onRefreshDiscussionList);
    on<UpdateFilters>(_onUpdateFilters);
    on<LoadFilterData>(_onLoadFilterData);
    on<ToggleLikeDiscussion>(_onToggleLike);
    on<ToggleBookmarkDiscussion>(_onToggleBookmark);
    on<DeleteDiscussion>(_onDeleteDiscussion);
  }

  Future<void> _onLoadDiscussionList(
      LoadDiscussionList event, Emitter<DiscussionListState> emit) async {
    if (event.refresh) {
      _currentPage = 1;
      _discussions.clear();
    }

    if (event.filters != null) {
      _currentFilters = event.filters!;
    }

    if (_discussions.isEmpty) {
      emit(DiscussionListLoading());
    }

    try {
      final result = await repository.getCaseDiscussions(
        page: _currentPage,
        filters: _currentFilters,
      );

      if (event.refresh) {
        _discussions = result.items;
      } else {
        _discussions.addAll(result.items);
      }
      _currentPage++;

      emit(DiscussionListLoaded(
        discussions: List.from(_discussions),
        hasReachedMax: !result.pagination.hasNextPage,
        specialties: _specialties,
        countries: _countries,
        currentFilters: _currentFilters,
      ));
    } catch (e) {
      emit(DiscussionListError(e.toString()));
    }
  }

  Future<void> _onLoadMoreDiscussions(
      LoadMoreDiscussions event, Emitter<DiscussionListState> emit) async {
    final currentState = state;
    if (currentState is DiscussionListLoaded &&
        !currentState.hasReachedMax &&
        !currentState.isLoadingMore) {
      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final result = await repository.getCaseDiscussions(
          page: _currentPage,
          filters: _currentFilters,
        );

        _discussions.addAll(result.items);
        _currentPage++;

        emit(DiscussionListLoaded(
          discussions: List.from(_discussions),
          hasReachedMax: !result.pagination.hasNextPage,
          isLoadingMore: false,
          specialties: _specialties,
          countries: _countries,
          currentFilters: _currentFilters,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onRefreshDiscussionList(
      RefreshDiscussionList event, Emitter<DiscussionListState> emit) async {
    add(LoadDiscussionList(refresh: true, filters: _currentFilters));
  }

  Future<void> _onUpdateFilters(
      UpdateFilters event, Emitter<DiscussionListState> emit) async {
    _currentFilters = event.filters;
    _currentPage = 1;
    _discussions.clear();
    emit(DiscussionListLoading());

    try {
      final result = await repository.getCaseDiscussions(
        page: 1,
        filters: _currentFilters,
      );

      _discussions = result.items;
      _currentPage = 2;

      emit(DiscussionListLoaded(
        discussions: List.from(_discussions),
        hasReachedMax: !result.pagination.hasNextPage,
        specialties: _specialties,
        countries: _countries,
        currentFilters: _currentFilters,
      ));
    } catch (e) {
      emit(DiscussionListError(e.toString()));
    }
  }

  Future<void> _onLoadFilterData(
      LoadFilterData event, Emitter<DiscussionListState> emit) async {
    try {
      final filterData = await repository.getFilterData();
      _specialties = filterData['specialties'] as List<SpecialtyFilter>;
      _countries = filterData['countries'] as List<CountryFilter>;

      final currentState = state;
      if (currentState is DiscussionListLoaded) {
        emit(currentState.copyWith(
          specialties: _specialties,
          countries: _countries,
        ));
      }
    } catch (e) {
      // Filter load failure is non-critical
    }
  }

  Future<void> _onToggleLike(
      ToggleLikeDiscussion event, Emitter<DiscussionListState> emit) async {
    final currentState = state;
    if (currentState is DiscussionListLoaded) {
      // Find the item
      final idx =
          currentState.discussions.indexWhere((d) => d.id == event.caseId);
      if (idx == -1) return;
      final item = currentState.discussions[idx];
      final wasLiked = item.isLiked;

      // Optimistic update
      final updated = item.copyWith(
        isLiked: !wasLiked,
        likes: wasLiked ? item.likes - 1 : item.likes + 1,
      );
      final updatedList = List<CaseDiscussionListItem>.from(currentState.discussions);
      updatedList[idx] = updated;
      emit(currentState.copyWith(discussions: updatedList));

      try {
        await repository.performCaseAction(
          caseId: event.caseId,
          action: wasLiked ? 'unlike' : 'like',
        );
      } catch (_) {
        // Revert on failure
        final revertedList = List<CaseDiscussionListItem>.from(currentState.discussions);
        revertedList[idx] = item;
        emit(currentState.copyWith(discussions: revertedList));
      }
    }
  }

  Future<void> _onToggleBookmark(
      ToggleBookmarkDiscussion event, Emitter<DiscussionListState> emit) async {
    final currentState = state;
    if (currentState is DiscussionListLoaded) {
      final idx =
          currentState.discussions.indexWhere((d) => d.id == event.caseId);
      if (idx == -1) return;
      final item = currentState.discussions[idx];
      final wasBookmarked = item.isBookmarked;

      // Optimistic update
      final updated = item.copyWith(isBookmarked: !wasBookmarked);
      final updatedList = List<CaseDiscussionListItem>.from(currentState.discussions);
      updatedList[idx] = updated;
      emit(currentState.copyWith(discussions: updatedList));

      try {
        await repository.performCaseAction(
          caseId: event.caseId,
          action: wasBookmarked ? 'unbookmark' : 'bookmark',
        );
      } catch (_) {
        final revertedList = List<CaseDiscussionListItem>.from(currentState.discussions);
        revertedList[idx] = item;
        emit(currentState.copyWith(discussions: revertedList));
      }
    }
  }

  Future<void> _onDeleteDiscussion(
      DeleteDiscussion event, Emitter<DiscussionListState> emit) async {
    final currentState = state;
    if (currentState is DiscussionListLoaded) {
      try {
        await repository.deleteCase(event.caseId);
        _discussions.removeWhere((d) => d.id == event.caseId);
        emit(currentState.copyWith(
          discussions: List.from(_discussions),
        ));
      } catch (_) {
        // Silently handle
      }
    }
  }
}
