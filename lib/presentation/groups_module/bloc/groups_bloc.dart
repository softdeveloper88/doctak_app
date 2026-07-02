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

  GroupsLoaded get _loaded =>
      state is GroupsLoaded ? state as GroupsLoaded : const GroupsLoaded();

  Future<void> _onBrowse(
    GroupsBrowseRequested event,
    Emitter<GroupsState> emit,
  ) async {
    final snapshot = _loaded;
    final keyword = event.keyword ?? snapshot.searchKeyword;
    final requestSeq = ++_browseRequestSeq;

    if (!event.refresh && state is GroupsInitial) {
      emit(const GroupsLoading());
    } else if (state is GroupsLoaded) {
      emit(snapshot.copyWith(clearError: true));
    }

    try {
      final result = await GroupsNodeApiService.browseGroups(
        keyword: keyword,
        scope: 'all',
      );
      if (requestSeq != _browseRequestSeq) return;

      final latest = _loaded;
      emit(
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
        ),
      );
    } catch (e) {
      if (requestSeq != _browseRequestSeq) return;
      if (state is GroupsLoading) {
        emit(GroupsFailure('Failed to load groups: $e'));
      } else {
        emit(_loaded.copyWith(errorMessage: '$e'));
      }
    }
  }

  Future<void> _onBrowseLoadMore(
    GroupsBrowseLoadMore event,
    Emitter<GroupsState> emit,
  ) async {
    final current = _loaded;
    if (!current.browseHasMore || current.browseLoadingMore) return;

    emit(current.copyWith(browseLoadingMore: true, clearError: true));
    try {
      final result = await GroupsNodeApiService.browseGroups(
        keyword: current.searchKeyword,
        scope: 'all',
        cursor: current.browseCursor,
      );
      emit(
        current.copyWith(
          browseItems: [...current.browseItems, ...result.items],
          browseCursor: result.nextCursor,
          browseHasMore: result.nextCursor != null,
          browseLoadingMore: false,
          facets: result.facets ?? current.facets,
          dataRevision: _nextRevision(current),
        ),
      );
    } catch (e) {
      emit(current.copyWith(browseLoadingMore: false, errorMessage: '$e'));
    }
  }

  Future<void> _onMine(
    GroupsMineRequested event,
    Emitter<GroupsState> emit,
  ) async {
    if (state is GroupsInitial) emit(const GroupsLoading());

    try {
      final result = await GroupsNodeApiService.browseGroups(
        scope: event.scope == 'mine' ? 'mine' : 'joined',
      );
      final current = _loaded;
      emit(
        GroupsLoaded(
          browseItems: current.browseItems,
          browseCursor: current.browseCursor,
          browseHasMore: current.browseHasMore,
          mineItems: event.scope == 'mine' ? current.mineItems : result.items,
          mineCursor: event.scope == 'mine' ? current.mineCursor : result.nextCursor,
          mineHasMore: event.scope == 'mine' ? current.mineHasMore : result.nextCursor != null,
          createdItems: event.scope == 'mine' ? result.items : current.createdItems,
          createdCursor: event.scope == 'mine' ? result.nextCursor : current.createdCursor,
          createdHasMore: event.scope == 'mine'
              ? result.nextCursor != null
              : current.createdHasMore,
          invitations: current.invitations,
          suggestions: current.suggestions,
          facets: result.facets ?? current.facets,
          searchKeyword: current.searchKeyword,
          joiningGroupIds: current.joiningGroupIds,
          dataRevision: _nextRevision(current),
        ),
      );
    } catch (e) {
      if (state is GroupsLoading) {
        emit(GroupsFailure('Failed to load your groups: $e'));
      } else {
        emit(_loaded.copyWith(errorMessage: '$e'));
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
    try {
      final items = await GroupsNodeApiService.getMyInvitations();
      final current = _loaded;
      emit(current.copyWith(invitations: items, clearError: true, dataRevision: _nextRevision(current)));
    } catch (e) {
      emit(_loaded.copyWith(errorMessage: '$e'));
    }
  }

  Future<void> _onSuggestions(
    GroupsSuggestionsRequested event,
    Emitter<GroupsState> emit,
  ) async {
    try {
      final items = await GroupsNodeApiService.getSuggestions(limit: 6);
      emit(_loaded.copyWith(suggestions: items, clearError: true, dataRevision: _nextRevision(_loaded)));
    } catch (e) {
      emit(_loaded.copyWith(errorMessage: '$e'));
    }
  }

  Future<void> _onJoin(
    GroupJoinRequested event,
    Emitter<GroupsState> emit,
  ) async {
    final current = _loaded;
    final id = event.group.routeId;
    final joining = {...current.joiningGroupIds, id};
    emit(current.copyWith(joiningGroupIds: joining, clearError: true));

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

      emit(
        current.copyWith(
          browseItems: current.browseItems.map(patchMembership).toList(),
          mineItems: current.mineItems.map(patchMembership).toList(),
          suggestions: current.suggestions.map(patchMembership).toList(),
          joiningGroupIds: {...joining}..remove(id),
          dataRevision: _nextRevision(current),
        ),
      );
      add(const GroupsMineRequested(refresh: true));
      add(const GroupsCreatedRequested(refresh: true));
    } catch (e) {
      emit(
        current.copyWith(
          joiningGroupIds: {...joining}..remove(id),
          errorMessage: '$e',
        ),
      );
    }
  }

  Future<void> _onInvitationRespond(
    GroupInvitationRespondRequested event,
    Emitter<GroupsState> emit,
  ) async {
    final current = _loaded;
    try {
      await GroupsNodeApiService.respondInvitation(
        event.invitationId,
        event.accept,
      );
      final remaining = current.invitations
          .where((inv) => inv.id != event.invitationId)
          .toList();
      emit(current.copyWith(invitations: remaining, clearError: true, dataRevision: _nextRevision(current)));
      if (event.accept) {
        add(const GroupsMineRequested(refresh: true));
      add(const GroupsCreatedRequested(refresh: true));
      }
    } catch (e) {
      emit(current.copyWith(errorMessage: '$e'));
    }
  }

  Future<void> _onSearchChanged(
    GroupsSearchChanged event,
    Emitter<GroupsState> emit,
  ) async {
    add(GroupsBrowseRequested(refresh: true, keyword: event.keyword));
  }
}
