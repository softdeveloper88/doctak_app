import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:equatable/equatable.dart';

abstract class GroupsState extends Equatable {
  const GroupsState();

  @override
  List<Object?> get props => [];
}

class GroupsInitial extends GroupsState {
  const GroupsInitial();
}

class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

class GroupsLoaded extends GroupsState {
  final List<GroupSummaryModel> browseItems;
  final String? browseCursor;
  final bool browseHasMore;
  final bool browseLoadingMore;

  final List<GroupSummaryModel> mineItems;
  final String? mineCursor;
  final bool mineHasMore;
  final bool mineLoadingMore;

  final List<GroupSummaryModel> createdItems;
  final String? createdCursor;
  final bool createdHasMore;
  final bool createdLoadingMore;

  final List<GroupInvitationModel> invitations;
  final List<GroupSummaryModel> suggestions;
  final GroupFacetsModel? facets;

  final String searchKeyword;
  final String? errorMessage;
  final Set<String> joiningGroupIds;
  final int dataRevision;

  const GroupsLoaded({
    this.browseItems = const [],
    this.browseCursor,
    this.browseHasMore = false,
    this.browseLoadingMore = false,
    this.mineItems = const [],
    this.mineCursor,
    this.mineHasMore = false,
    this.mineLoadingMore = false,
    this.createdItems = const [],
    this.createdCursor,
    this.createdHasMore = false,
    this.createdLoadingMore = false,
    this.invitations = const [],
    this.suggestions = const [],
    this.facets,
    this.searchKeyword = '',
    this.errorMessage,
    this.joiningGroupIds = const {},
    this.dataRevision = 0,
  });

  /// Hot-reload safe read — older in-memory instances may lack [dataRevision].
  int get resolvedDataRevision {
    final Object? raw = (this as dynamic).dataRevision;
    return raw is int ? raw : 0;
  }

  GroupsLoaded copyWith({
    List<GroupSummaryModel>? browseItems,
    String? browseCursor,
    bool? browseHasMore,
    bool? browseLoadingMore,
    List<GroupSummaryModel>? mineItems,
    String? mineCursor,
    bool? mineHasMore,
    bool? mineLoadingMore,
    List<GroupSummaryModel>? createdItems,
    String? createdCursor,
    bool? createdHasMore,
    bool? createdLoadingMore,
    List<GroupInvitationModel>? invitations,
    List<GroupSummaryModel>? suggestions,
    GroupFacetsModel? facets,
    String? searchKeyword,
    String? errorMessage,
    Set<String>? joiningGroupIds,
    int? dataRevision,
    bool clearError = false,
  }) {
    return GroupsLoaded(
      browseItems: browseItems ?? this.browseItems,
      browseCursor: browseCursor ?? this.browseCursor,
      browseHasMore: browseHasMore ?? this.browseHasMore,
      browseLoadingMore: browseLoadingMore ?? this.browseLoadingMore,
      mineItems: mineItems ?? this.mineItems,
      mineCursor: mineCursor ?? this.mineCursor,
      mineHasMore: mineHasMore ?? this.mineHasMore,
      mineLoadingMore: mineLoadingMore ?? this.mineLoadingMore,
      createdItems: createdItems ?? this.createdItems,
      createdCursor: createdCursor ?? this.createdCursor,
      createdHasMore: createdHasMore ?? this.createdHasMore,
      createdLoadingMore: createdLoadingMore ?? this.createdLoadingMore,
      invitations: invitations ?? this.invitations,
      suggestions: suggestions ?? this.suggestions,
      facets: facets ?? this.facets,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      joiningGroupIds: joiningGroupIds ?? this.joiningGroupIds,
      dataRevision: dataRevision ?? resolvedDataRevision,
    );
  }

  static int _listSignature(List<GroupSummaryModel> items) {
    return Object.hashAll(
      items.map(
        (g) => Object.hash(
          g.id,
          g.uuid,
          g.routeId,
          g.name,
          g.membership?.status,
          g.membership?.role,
          g.membersCount,
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [
        _listSignature(browseItems),
        browseCursor,
        browseHasMore,
        browseLoadingMore,
        _listSignature(mineItems),
        mineCursor,
        mineHasMore,
        mineLoadingMore,
        _listSignature(createdItems),
        createdCursor,
        createdHasMore,
        createdLoadingMore,
        invitations.map((e) => e.id).join(','),
        _listSignature(suggestions),
        facets?.pendingInvitations,
        searchKeyword,
        errorMessage,
        joiningGroupIds,
        resolvedDataRevision,
      ];
}

class GroupsFailure extends GroupsState {
  final String message;

  const GroupsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
