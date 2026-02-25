import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctak_app/data/apiClient/services/network_api_service.dart';

part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final NetworkApiService _api = NetworkApiService();

  // Cache lists so UI can access them
  List<Map<String, dynamic>> friendRequests = [];
  List<Map<String, dynamic>> connections = [];
  List<Map<String, dynamic>> suggestions = [];
  int pendingCount = 0;

  // Track pagination states per tab
  int suggestionsPage = 1;
  bool suggestionsHasMore = false;
  int requestsPage = 1;
  bool requestsHasMore = false;
  int connectionsPage = 1;
  bool connectionsHasMore = false;
  bool isLoadingMore = false; // Flag for load-more spinner

  // Track which tabs have been loaded at least once
  bool hasLoadedSuggestions = false;
  bool hasLoadedRequests = false;
  bool hasLoadedConnections = false;

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

  NetworkBloc() : super(NetworkInitialState()) {
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
      print('getFriendRequests(${event.type}) result keys: ${result.keys.toList()}, total: ${result['total']}');
      // Backend returns { requests: { data: [...] }, current_page, last_page, total }
      final requestsObj = result['requests'];
      final List<dynamic> data = requestsObj is Map
          ? (requestsObj['data'] as List<dynamic>? ?? [])
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
      pendingCount = _safeInt(result['total']) ?? friendRequests.length;
      final currentPage = _safeInt(result['current_page']) ?? 1;
      final lastPage = _safeInt(result['last_page']) ?? 1;
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
      );
      if (isClosed) return;
      // Backend returns { connections: { data: [...] }, current_page, last_page, total }
      final connsObj = result['connections'];
      final List<dynamic> data = connsObj is Map
          ? (connsObj['data'] as List<dynamic>? ?? [])
          : (result['data'] as List<dynamic>? ?? []);
      final items = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (event.page == 1) {
        connections = items;
      } else {
        connections.addAll(items);
      }
      final currentPage = _safeInt(result['current_page']) ?? 1;
      final lastPage = _safeInt(result['last_page']) ?? 1;
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
      final data =
          result['people'] as List<dynamic>? ??
          result['data'] as List<dynamic>? ??
          [];
      final items = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (event.page == 1) {
        suggestions = items;
      } else {
        suggestions.addAll(items);
      }
      final currentPage = _safeInt(result['current_page']) ?? 1;
      final lastPage = _safeInt(result['last_page']) ?? 1;
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
      emit(NetworkActionSuccessState(result['message'] ?? 'Request rejected'));
      emit(NetworkLoadedState(items: friendRequests));
    } catch (e) {
      if (isClosed) return;
      emit(NetworkErrorState(e.toString()));
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
      );
      if (isClosed) return;
      // If query/filters changed while loading, discard results
      if (lastSearchQuery != event.query ||
          lastSearchSpecialty != event.specialty ||
          lastSearchCountry != event.country) return;

      final data = result['users'] as List<dynamic>? ?? [];
      final items = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (event.page == 1) {
        searchResults = items;
      } else {
        searchResults.addAll(items);
      }
      final currentPage = _safeInt(result['current_page']) ?? 1;
      final lastPage = _safeInt(result['last_page']) ?? 1;
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

  /// Safely parse a value that could be int or String to int
  int? _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
