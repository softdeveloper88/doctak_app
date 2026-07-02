import 'package:doctak_app/presentation/calling_module_v2/models/call_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

/// Calling module v2 — protocol mirror tests.
/// Verifies the Dart side stays wire-compatible with
/// doctak-node/lib/calls/protocol.ts.
void main() {
  group('CallState / CallEndReason wire mapping', () {
    test('states map both directions', () {
      expect(CallState.fromWire('RINGING'), CallState.ringing);
      expect(CallState.fromWire('CONNECTING'), CallState.connecting);
      expect(CallState.fromWire('ACTIVE'), CallState.active);
      expect(CallState.fromWire('RECONNECTING'), CallState.reconnecting);
      expect(CallState.fromWire('ENDED'), CallState.ended);
      // Unknown states must degrade safely to ended (server wins).
      expect(CallState.fromWire('garbage'), CallState.ended);
      expect(CallState.fromWire(null), CallState.ended);
    });

    test('end reasons cover the full enum', () {
      const wires = [
        'completed',
        'declined',
        'busy',
        'cancelled',
        'no_answer',
        'missed',
        'unreachable',
        'connect_failed',
        'network_failed',
        'error',
      ];
      for (final wire in wires) {
        expect(CallEndReason.fromWire(wire)?.wire, wire);
      }
      expect(CallEndReason.fromWire('nope'), isNull);
      expect(CallEndReason.fromWire(null), isNull);
    });
  });

  group('SignalEnvelopeV2', () {
    test('round-trips through JSON', () {
      const envelope = SignalEnvelopeV2(
        type: 'call.accept',
        callId: 'call-1',
        ts: 1234,
        payload: {'a': 1},
      );
      final json = envelope.toJson();
      expect(json['v'], kCallProtocolVersion);
      final parsed = SignalEnvelopeV2.tryParse(json);
      expect(parsed, isNotNull);
      expect(parsed!.type, 'call.accept');
      expect(parsed.callId, 'call-1');
      expect(parsed.payload['a'], 1);
    });

    test('rejects frames without type/callId', () {
      expect(SignalEnvelopeV2.tryParse({'callId': 'x'}), isNull);
      expect(SignalEnvelopeV2.tryParse({'type': 'call.end'}), isNull);
    });
  });

  group('CallSnapshotV2', () {
    test('parses a server snapshot', () {
      final snapshot = CallSnapshotV2.fromJson({
        'callId': 'c1',
        'state': 'ACTIVE',
        'endReason': null,
        'callType': 'video',
        'caller': {'id': 'u1', 'name': 'Alice', 'avatar': 'a.png'},
        'callee': {'id': 'u2', 'name': 'Bob', 'avatar': ''},
        'upgradedToVideo': true,
        'media': {
          'u1': {'muted': true, 'videoEnabled': false},
        },
      });
      expect(snapshot.state, CallState.active);
      expect(snapshot.callType, CallTypeV2.video);
      expect(snapshot.caller.name, 'Alice');
      expect(snapshot.callee.id, 'u2');
      expect(snapshot.upgradedToVideo, isTrue);
      expect(snapshot.media['u1']!.muted, isTrue);
    });

    test('tolerates missing fields (ENDED default)', () {
      final snapshot = CallSnapshotV2.fromJson(const {});
      expect(snapshot.state, CallState.ended);
      expect(snapshot.caller.name, 'Unknown');
    });
  });

  group('JoinChannelPayloadV2', () {
    test('parses Agora credentials', () {
      final payload = JoinChannelPayloadV2.fromJson({
        'appId': 'app',
        'channel': 'c1',
        'token': 'tok',
        'uid': 'u_123',
        'remoteUid': 'u_456',
        'callType': 'audio',
        'tokenExpiresAt': 999,
      });
      expect(payload.uid, 'u_123');
      expect(payload.remoteUid, 'u_456');
      expect(payload.callType, CallTypeV2.audio);
      expect(payload.tokenExpiresAt, 999);
    });
  });

  group('IncomingCallPushV2 (§5.4 contract)', () {
    Map<String, dynamic> validPush({String? expiresAt}) => {
          'type': 'incoming_call',
          'signalVersion': '2',
          'callId': 'c1',
          'callerId': 'u1',
          'callerName': 'Alice',
          'callerAvatar': 'a.png',
          'callType': 'video',
          'expiresAt': expiresAt ??
              '${DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch}',
        };

    test('parses a valid push', () {
      final push = IncomingCallPushV2.tryParse(validPush());
      expect(push, isNotNull);
      expect(push!.callId, 'c1');
      expect(push.callType, CallTypeV2.video);
      expect(push.isExpired, isFalse);
    });

    test('stale pushes are flagged expired (ghost-ring guard, edge 26)', () {
      final past =
          '${DateTime.now().subtract(const Duration(minutes: 2)).millisecondsSinceEpoch}';
      final push = IncomingCallPushV2.tryParse(validPush(expiresAt: past));
      expect(push, isNotNull);
      expect(push!.isExpired, isTrue);
    });

    test('rejects v1/legacy payloads and other types', () {
      expect(
        IncomingCallPushV2.tryParse({'type': 'incoming_call', 'callId': 'c1'}),
        isNull,
        reason: 'missing signalVersion=2 must not ring the v2 module',
      );
      expect(
        IncomingCallPushV2.tryParse({
          'type': 'call',
          'signalVersion': '2',
          'callId': 'c1',
        }),
        isNull,
      );
      expect(
        IncomingCallPushV2.tryParse({
          'type': 'incoming_call',
          'signalVersion': '2',
        }),
        isNull,
        reason: 'callId is mandatory',
      );
    });
  });
}
