import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'groups_event.dart';
import 'groups_state.dart';

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  GroupsBloc() : super(const GroupsInitial()) {
    on<GroupsBrowseRequested>(_onBrowse);
    on<GroupsBrowseLoadMore>(_onBrowseLoadMore);
    on<GroupsMineRequested>(_onMine);
    on<GroupsCreatedRequested>(_onCreated);
    on<GroupsInvitationsRequested>(_onInvitations);
    on<GroupsSuggestionsRequested>(_onSuggestions);
    on<GroupJoinRequested>(_onJoin);
    on<GroupInvitationRespondRequested>(_onInvitationRespond);
    on<GroupsSearchChanged>(_onSearchChanged);
  }

  int _browseRequestSeq = 0;
  int _nextRevision(GroupsLoaded current) => current.resolvedDataRevision + 1;

  // Single source of truth for accumulated list data. Deriving snapshots from
  // `state` returned an empty GroupsLoaded() whenever state was GroupsLoading,
  // so the browse/mine/invitations/suggestions fetches fired concurrently on
  // first load could wipe each other's slice while another request was still
  // in flight (leaving the list empty until pull-to-refresh). Keeping a
  // persistent snapshot makes every merge lossless regardless of ordering.
  GroupsLoaded _data = const GroupsLoaded();

  GroupsLoaded get _loaded => _data;

  void _pushLoaded(Emitter<GroupsState> emit, GroupsLoaded next) {
    _data = next;
    emit(next);
  }

  Future<void> _onBrowse(
    GroupsBrowseRequested event,
    Emitter<GroupsState> emit,
  ) async {
    final keyword = event.keyword ?? _loaded.searchKeyword;
    final requestSeq = ++_browseRequestSeq;

    if (!event.refresh && state is! GroupsLoaded) {
      _data = _data.copyWith(browseLoading: true, clearError: true);
      emit(const GroupsLoading());
    } else if (state is GroupsLoaded) {
      _pushLoaded(emit, _loaded.copyWith(browseLoading: true, clearError: true));
    } else {
      _data = _data.copyWith(browseLoading: true, clearError: true);
    }

    try {
      final result = await GroupsNodeApiService.browseGroups(
        keyword: keyword,
        scope: 'all',
      );
      if (requestSeq != _browseRequestSeq) return;

      final latest = _loaded;
      _pushLoaded(
        emit,
        GroupsLoaded(
          browseItems: result.items,
          browseCursor: result.nextCursor,
          browseHasMore: result.nextCursor != null,
          mineItems: latest.mineItems,
          mineCursor: latest.mineCursor,
          mineHasMore: latest.mineHasMore,
          createdItems: latest.createdItems,
          createdCursor: latest.createdCursor,
          createdHasMore: latest.createdHasMore,
          invitations: latest.invitations,
          suggestions: latest.suggestions,
          facets: result.facets ?? latest.facets,
          searchKeyword: keyword,
          joiningGroupIds: latest.joiningGroupIds,
          dataRevision: _nextRevision(latest),
          browseLoading: false,
          mineLoading: latest.mineLoading,
          createdLoading: latest.createdLoading,
          invitationsLoading: latest.invitationsLoading,
          suggestionsLoading: latest.suggestionsLoading,
        ),
      );
    } catch (e) {
      if (requestSeq != _browseRequestSeq) return;
      if (state is! GroupsLoaded) {
        emit(GroupsFailure('Failed to load groups: $e'));
      } else {
        _pushLoaded(emit, _loaded.copyWith(browseLoading: false, errorMessage: '$e'));
      }
    }
  }

  Future<void> _onBrowseLoadMore(
    GroupsBrowseLoadMore event,
    Emitter<GroupsState> emit,
  ) async {
    final current = _loaded;
    if (!current.browseHasMore || current.browseLoadingMore) return;

    _pushLoaded(emit, current.copyWith(browseLoadingMore: true, clearError: true));
    try {
      final result = await GroupsNodeApiService.browseGroups(
        keyword: current.searchKeyword,
        scope: 'all',
        cursor: current.browseCursor,
      );
      final latest = _loaded;
      _pushLoaded(
        emit,
        latest.copyWith(
          browseItems: [...latest.browseItems, ...result.items],
          browseCursor: result.nextCursor,
          browseHasMore: result.nextCursor != null,
          browseLoadingMore: false,
          facets: result.facets ?? latest.facets,
          dataRevision: _nextRevision(latest),
        ),
      );
    } catch (e) {
      _pushLoaded(emit, _loaded.copyWith(browseLoadingMore: false, errorMessage: '$e'));
    }
  }

  Future<void> _onMine(
    GroupsMineRequested event,
    Emitter<GroupsState> emit,
  ) async {
    final isCreated = event.scope == 'mine';
    if (state is! GroupsLoaded) {
      _data = _data.copyWith(
        mineLoading: isCreated ? _data.mineLoading : true,
        createdLoading: isCreated ? true : _data.createdLoading,
      );
      emit(const GroupsLoading());
    } else {
      _pushLoaded(
        emit,
        _loaded.copyWith(
          mineLoading: isCreated ? _loaded.mineLoading : true,
          createdLoading: isCreated ? true : _loaded.createdLoading,
        ),
      );
    }

    try {
      final result = await GroupsNodeApiService.browseGroups(
        scope: isCreated ? 'mine' : 'joined',
      );
      final current = _loaded;
      _pushLoaded(
        emit,
        GroupsLoaded(
          browseItems: current.browseItems,
          browseCursor: current.browseCursor,
          browseHasMore: current.browseHasMore,
          mineItems: isCreated ? current.mineItems : result.items,
          mineCursor: isCreated ? current.mineCursor : result.nextCursor,
          mineHasMore: isCreated ? current.mineHasMore : result.nextCursor != null,
          createdItems: isCreated ? result.items : current.createdItems,
          createdCursor: isCreated ? result.nextCursor : current.createdCursor,
          createdHasMore: isCreated
              ? result.nextCursor != null
              : current.createdHasMore,
          invitations: current.invitations,
          suggestions: current.suggestions,
          facets: result.facets ?? current.facets,
          searchKeyword: current.searchKeyword,
          joiningGroupIds: current.joiningGroupIds,
          dataRevision: _nextRevision(current),
          browseLoading: current.browseLoading,
          mineLoading: isCreated ? current.mineLoading : false,
          createdLoading: isCreated ? false : current.createdLoading,
          invitationsLoading: current.invitationsLoading,
          suggestionsLoading: current.suggestionsLoading,
        ),
      );
    } catch (e) {
      if (state is! GroupsLoaded) {
        emit(GroupsFailure('Failed to load your groups: $e'));
      } else {
        _pushLoaded(
          emit,
          _loaded.copyWith(
            mineLoading: isCreated ? _loaded.mineLoading : false,
            createdLoading: isCreated ? false : _loaded.createdLoading,
            errorMessage: '$e',
          ),
        );
      }
    }
  }

  Future<void> _onCreated(
    GroupsCreatedRequested event,
    Emitter<GroupsState> emit,
  ) async {
    add(GroupsMineRequested(refresh: event.refresh, scope: 'mine'));
  }

  Future<void> _onInvitations(
    GroupsInvitationsRequested event,
    Emitter<GroupsState> emit,
  ) async {
    if (state is GroupsLoaded) {
      _pushLoaded(emit, _loaded.copyWith(invitationsLoading: true));
    } else {
      _data = _data.copyWith(invitationsLoading: true);
    }
    try {
      final items = await GroupsNodeApiService.getMyInvitations();
      final current = _loaded;
      _pushLoaded(emit, current.copyWith(invitations: items, clearError: true, invitationsLoading: false, dataRevision: _nextRevision(current)));
    } catch (e) {
      _pushLoaded(emit, _loaded.copyWith(invitationsLoading: false, errorMessage: '$e'));
    }
  }

  Future<void> _onSuggestions(
    GroupsSuggestionsRequested event,
    Emitter<GroupsState> emit,
  ) async {
    if (state is GroupsLoaded) {
      _pushLoaded(emit, _loaded.copyWith(suggestionsLoading: true));
    } else {
      _data = _data.copyWith(suggestionsLoading: true);
    }
    try {
      final items = await GroupsNodeApiService.getSuggestions(limit: 6);
      _pushLoaded(emit, _loaded.copyWith(suggestions: items, clearError: true, suggestionsLoading: false, dataRevision: _nextRevision(_loaded)));
    } catch (e) {
      _pushLoaded(emit, _loaded.copyWith(suggestionsLoading: false, errorMessage: '$e'));
    }
  }

  Future<void> _onJoin(
    GroupJoinRequested event,
    Emitter<GroupsState> emit,
  ) async {
    final id = event.group.routeId;
    final joining = {..._loaded.joiningGroupIds, id};
    _pushLoaded(emit, _loaded.copyWith(joiningGroupIds: joining, clearError: true));

    try {
      await GroupsNodeApiService.joinGroup(id);
      GroupSummaryModel patchMembership(GroupSummaryModel g) {
        if (g.routeId != id) return g;
        return GroupSummaryModel(
          id: g.id,
          uuid: g.uuid,
          name: g.name,
          description: g.description,
          privacy: g.privacy,
          groupType: g.groupType,
          bannerImage: g.bannerImage,
          logoImage: g.logoImage,
          primaryColor: g.primaryColor,
          secondaryColor: g.secondaryColor,
          specialtyId: g.specialtyId,
          specialty: g.specialty,
          isVerified: g.isVerified,
          membersCount: g.membersCount + 1,
      postsCount: g.postsCount,
      pollsCount: g.pollsCount,
      articlesCount: g.articlesCount,
      lastActivityAt: g.lastActivityAt,
          createdAt: g.createdAt,
          membership: const GroupMembershipModel(
            role: 'member',
            status: 'active',
          ),
        );
      }

      final latest = _loaded;
      _pushLoaded(
        emit,
        latest.copyWith(
          browseItems: latest.browseItems.map(patchMembership).toList(),
          mineItems: latest.mineItems.map(patchMembership).toList(),
          suggestions: latest.suggestions.map(patchMembership).toList(),
          joiningGroupIds: {...latest.joiningGroupIds}..remove(id),
          dataRevision: _nextRevision(latest),
        ),
      );
      add(const GroupsMineRequested(refresh: true));
      add(const GroupsCreatedRequested(refresh: true));
    } catch (e) {
      _pushLoaded(
        emit,
        _loaded.copyWith(
          joiningGroupIds: {..._loaded.joiningGroupIds}..remove(id),
          errorMessage: '$e',
        ),
      );
    }
  }

  Future<void> _onInvitationRespond(
    GroupInvitationRespondRequested event,
    Emitter<GroupsState> emit,
  ) async {
    try {
      await GroupsNodeApiService.respondInvitation(
        event.invitationId,
        event.accept,
      );
      final latest = _loaded;
      final remaining = latest.invitations
          .where((inv) => inv.id != event.invitationId)
          .toList();
      _pushLoaded(emit, latest.copyWith(invitations: remaining, clearError: true, dataRevision: _nextRevision(latest)));
      if (event.accept) {
        add(const GroupsMineRequested(refresh: true));
      add(const GroupsCreatedRequested(refresh: true));
      }
    } catch (e) {
      _pushLoaded(emit, _loaded.copyWith(errorMessage: '$e'));
    }
  }

  Future<void> _onSearchChanged(
    GroupsSearchChanged event,
    Emitter<GroupsState> emit,
  ) async {
    add(GroupsBrowseRequested(refresh: true, keyword: event.keyword));
  }
}
