/// Calling module v2 — protocol mirror.
///
/// Dart mirror of `doctak-node/lib/calls/protocol.ts`. The server (CallSession
/// Durable Object) owns the canonical state machine; this client keeps a
/// mirror and reconciles from `call.state` snapshots — on conflict the
/// server wins.
library;

const int kCallProtocolVersion = 1;

/// Server-authoritative lifecycle states (§4 of the spec).
enum CallState {
  initiating('INITIATING'),
  ringing('RINGING'),
  connecting('CONNECTING'),
  active('ACTIVE'),
  reconnecting('RECONNECTING'),
  ended('ENDED');

  final String wire;
  const CallState(this.wire);

  static CallState fromWire(String? value) => CallState.values.firstWhere(
        (state) => state.wire == value,
        orElse: () => CallState.ended,
      );
}

enum CallEndReason {
  completed('completed'),
  declined('declined'),
  busy('busy'),
  cancelled('cancelled'),
  noAnswer('no_answer'),
  missed('missed'),
  unreachable('unreachable'),
  connectFailed('connect_failed'),
  networkFailed('network_failed'),
  error('error');

  final String wire;
  const CallEndReason(this.wire);

  static CallEndReason? fromWire(String? value) {
    if (value == null) return null;
    for (final reason in CallEndReason.values) {
      if (reason.wire == value) return reason;
    }
    return null;
  }
}

enum CallTypeV2 {
  audio('audio'),
  video('video');

  final String wire;
  const CallTypeV2(this.wire);

  static CallTypeV2 fromWire(String? value) =>
      value == 'video' ? CallTypeV2.video : CallTypeV2.audio;
}

/// Timing constants — keep in sync with CALL_TIMINGS in protocol.ts.
class CallTimings {
  static const ringTimeout = Duration(seconds: 40);
  static const connectTimeout = Duration(seconds: 30);
  static const reconnectGrace = Duration(seconds: 30);
  static const heartbeatInterval = Duration(seconds: 25);
  static const pushExpiry = Duration(seconds: 45);
}

class CallParticipant {
  final String id;
  final String name;
  final String avatar;

  const CallParticipant({required this.id, required this.name, required this.avatar});

  factory CallParticipant.fromJson(Map<String, dynamic> json) => CallParticipant(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown',
        avatar: json['avatar']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatar': avatar};
}

class CallMediaStateV2 {
  final bool muted;
  final bool videoEnabled;

  const CallMediaStateV2({this.muted = false, this.videoEnabled = false});

  factory CallMediaStateV2.fromJson(Map<String, dynamic> json) => CallMediaStateV2(
        muted: json['muted'] == true,
        videoEnabled: json['videoEnabled'] == true,
      );
}

/// Authoritative snapshot from the signaling server.
class CallSnapshotV2 {
  final String callId;
  final CallState state;
  final CallEndReason? endReason;
  final CallTypeV2 callType;
  final CallParticipant caller;
  final CallParticipant callee;
  final bool upgradedToVideo;
  final Map<String, CallMediaStateV2> media;

  const CallSnapshotV2({
    required this.callId,
    required this.state,
    required this.endReason,
    required this.callType,
    required this.caller,
    required this.callee,
    required this.upgradedToVideo,
    required this.media,
  });

  factory CallSnapshotV2.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['media'];
    final media = <String, CallMediaStateV2>{};
    if (mediaJson is Map) {
      mediaJson.forEach((key, value) {
        if (value is Map) {
          media[key.toString()] =
              CallMediaStateV2.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }
    return CallSnapshotV2(
      callId: json['callId']?.toString() ?? '',
      state: CallState.fromWire(json['state']?.toString()),
      endReason: CallEndReason.fromWire(json['endReason']?.toString()),
      callType: CallTypeV2.fromWire(json['callType']?.toString()),
      caller: CallParticipant.fromJson(
          Map<String, dynamic>.from(json['caller'] as Map? ?? const {})),
      callee: CallParticipant.fromJson(
          Map<String, dynamic>.from(json['callee'] as Map? ?? const {})),
      upgradedToVideo: json['upgradedToVideo'] == true,
      media: media,
    );
  }
}

/// Agora join credentials delivered via `call.join_channel`.
class JoinChannelPayloadV2 {
  final String appId;
  final String channel;
  final String token;
  final String uid; // Agora userAccount (string uid)
  final String remoteUid;
  final CallTypeV2 callType;
  final int tokenExpiresAt;

  const JoinChannelPayloadV2({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    required this.remoteUid,
    required this.callType,
    required this.tokenExpiresAt,
  });

  factory JoinChannelPayloadV2.fromJson(Map<String, dynamic> json) => JoinChannelPayloadV2(
        appId: json['appId']?.toString() ?? '',
        channel: json['channel']?.toString() ?? '',
        token: json['token']?.toString() ?? '',
        uid: json['uid']?.toString() ?? '',
        remoteUid: json['remoteUid']?.toString() ?? '',
        callType: CallTypeV2.fromWire(json['callType']?.toString()),
        tokenExpiresAt: (json['tokenExpiresAt'] as num?)?.toInt() ?? 0,
      );
}

/// Versioned signaling envelope (§2.1).
class SignalEnvelopeV2 {
  final String type;
  final String callId;
  final String? from;
  final int ts;
  final Map<String, dynamic> payload;

  const SignalEnvelopeV2({
    required this.type,
    required this.callId,
    this.from,
    required this.ts,
    this.payload = const {},
  });

  static SignalEnvelopeV2? tryParse(Map<String, dynamic> json) {
    final type = json['type']?.toString();
    final callId = json['callId']?.toString();
    if (type == null || callId == null) return null;
    final payload = json['payload'];
    return SignalEnvelopeV2(
      type: type,
      callId: callId,
      from: json['from']?.toString(),
      ts: (json['ts'] as num?)?.toInt() ?? 0,
      payload: payload is Map ? Map<String, dynamic>.from(payload) : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'v': kCallProtocolVersion,
        'type': type,
        'callId': callId,
        'ts': ts,
        'payload': payload,
      };
}

/// Incoming-call push payload (§5.4). All FCM data values are strings.
class IncomingCallPushV2 {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final CallTypeV2 callType;
  final int expiresAt;

  const IncomingCallPushV2({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.callType,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  static IncomingCallPushV2? tryParse(Map<String, dynamic> data) {
    if (data['type'] != 'incoming_call' || data['signalVersion'] != '2') return null;
    final callId = data['callId']?.toString();
    if (callId == null || callId.isEmpty) return null;
    return IncomingCallPushV2(
      callId: callId,
      callerId: data['callerId']?.toString() ?? '',
      callerName: data['callerName']?.toString() ?? 'Unknown',
      callerAvatar: data['callerAvatar']?.toString() ?? '',
      callType: CallTypeV2.fromWire(data['callType']?.toString()),
      expiresAt: int.tryParse(data['expiresAt']?.toString() ?? '') ??
          DateTime.now()
              .add(CallTimings.pushExpiry)
              .millisecondsSinceEpoch,
    );
  }
}
