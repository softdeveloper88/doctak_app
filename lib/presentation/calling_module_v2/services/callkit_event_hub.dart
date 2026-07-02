import 'dart:async';

import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

/// Single owner of the `FlutterCallkitIncoming.onEvent` platform stream.
///
/// Flutter EventChannels deliver to ONE subscriber: every additional
/// `onEvent.listen(...)` steals the stream from previous listeners, and a
/// later cancel can tear the channel down for everyone. With both the
/// legacy calling module and calling_module_v2 (and historically several
/// services) subscribing independently, CallKit accepts were silently lost —
/// the #1 cause of "attended but nothing happened".
///
/// Every in-app consumer must listen to [stream] instead of the plugin
/// directly. The hub holds the only platform subscription and rebroadcasts.
/// (The FCM background isolate is a separate Dart VM with its own channel —
/// direct subscription there is fine.)
class CallKitEventHub {
  CallKitEventHub._();
  static final CallKitEventHub instance = CallKitEventHub._();

  StreamSubscription<CallEvent?>? _platformSubscription;
  final StreamController<CallEvent?> _controller =
      StreamController<CallEvent?>.broadcast();

  Stream<CallEvent?> get stream {
    _ensurePlatformSubscription();
    return _controller.stream;
  }

  void _ensurePlatformSubscription() {
    _platformSubscription ??= FlutterCallkitIncoming.onEvent.listen(
      _controller.add,
      onError: _controller.addError,
    );
  }
}
