import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tracks whether the home feed is actively scrolling so heavy per-card work
/// (e.g. reaction-summary API calls) can be deferred until the list is idle.
///
/// Also throttles idle work so dozens of cards do not fire network + setState
/// in the same frame after scrolling stops.
class FeedScrollActivity {
  FeedScrollActivity._();

  static final FeedScrollActivity instance = FeedScrollActivity._();

  static const _idleDelay = Duration(milliseconds: 200);
  static const _maxConcurrentIdleTasks = 2;

  /// `true` while the user is actively scrolling the feed.
  final ValueNotifier<bool> isScrolling = ValueNotifier<bool>(false);

  Timer? _idleTimer;
  final List<Future<void> Function()> _idleQueue = [];
  int _runningIdleTasks = 0;

  /// Call on each scroll update. Marks the feed as scrolling and (re)arms an
  /// idle timer that flips back to idle shortly after scrolling stops.
  void notifyScrollActivity() {
    if (!isScrolling.value) isScrolling.value = true;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleDelay, () {
      isScrolling.value = false;
      _drainIdleQueue();
    });
  }

  /// Runs [action] now if the feed is idle, otherwise once it next becomes idle.
  void runWhenIdle(VoidCallback action) {
    scheduleWhenIdle(() async => action());
  }

  /// Schedules async work after scroll idle, max [_maxConcurrentIdleTasks] at once.
  void scheduleWhenIdle(Future<void> Function() task) {
    if (!isScrolling.value) {
      _enqueueIdleTask(task);
      return;
    }
    void listener() {
      if (!isScrolling.value) {
        isScrolling.removeListener(listener);
        _enqueueIdleTask(task);
      }
    }

    isScrolling.addListener(listener);
  }

  void _enqueueIdleTask(Future<void> Function() task) {
    _idleQueue.add(task);
    _drainIdleQueue();
  }

  void _drainIdleQueue() {
    if (isScrolling.value) return;
    while (_runningIdleTasks < _maxConcurrentIdleTasks && _idleQueue.isNotEmpty) {
      _runningIdleTasks++;
      final task = _idleQueue.removeAt(0);
      task().whenComplete(() {
        _runningIdleTasks--;
        _drainIdleQueue();
      });
    }
  }
}
