import 'package:flutter/material.dart';

import 'feed_video_autoplay_registry.dart';

/// Pauses inline feed videos whenever a new route covers the current screen.
class FeedVideoNavigatorObserver extends NavigatorObserver {
  static final FeedVideoNavigatorObserver instance =
      FeedVideoNavigatorObserver();

  void _pauseForNavigation() {
    FeedVideoAutoplayRegistry.instance.pauseAll();
  }

  void _resumeAfterNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeedVideoAutoplayRegistry.instance.resume();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _pauseForNavigation();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _resumeAfterNavigation();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _resumeAfterNavigation();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute is PageRoute) _pauseForNavigation();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

/// Call when switching dashboard tabs or search tabs so hidden feeds stop audio.
void pauseFeedVideosForUiChange({bool resumeNextFrame = true}) {
  FeedVideoAutoplayRegistry.instance.pauseAll();
  if (resumeNextFrame) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeedVideoAutoplayRegistry.instance.resume();
    });
  }
}
