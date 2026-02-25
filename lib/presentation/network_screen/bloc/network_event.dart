part of 'network_bloc.dart';

abstract class NetworkEvent {
  const NetworkEvent();
}

/// Load friend requests (received / sent)
class LoadFriendRequestsEvent extends NetworkEvent {
  final String type; // 'received' or 'sent'
  final String search;
  final int page;
  const LoadFriendRequestsEvent({this.type = 'received', this.search = '', this.page = 1});
}

/// Load connections list
class LoadConnectionsEvent extends NetworkEvent {
  final String search;
  final int page;
  const LoadConnectionsEvent({this.search = '', this.page = 1});
}

/// Load people you may know
class LoadSuggestionsEvent extends NetworkEvent {
  final String search;
  final int page;
  const LoadSuggestionsEvent({this.search = '', this.page = 1});
}

/// Send friend request
class SendFriendRequestEvent extends NetworkEvent {
  final String userId;
  const SendFriendRequestEvent({required this.userId});
}

/// Accept friend request
class AcceptFriendRequestEvent extends NetworkEvent {
  final String requestId;
  const AcceptFriendRequestEvent({required this.requestId});
}

/// Reject friend request
class RejectFriendRequestEvent extends NetworkEvent {
  final String requestId;
  const RejectFriendRequestEvent({required this.requestId});
}

/// Cancel a sent friend request
class CancelFriendRequestEvent extends NetworkEvent {
  final String requestId;
  final String userId; // to also remove from suggestions 'Pending' state
  const CancelFriendRequestEvent({required this.requestId, this.userId = ''});
}

/// Remove existing connection
class RemoveConnectionEvent extends NetworkEvent {
  final String userId;
  const RemoveConnectionEvent({required this.userId});
}

/// Network search — search all users with connection status + filters
class NetworkSearchEvent extends NetworkEvent {
  final String query;
  final int page;
  final String specialty;
  final String country;
  const NetworkSearchEvent({
    required this.query,
    this.page = 1,
    this.specialty = '',
    this.country = '',
  });
}
