import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctak_app/data/apiClient/services/network_api_service.dart';

part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final NetworkApiService _api = NetworkApiService();

  static bool _networkOrgIsFollowing(Map<String, dynamic> org) {
    final raw = org['is_following'] ?? org['isFollowing'];
    if (raw is bool) return raw;
    if (raw is num) return raw == 1;
    final text = raw?.toString().toLowerCase() ?? '';
    return text == '1' || text == 'true';
  }

  static Map<String, dynamic> _normalizeOrganization(Map<String, dynamic> org) {
    return {
      ...org,
      'is_following': _networkOrgIsFollowing(org),
    };
  }

  // Cache lists so UI can access them
  List<Map<String, dynamic>> friendRequests = [];
  List<Map<String, dynamic>> connections = [];
  List<Map<String, dynamic>> suggestions = [];
  List<Map<String, dynamic>> organizations = [];
  Map<String, dynamic> networkStats = {};
  String invitationSubtitle = '';
  List<String> invitationPreviewNames = [];
  int pendingCount = 0;

  // Track pagination states per tab
  int suggestionsPage = 1;
  bool suggestionsHasMore = false;
  int requestsPage = 1;
  bool requestsHasMore = false;
  int connectionsPage = 1;
  bool connectionsHasMore = false;
  int organizationsPage = 1;
  bool organizationsHasMore = false;
  bool isLoadingMore = false; // Flag for load-more spinner

  // Track which tabs have been loaded at least once
  bool hasLoadedHome = false;
  bool hasLoadedSuggestions = false;
  bool hasLoadedRequests = false;
  bool hasLoadedConnections = false;
  bool hasLoadedOrganizations = false;

  // Track which tab is currently loading
  String? activeLoadType;

  // Network search state
  List<Map<String, dynamic>> searchResults = [];
  int searchPage = 1;
  bool searchHasMore = false;
  bool hasSearched = false;
  String lastSearchQuery = '';
  String lastSearchSpecialty = '';
  String lastSearchCountry = '';
  String lastSearchScope = 'all';
  int searchPeopleCount = 0;
  int searchOrganizationCount = 0;

  NetworkBloc() : super(NetworkInitialState()) {
    on<LoadNetworkHomeEvent>(_onLoadNetworkHome);
    on<LoadOrganizationsEvent>(_onLoadOrganizations);
    on<ToggleOrganizationFollowEvent>(_onToggleOrganizationFollow);
    on<LoadFriendRequestsEvent>(_onLoadFriendRequests);
    on<LoadConnectionsEvent>(_onLoadConnections);
    on<LoadSuggestionsEvent>(_onLoadSuggestions);
    on<SendFriendRequestEvent>(_onSendRequest);
    on<AcceptFriendRequestEvent>(_onAcceptRequest);
    on<RejectFriendRequestEvent>(_onRejectRequest);
    on<CancelFriendRequestEvent>(_onCancelRequest);
    on<RemoveConnectionEvent>(_onRemoveConnection);
    on<NetworkSearchEvent>(_onNetworkSearch);
  }

  List<Map<String, dynamic>> _parsePaginatorItems(
    Map<String, dynamic> result,
    String key,
  ) {
    final paginator = result[key];
    if (paginator is Map) {
      final data = paginator['data'];
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    if (result['data'] is List) {
      return (result['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  Map<String, dynamic>? _paginatorMeta(
    Map<String, dynamic> result,
    String key,
  ) {
    final paginator = result[key];
    return paginator is Map ? Map<String, dynamic>.from(paginator) : null;
  }

  Future<void> _onLoadNetworkHome(
    LoadNetworkHomeEvent event,
    Emitter<NetworkState> emit,
  ) async {
    if (!event.silent) {
      emit(NetworkLoadingState());
    }
    try {
      final result = await _api.getNetworkHome();
      if (isClosed) return;

      final stats = result['stats'];
      if (stats is Map) {
        networkStats = Map<String, dynamic>.from(stats);
      }

      final preview = result['invitationPreview'];
      if (preview is Map) {
        pendingCount = _safeInt(preview['count']) ?? 0;
        invitationSubtitle = preview['subtitle']?.toString() ?? '';
        invitationPreviewNames = (preview['names'] as List<dynamic>? ?? [])
            .map((name) => name.toString())
            .where((name) => name.isNotEmpty)
            .toList();
      }

      friendRequests = _parsePaginatorItems(result, 'requests');
      suggestions = _parsePaginatorItems(result, 'people');
      connections = _parsePaginatorItems(result, 'connections');
      organizations = _parsePaginatorItems(result, 'businesses')
          .map(_normalizeOrganization)
          .toList();

      final requestsMeta = _paginatorMeta(result, 'requests');
      final peopleMeta = _paginatorMeta(result, 'people');
      final connectionsMeta = _paginatorMeta(result, 'connections');
      final businessesMeta = _paginatorMeta(result, 'businesses');

      requestsPage = _safeInt(requestsMeta?['current_page']) ?? 1;
      requestsHasMore =
          requestsPage < (_safeInt(requestsMeta?['last_page']) ?? 1);
      suggestionsPage = _safeInt(peopleMeta?['current_page']) ?? 1;
      suggestionsHasMore =
          suggestionsPage < (_safeInt(peopleMeta?['last_page']) ?? 1);
      connectionsPage = _safeInt(connectionsMeta?['current_page']) ?? 1;
      connectionsHasMore =
          connectionsPage < (_safeInt(connectionsMeta?['last_page']) ?? 1);
      organizationsPage = _safeInt(businessesMeta?['current_page']) ?? 1;
      organizationsHasMore =
          organizationsPage < (_safeInt(businessesMeta?['last_page']) ?? 1);

      pendingCount = _safeInt(requestsMeta?['total']) ?? pendingCount;

      hasLoadedHome = true;
      hasLoadedRequests = true;
      hasLoadedSuggestions = true;
      hasLoadedConnections = true;
      hasLoadedOrganizations = true;
      isLoadingMore = false;
      activeLoadType = null;

      emit(
        NetworkLoadedState(
          items: suggestions,
          currentPage: suggestionsPage,
          hasMore: suggestionsHasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      hasLoadedHome = true;
      hasLoadedRequests = true;
      hasLoadedSuggestions = true;
      hasLoadedConnections = true;
      hasLoadedOrganizations = true;
      emit(NetworkErrorState('Failed to load network: $e'));
    }
  }

  Future<void> _onLoadOrganizations(
    LoadOrganizationsEvent event,
    Emitter<NetworkState> emit,
  ) async {
    activeLoadType = 'organizations';
    if (event.page == 1) {
      isLoadingMore = false;
      if (!hasLoadedOrganizations) {
        emit(NetworkLoadingState());
      }
    } else {
      isLoadingMore = true;
      emit(
        NetworkLoadedState(
          items: organizations,
          currentPage: organizationsPage,
          hasMore: true,
        ),
      );
    }

    try {
      final result = await _api.getNetworkBusinesses(
        search: event.search,
        page: event.page,
      );
      if (isClosed) return;

      final items = _parsePaginatorItems(result, 'businesses')
          .map(_normalizeOrganization)
          .toList();
      final meta = _paginatorMeta(result, 'businesses');
      if (event.page == 1) {
        organizations = items;
      } else {
        organizations.addAll(items);
      }

      final currentPage = _safeInt(meta?['current_page']) ?? event.page;
      final lastPage = _safeInt(meta?['last_page']) ?? currentPage;
      organizationsPage = currentPage;
      organizationsHasMore = currentPage < lastPage;
      hasLoadedOrganizations = true;
      isLoadingMore = false;
      activeLoadType = null;

      emit(
        NetworkLoadedState(
          items: organizations,
          currentPage: currentPage,
          hasMore: organizationsHasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      isLoadingMore = false;
      activeLoadType = null;
      hasLoadedOrganizations = true;
      emit(NetworkErrorState(e.toString()));
    }
  }

  Future<void> _onToggleOrganizationFollow(
    ToggleOrganizationFollowEvent event,
    Emitter<NetworkState> emit,
  ) async {
    final index = organizations.indexWhere(
      (org) => org['id']?.toString() == event.organizationId,
    );
    if (index < 0) return;

    final org = organizations[index];
    final isFollowing = _networkOrgIsFollowing(org);
    try {
      final result = isFollowing
          ? await _api.unfollowOrganization(event.organizationId)
          : await _api.followOrganization(event.organizationId);

      if (isClosed) return;

      final nextFollowing = result['following'];
      org['is_following'] = nextFollowing != null
          ? _networkOrgIsFollowing({'is_following': nextFollowing})
          : !isFollowing;
      final followers = _safeInt(result['followers_count']) ??
          _safeInt(org['follower_count']) ??
          0;
      org['follower_count'] = followers;

      emit(
        NetworkActionSuccessState(
          result['message']?.toString() ??
              (isFollowing ? 'Unfollowed' : 'Following'),
        ),
      );
      emit(
        NetworkLoadedState(
          items: organizations,
          currentPage: organizationsPage,
          hasMore: organizationsHasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(NetworkErrorState(e.toString()));
    }
  }

  Future<void> _onLoadFriendRequests(
    LoadFriendRequestsEvent event,
    Emitter<NetworkState> emit,
  ) async {
    activeLoadType = event.type; // 'received' or 'sent'
    if (event.page == 1) {
      isLoadingMore = false;
      emit(NetworkLoadingState());
    } else {
      isLoadingMore = true;
      emit(NetworkLoadedState(items: friendRequests, currentPage: requestsPage, hasMore: true));
    }
    try {
      final result = await _api.getFriendRequests(
        type: event.type,
        search: event.search,
        page: event.page,
      );
      if (isClosed) return;
      // Backend returns { requests: { current_page, data: [...], last_page, total } }
      final requestsObj = result['requests'];
      final Map<String, dynamic>? requestsPaginator =
          requestsObj is Map ? Map<String, dynamic>.from(requestsObj) : null;
      final List<dynamic> data = requestsPaginator != null
          ? (requestsPaginator['data'] as List<dynamic>? ?? [])
          : (result['data'] as List<dynamic>? ?? []);
      final items = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      print('getFriendRequests(${event.type}) parsed ${items.length} items from requestsObj type: ${requestsObj.runtimeType}');
      if (event.page == 1) {
        friendRequests = items;
      } else {
        friendRequests.addAll(items);
      }
      pendingCount =
          _safeInt(requestsPaginator?['total'] ?? result['total']) ?? friendRequests.length;
      final currentPage =
          _safeInt(requestsPaginator?['current_page'] ?? result['current_page']) ?? 1;
      final lastPage =
          _safeInt(requestsPaginator?['last_page'] ?? result['last_page']) ?? 1;
      requestsPage = currentPage;
      requestsHasMore = currentPage < lastPage;
      hasLoadedRequests = true;
      isLoadingMore = false;
      activeLoadType = null;
      emit(
        NetworkLoadedState(
          items: friendRequests,
          currentPage: currentPage,
          hasMore: requestsHasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      isLoadingMore = false;
      activeLoadType = null;
      hasLoadedRequests = true; // Prevent infinite shimmer on error
      print('NetworkBloc._onLoadFriendRequests ERROR: $e');
      emit(NetworkErrorState('Failed to load friend requests: $e'));
    }
  }

  Future<void> _onLoadConnections(
    LoadConnectionsEvent event,
    Emitter<NetworkState> emit,
  ) async {
    activeLoadType = 'connections';
    if (event.page == 1) {
      isLoadingMore = false;
      emit(NetworkLoadingState());
    } else {
      isLoadingMore = true;
      emit(NetworkLoadedState(items: connections, currentPage: connectionsPage, hasMore: true));
    }
    try {
      final result = await _api.getConnections(
        search: event.search,
        page: event.page,
        viewUserId: event.viewUserId,
      );
      if (isClosed) return;
      // Backend returns { connections: { current_page, data: [...], last_page, total } }
      final connsObj = result['connections'];
      final Map<String, dynamic>? connsPaginator =
          connsObj is Map ? Map<String, dynamic>.from(connsObj) : null;
      final List<dynamic> data = connsPaginator != null
          ? (connsPaginator['data'] as List<dynamic>? ?? [])
          : (result['data'] as List<dynamic>? ?? []);
      final items = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (event.page == 1) {
        connections = items;
      } else {
        connections.addAll(items);
      }
      final currentPage =
          _safeInt(connsPaginator?['current_page'] ?? result['current_page']) ?? 1;
      final lastPage =
          _safeInt(connsPaginator?['last_page'] ?? result['last_page']) ?? 1;
      connectionsPage = currentPage;
      connectionsHasMore = currentPage < lastPage;
      hasLoadedConnections = true;
      isLoadingMore = false;
      activeLoadType = null;
      emit(
        NetworkLoadedState(
          items: connections,
          currentPage: currentPage,
          hasMore: connectionsHasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      isLoadingMore = false;
      activeLoadType = null;
      hasLoadedConnections = true;
      print('NetworkBloc._onLoadConnections ERROR: $e');
      emit(NetworkErrorState(e.toString()));
    }
  }

  Future<void> _onLoadSuggestions(
    LoadSuggestionsEvent event,
    Emitter<NetworkState> emit,
  ) async {
    activeLoadType = 'suggestions';
    if (event.page == 1) {
      isLoadingMore = false;
      emit(NetworkLoadingState());
    } else {
      isLoadingMore = true;
      emit(NetworkLoadedState(items: suggestions, currentPage: suggestionsPage, hasMore: true));
    }
    try {
      final result = await _api.getPeopleYouMayKnow(
        search: event.search,
        page: event.page,
      );
      if (isClosed) return;
      // 'people' is a paginator Map from the server: { current_page, data: [...], last_page, total }
      final peopleVal = result['people'];
      final Map<String, dynamic>? peoplePaginator =
          peopleVal is Map ? Map<String, dynamic>.from(peopleVal) : null;
      final List<dynamic> data = peoplePaginator != null
          ? (peoplePaginator['data'] as List<dynamic>? ?? [])
          : (peopleVal is List
              ? List<dynamic>.from(peopleVal)
              : (result['data'] as List<dynamic>? ?? []));
      final items = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (event.page == 1) {
        suggestions = items;
      } else {
        suggestions.addAll(items);
      }
      final currentPage =
          _safeInt(peoplePaginator?['current_page'] ?? result['current_page']) ?? 1;
      final lastPage =
          _safeInt(peoplePaginator?['last_page'] ?? result['last_page']) ?? 1;
      suggestionsPage = currentPage;
      suggestionsHasMore = currentPage < lastPage;
      hasLoadedSuggestions = true;
      isLoadingMore = false;
      activeLoadType = null;
      emit(
        NetworkLoadedState(
          items: suggestions,
          currentPage: currentPage,
          hasMore: suggestionsHasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      isLoadingMore = false;
      activeLoadType = null;
      hasLoadedSuggestions = true;
      print('NetworkBloc._onLoadSuggestions ERROR: $e');
      emit(NetworkErrorState(e.toString()));
    }
  }

  Future<void> _onSendRequest(
    SendFriendRequestEvent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      final result = await _api.sendFriendRequest(event.userId);
      if (isClosed) return;
      // Remove from suggestions
      suggestions.removeWhere((s) => s['id']?.toString() == event.userId);
      // Update search results to show pending_sent
      for (final s in searchResults) {
        if (s['id']?.toString() == event.userId) {
          s['connection_status'] = 'pending_sent';
          s['friend_request_id'] = result['friend_request_id'];
        }
      }
      emit(NetworkActionSuccessState(result['message'] ?? 'Request sent'));
      emit(NetworkLoadedState(items: suggestions));
    } catch (e) {
      if (isClosed) return;
      emit(NetworkErrorState(e.toString()));
    }
  }

  Future<void> _onAcceptRequest(
    AcceptFriendRequestEvent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      final result = await _api.acceptFriendRequest(event.requestId);
      if (isClosed) return;
      friendRequests.removeWhere((r) => r['id']?.toString() == event.requestId);
      for (final s in searchResults) {
        if (s['friend_request_id']?.toString() == event.requestId) {
          s['connection_status'] = 'connected';
        }
      }
      pendingCount = pendingCount > 0 ? pendingCount - 1 : 0;
      _syncInvitationPreview();
      emit(NetworkActionSuccessState(result['message'] ?? 'Request accepted'));
      emit(NetworkLoadedState(items: friendRequests));
    } catch (e) {
      if (isClosed) return;
      emit(NetworkErrorState(e.toString()));
    }
  }

  Future<void> _onRejectRequest(
    RejectFriendRequestEvent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      final result = await _api.rejectFriendRequest(event.requestId);
      if (isClosed) return;
      friendRequests.removeWhere((r) => r['id']?.toString() == event.requestId);
      for (final s in searchResults) {
        if (s['friend_request_id']?.toString() == event.requestId) {
          s['connection_status'] = 'none';
          s['friend_request_id'] = null;
        }
      }
      pendingCount = pendingCount > 0 ? pendingCount - 1 : 0;
      _syncInvitationPreview();
      emit(NetworkActionSuccessState(result['message'] ?? 'Request rejected'));
      emit(NetworkLoadedState(items: friendRequests));
    } catch (e) {
      if (isClosed) return;
      emit(NetworkErrorState(e.toString()));
    }
  }

  void _syncInvitationPreview() {
    invitationPreviewNames = friendRequests
        .map(_personNameFromRequest)
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList();
    if (pendingCount <= 0) {
      invitationSubtitle = '';
      return;
    }
    if (pendingCount == 1 && invitationPreviewNames.isNotEmpty) {
      invitationSubtitle = '${invitationPreviewNames.first} wants to connect';
    } else if (invitationPreviewNames.length >= 2) {
      invitationSubtitle =
          '${invitationPreviewNames.first} & ${pendingCount - 1} other${pendingCount - 1 == 1 ? '' : 's'} want to connect';
    } else {
      invitationSubtitle = '$pendingCount people want to connect';
    }
  }

  Future<void> _onRemoveConnection(
    RemoveConnectionEvent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      final result = await _api.removeConnection(event.userId);
      if (isClosed) return;
      connections.removeWhere((c) => c['id']?.toString() == event.userId);
      emit(
        NetworkActionSuccessState(result['message'] ?? 'Connection removed'),
      );
      emit(NetworkLoadedState(items: connections));
    } catch (e) {
      if (isClosed) return;
      emit(NetworkErrorState(e.toString()));
    }
  }

  Future<void> _onCancelRequest(
    CancelFriendRequestEvent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      final result = await _api.cancelFriendRequest(event.requestId);
      if (isClosed) return;
      // Remove from sent requests list
      friendRequests.removeWhere((r) => r['id']?.toString() == event.requestId);
      // Also reset friendRequestSent flag in suggestions so user can re-send
      if (event.userId.isNotEmpty) {
        for (final s in suggestions) {
          if (s['id']?.toString() == event.userId) {
            s['friendRequestSent'] = false;
          }
        }
      }
      // Also update search results
      for (final s in searchResults) {
        if (s['id']?.toString() == event.userId) {
          s['connection_status'] = 'none';
          s['friend_request_id'] = null;
        }
      }
      emit(NetworkActionSuccessState(result['message'] ?? 'Request canceled'));
      emit(NetworkLoadedState(items: friendRequests));
    } catch (e) {
      if (isClosed) return;
      emit(NetworkErrorState(e.toString()));
    }
  }

  Future<void> _onNetworkSearch(
    NetworkSearchEvent event,
    Emitter<NetworkState> emit,
  ) async {
    lastSearchQuery = event.query;
    lastSearchSpecialty = event.specialty;
    lastSearchCountry = event.country;
    lastSearchScope = event.scope;
    if (event.page == 1) {
      isLoadingMore = false;
      emit(NetworkLoadingState());
    } else {
      isLoadingMore = true;
      emit(NetworkLoadedState(items: searchResults, currentPage: searchPage, hasMore: true));
    }
    try {
      final result = await _api.networkSearch(
        query: event.query,
        page: event.page,
        specialty: event.specialty,
        country: event.country,
        type: event.scope,
      );
      if (isClosed) return;
      if (lastSearchQuery != event.query ||
          lastSearchSpecialty != event.specialty ||
          lastSearchCountry != event.country ||
          lastSearchScope != event.scope) {
        return;
      }

      final usersVal = result['users'];
      final Map<String, dynamic>? usersPaginator =
          usersVal is Map ? Map<String, dynamic>.from(usersVal) : null;
      final List<dynamic> userData = usersPaginator != null
          ? (usersPaginator['data'] as List<dynamic>? ?? [])
          : (usersVal is List
              ? List<dynamic>.from(usersVal)
              : (result['data'] as List<dynamic>? ?? []));

      final orgVal = result['organizations'];
      final List<dynamic> orgData = orgVal is List
          ? List<dynamic>.from(orgVal)
          : (orgVal is Map
              ? (orgVal['data'] as List<dynamic>? ?? [])
              : <dynamic>[]);

      final peopleItems = userData
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((item) {
            item.putIfAbsent('entity_type', () => 'people');
            item.putIfAbsent('type', () => 'people');
            return item;
          })
          .toList();

      final orgItems = orgData
          .map((e) => _normalizeOrganization(Map<String, dynamic>.from(e as Map)))
          .map((item) {
            item['entity_type'] = 'organization';
            item['type'] = 'organization';
            return item;
          })
          .toList();

      final merged = [...peopleItems, ...orgItems];

      final counts = result['counts'];
      if (counts is Map) {
        searchPeopleCount =
            int.tryParse('${counts['people'] ?? counts['peopleCount'] ?? 0}') ?? 0;
        searchOrganizationCount = int.tryParse(
                '${counts['organizations'] ?? counts['organizationCount'] ?? 0}') ??
            0;
      } else {
        searchPeopleCount = peopleItems.length;
        searchOrganizationCount = orgItems.length;
      }

      if (event.page == 1) {
        searchResults = merged;
      } else {
        searchResults.addAll(merged);
      }

      final currentPage =
          _safeInt(usersPaginator?['current_page'] ?? result['current_page']) ?? event.page;
      final lastPage =
          _safeInt(usersPaginator?['last_page'] ?? result['last_page']) ?? 1;
      searchPage = currentPage;
      searchHasMore = currentPage < lastPage;
      hasSearched = true;
      isLoadingMore = false;
      emit(NetworkLoadedState(
        items: searchResults,
        currentPage: currentPage,
        hasMore: searchHasMore,
      ));
    } catch (e) {
      if (isClosed) return;
      isLoadingMore = false;
      emit(NetworkErrorState(e.toString()));
    }
  }

  String _personNameFromRequest(Map<String, dynamic> request) {
    final sender = request['sender'];
    final person = sender is Map
        ? Map<String, dynamic>.from(sender)
        : request;
    final full = person['fullName']?.toString().trim();
    if (full != null && full.isNotEmpty) return full;
    return '${person['first_name'] ?? person['name'] ?? ''} ${person['last_name'] ?? ''}'
        .trim();
  }

  /// Safely parse a value that could be int or String to int
  int? _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
