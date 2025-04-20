import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../utils/constants.dart';
import 'dart:async';

class PusherService {
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  final String _meetingId;
  bool _isInitialized = false;

  // Event streams
  final _onNewMessage = StreamController<Map<String, dynamic>>.broadcast();
  final _onUserAllowed = StreamController<String>.broadcast();
  final _onUserRejected = StreamController<Map<String, dynamic>>.broadcast();
  final _onMeetingEnded = StreamController<Map<String, dynamic>>.broadcast();
  final _onSettingsUpdated = StreamController<Map<String, dynamic>>.broadcast();
  final _onHandRaised = StreamController<Map<String, dynamic>>.broadcast();
  final _onRecordingStarted = StreamController<Map<String, dynamic>>.broadcast();
  final _onRecordingStopped = StreamController<Map<String, dynamic>>.broadcast();
  final _onMuteAll = StreamController<Map<String, dynamic>>.broadcast();
  final _onAnnouncement = StreamController<Map<String, dynamic>>.broadcast();
  final _onNewUserJoin = StreamController<Map<String, dynamic>>.broadcast();
  final _onMeetingStatus = StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get onNewMessage => _onNewMessage.stream;
  Stream<String> get onUserAllowed => _onUserAllowed.stream;
  Stream<Map<String, dynamic>> get onUserRejected => _onUserRejected.stream;
  Stream<Map<String, dynamic>> get onMeetingEnded => _onMeetingEnded.stream;
  Stream<Map<String, dynamic>> get onSettingsUpdated => _onSettingsUpdated.stream;
  Stream<Map<String, dynamic>> get onHandRaised => _onHandRaised.stream;
  Stream<Map<String, dynamic>> get onRecordingStarted => _onRecordingStarted.stream;
  Stream<Map<String, dynamic>> get onRecordingStopped => _onRecordingStopped.stream;
  Stream<Map<String, dynamic>> get onMuteAll => _onMuteAll.stream;
  Stream<Map<String, dynamic>> get onAnnouncement => _onAnnouncement.stream;
  Stream<Map<String, dynamic>> get onNewUserJoin => _onNewUserJoin.stream;
  Stream<Map<String, dynamic>> get onMeetingStatus => _onMeetingStatus.stream;

  PusherService(this._meetingId);

  // Initialize Pusher
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _pusher.init(
        apiKey: PUSHER_APP_KEY,
        cluster: PUSHER_CLUSTER,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
      );

      await _pusher.subscribe(
        channelName: 'meeting-channel$_meetingId',
        onEvent: _onEvent,
      );
    print('meetingId $_meetingId');
      await _pusher.connect();

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing Pusher: $e");
      }
      rethrow;
    }
  }

  // Handle connection state changes
  void _onConnectionStateChange(String currentState, String previousState) {
    if (kDebugMode) {
      print("Pusher connection state: $currentState");
    }
  }

  // Handle errors
  void _onError(String message, int? code, dynamic e) {
    if (kDebugMode) {
      print("Pusher error: $message (Code: $code)");
    }
  }

  // Handle incoming events
  void _onEvent(event) {
    final eventData = event.data;
    print(event.data);
    if (eventData != null) {
      switch (event.eventName) {
        case 'new-message':
          _onNewMessage.add(eventData);
          break;
        case 'new-user-allowed':
          _onUserAllowed.add(eventData['user_id']);
          break;
          case 'new-user-join':
            _onNewUserJoin.add(eventData['user_id']);
          break;
        case 'new-user-rejected':
          _onUserRejected.add(eventData);
          break;
        case 'meeting-ended':
          _onMeetingEnded.add(eventData);
          break;
        case 'settings-updated':
          _onSettingsUpdated.add(eventData);
          break;
        case 'hand-raised':
          _onHandRaised.add(eventData);
          break;
        case 'recording-started':
          _onRecordingStarted.add(eventData);
          break;
        case 'recording-stopped':
          _onRecordingStopped.add(eventData);
          break;
        case 'mute-all':
          _onMuteAll.add(eventData);
          break;
        case 'announcement':
          _onAnnouncement.add(eventData);
          break;
        case 'new-user-join':
          _onNewUserJoin.add(eventData);
          break;
        case 'meeting-status':
          _onMeetingStatus.add(eventData);
          break;
        default:
          if (kDebugMode) {
            print("Unhandled event: ${event.eventName}");
          }
      }
    }
  }

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Disconnect and dispose
  void dispose() {
    _onNewMessage.close();
    _onUserAllowed.close();
    _onUserRejected.close();
    _onMeetingEnded.close();
    _onSettingsUpdated.close();
    _onHandRaised.close();
    _onRecordingStarted.close();
    _onRecordingStopped.close();
    _onMuteAll.close();
    _onAnnouncement.close();
    _onNewUserJoin.close();
    _onMeetingStatus.close();

    _pusher.unsubscribe(channelName: 'meeting-channel$_meetingId');
    _pusher.disconnect();
    _isInitialized = false;
  }
}
