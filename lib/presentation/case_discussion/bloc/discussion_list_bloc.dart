import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/case_discussion_repository.dart';
import '../models/case_discussion_models.dart';

// Events
abstract class DiscussionListEvent extends Equatable {
  const DiscussionListEvent();

  @override
  List<Object?> get props => [];
}

class LoadDiscussionList extends DiscussionListEvent {
  final bool refresh;
  final String? search;
  final String? specialty;
  final String? countryId;
  final String? sortBy;
  final String? sortOrder;
  final CaseDiscussionFilters? filters;

  const LoadDiscussionList({
    this.refresh = false,
    this.search,
    this.specialty,
    this.countryId,
    this.sortBy,
    this.sortOrder,
    this.filters,
  });

  @override
  List<Object?> get props => [refresh, search, specialty, countryId, sortBy, sortOrder, filters];
}

class LoadMoreDiscussions extends DiscussionListEvent {}

class RefreshDiscussionList extends DiscussionListEvent {}

class LikeDiscussion extends DiscussionListEvent {
  final int caseId;

  const LikeDiscussion(this.caseId);

  @override
  List<Object> get props => [caseId];
}

class LoadFilterData extends DiscussionListEvent {}

class DeleteDiscussion extends DiscussionListEvent {
  final int caseId;

  const DeleteDiscussion(this.caseId);

  @override
  List<Object> get props => [caseId];
}

class UpdateFilters extends DiscussionListEvent {
  final CaseDiscussionFilters filters;

  const UpdateFilters(this.filters);

  @override
  List<Object> get props => [filters];
}

// States
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
  List<Object> get props => [discussions, hasReachedMax, isLoadingMore, specialties, countries, currentFilters];

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

// BLoC
class DiscussionListBloc extends Bloc<DiscussionListEvent, DiscussionListState> {
  final CaseDiscussionRepository repository;

  int _currentPage = 1;
  List<CaseDiscussionListItem> _discussions = [];
  CaseDiscussionFilters _currentFilters = const CaseDiscussionFilters();
  List<SpecialtyFilter> _specialties = [];
  List<CountryFilter> _countries = [];

  DiscussionListBloc({required this.repository}) : super(DiscussionListInitial()) {
    on<LoadDiscussionList>(_onLoadDiscussionList);
    on<LoadMoreDiscussions>(_onLoadMoreDiscussions);
    on<RefreshDiscussionList>(_onRefreshDiscussionList);
    on<LikeDiscussion>(_onLikeDiscussion);
    on<LoadFilterData>(_onLoadFilterData);
    on<UpdateFilters>(_onUpdateFilters);
    on<DeleteDiscussion>(_onDeleteDiscussion);
  }

  Future<void> _onLoadDiscussionList(
    LoadDiscussionList event,
    Emitter<DiscussionListState> emit,
  ) async {
    if (event.refresh) {
      _currentPage = 1;
      _discussions.clear();
    }

    // Update current filters
    if (event.filters != null) {
      _currentFilters = event.filters!;
    }

    if (_discussions.isEmpty) {
      emit(DiscussionListLoading());
    }

    try {
      final result = await repository.getCaseDiscussions(
        page: _currentPage,
        search: event.search,
        specialty: event.specialty,
        countryId: event.countryId,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters ?? _currentFilters,
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
    LoadMoreDiscussions event,
    Emitter<DiscussionListState> emit,
  ) async {
    final currentState = state;
    if (currentState is DiscussionListLoaded && !currentState.hasReachedMax) {
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
    RefreshDiscussionList event,
    Emitter<DiscussionListState> emit,
  ) async {
    add(LoadDiscussionList(
      refresh: true,
      filters: _currentFilters,
    ));
  }

  Future<void> _onLikeDiscussion(
    LikeDiscussion event,
    Emitter<DiscussionListState> emit,
  ) async {
    try {
      // TODO: Add like state tracking to properly toggle like/unlike
      await repository.performCaseAction(
        caseId: event.caseId,
        action: 'like',
      );

      // Update the like count in the local list
      final currentState = state;
      if (currentState is DiscussionListLoaded) {
        final updatedDiscussions = currentState.discussions.map((discussion) {
          if (discussion.id == event.caseId) {
            // Create updated list item with incremented likes
            return CaseDiscussionListItem(
              id: discussion.id,
              title: discussion.title,
              tags: discussion.tags,
              likes: discussion.likes + 1,
              views: discussion.views,
              attachedFile: discussion.attachedFile,
              promoted: discussion.promoted,
              createdAt: discussion.createdAt,
              name: discussion.name,
              profilePic: discussion.profilePic,
              specialty: discussion.specialty,
              comments: discussion.comments,
            );
          }
          return discussion;
        }).toList();

        emit(currentState.copyWith(discussions: updatedDiscussions));
      }
    } catch (e) {
      // Handle error silently or show a snackbar
      print('Error liking discussion: $e');
    }
  }

  Future<void> _onLoadFilterData(
    LoadFilterData event,
    Emitter<DiscussionListState> emit,
  ) async {
    try {
      print('Loading filter data...');

      // Use the new getFilterData method
      final filterData = await repository.getFilterData();
      final specialties = filterData['specialties'] as List<SpecialtyFilter>;
      final countries = filterData['countries'] as List<CountryFilter>;

      _specialties = specialties;
      _countries = countries;

      print(
          'Loaded ${specialties.length} specialties and ${countries.length} countries');

      final currentState = state;
      if (currentState is DiscussionListLoaded) {
        emit(currentState.copyWith(
          specialties: specialties,
          countries: countries,
        ));
      } else {
        // If no discussions loaded yet, emit a loaded state with empty discussions
        // This ensures the filter UI can be displayed
        emit(DiscussionListLoaded(
          discussions: [],
          hasReachedMax: false,
          specialties: specialties,
          countries: countries,
          currentFilters: _currentFilters,
        ));
      }
    } catch (e) {
      print('Error loading filter data: $e');
      // Continue with fallback data
      final currentState = state;
      if (currentState is DiscussionListLoaded) {
        // Keep current state but ensure we have fallback data
        if (_specialties.isEmpty || _countries.isEmpty) {
          try {
            _specialties = await repository.getSpecialties();
            _countries = await repository.getCountries();
          } catch (_) {
            // Use empty lists if all else fails
            _specialties = [];
            _countries = [];
          }
        }
        emit(currentState.copyWith(
          specialties: _specialties,
          countries: _countries,
        ));
      }
    }
  }

  Future<void> _onUpdateFilters(
    UpdateFilters event,
    Emitter<DiscussionListState> emit,
  ) async {
    print('Updating filters: ${event.filters.toQueryParameters()}');

    _currentFilters = event.filters;

    // Reset pagination and reload discussions with new filters
    _currentPage = 1;
    _discussions.clear();

    // Reload discussions with new filters
    add(LoadDiscussionList(
      refresh: true,
      filters: _currentFilters,
    ));
  }

  Future<void> _onDeleteDiscussion(
    DeleteDiscussion event,
    Emitter<DiscussionListState> emit,
  ) async {
    try {
      print('🗑️ Starting delete process for case ID: ${event.caseId}');
      print('📋 Current discussions count: ${_discussions.length}');
      
      // Call API to delete case
      await repository.deleteCase(event.caseId);
      print('✅ API delete call successful');

      // Remove case from local list for real-time update
      final initialCount = _discussions.length;
      _discussions.removeWhere((discussion) => discussion.id == event.caseId);
      print('📋 Discussions count after removal: ${_discussions.length} (removed: ${initialCount - _discussions.length})');

      // Emit updated state
      final currentState = state;
      if (currentState is DiscussionListLoaded) {
        print('🔄 Emitting updated state with ${_discussions.length} discussions');
        emit(currentState.copyWith(discussions: List.from(_discussions)));
      }

      print('✅ Case deleted successfully and list updated');
    } catch (e) {
      print('❌ Error deleting case: $e');
      // Optionally emit an error state or show a snackbar
      // emit(DiscussionListError('Failed to delete discussion: $e'));
    }
  }
}
