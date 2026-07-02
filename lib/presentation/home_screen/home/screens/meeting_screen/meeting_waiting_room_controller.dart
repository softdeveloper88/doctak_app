import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/services/meeting_websocket_service.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:flutter/material.dart';

typedef MeetingWaitingRoomEnterCallback = Future<void> Function();

/// Waiting-room realtime for legacy meeting screens (replaces Pusher).
class MeetingWaitingRoomController {
  final MeetingWebSocketService _ws = MeetingWebSocketService();
  StreamSubscription<MeetingWsEvent>? _sub;
  Timer? _pollTimer;
  bool _transitionStarted = false;

  Future<void> connect({
    required BuildContext context,
    required String meetingId,
    required String channel,
    required MeetingWaitingRoomEnterCallback onApproved,
    VoidCallback? onRejected,
  }) async {
    _startPolling(context, channel, onApproved);
    final id = meetingId.trim();
    if (id.isEmpty) return;

    _sub?.cancel();
    _sub = _ws.events.listen((event) async {
      if (event is! MeetingRealtimeEvent) return;
      switch (event.event) {
        case 'allow-join-request':
        case 'new-user-allowed':
          final targetId = event.payload['id']?.toString() ?? '';
          if (targetId.isEmpty || targetId == AppData.logInUserId) {
            await _enterOnce(onApproved);
          }
          break;
        case 'reject-join-request':
        case 'new-user-rejected':
          final targetId = event.payload['id']?.toString() ?? '';
          if (targetId.isEmpty || targetId == AppData.logInUserId) {
            _cancelPolling();
            ProgressDialogUtils.hideProgressDialog();
            onRejected?.call();
          }
          break;
      }
    });
    await _ws.connect(id);
  }

  void _startPolling(
    BuildContext context,
    String channel,
    MeetingWaitingRoomEnterCallback onApproved,
  ) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_transitionStarted) {
        timer.cancel();
        return;
      }
      try {
        final resp = await askToJoin(context, channel);
        if (resp.success != true) return;
        final data = resp.data is Map<String, dynamic>
            ? resp.data as Map<String, dynamic>
            : Map<String, dynamic>.from(jsonDecode(jsonEncode(resp.data)) as Map);
        final status = data['status']?.toString() ?? '';
        final participant = data['participant'];
        final isAllowed =
            participant is Map ? participant['isAllowed'] == true : false;
        final isWaiting =
            data['waiting'] == true || status == 'waiting_room';
        final isSuccess =
            data['success'] == true || data['success'] == '1';
        if (!isSuccess) return;
        if (isWaiting && !isAllowed) return;
        final approved = isAllowed ||
            (status.isNotEmpty && status != 'waiting_room' && !isWaiting);
        if (approved) {
          timer.cancel();
          await _enterOnce(onApproved);
        }
      } catch (_) {
        // Keep polling on transient errors.
      }
    });
  }

  Future<void> _enterOnce(MeetingWaitingRoomEnterCallback onApproved) async {
    if (_transitionStarted) return;
    _transitionStarted = true;
    _cancelPolling();
    await onApproved();
  }

  void _cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> dispose() async {
    _cancelPolling();
    await _sub?.cancel();
    _sub = null;
    await _ws.disconnect();
    _transitionStarted = false;
  }
}
