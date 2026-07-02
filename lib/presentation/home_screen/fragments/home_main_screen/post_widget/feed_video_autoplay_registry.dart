import 'package:flutter/foundation.dart';

/// Picks one feed video at a time — the one closest to the viewport center.
class FeedVideoAutoplayRegistry {
  FeedVideoAutoplayRegistry._();
  static final FeedVideoAutoplayRegistry instance = FeedVideoAutoplayRegistry._();

  static const double minVisibleFraction = 0.45;

  final Map<String, _FeedVideoCandidate> _candidates = {};
  String? _activeId;
  bool _suspended = false;

  bool get isSuspended => _suspended;

  void updateCandidate({
    required String id,
    required double centerDistance,
    required double visibleFraction,
    required double maxCenterDistance,
    required VoidCallback onActivate,
    required VoidCallback onDeactivate,
  }) {
    _candidates[id] = _FeedVideoCandidate(
      centerDistance: centerDistance,
      visibleFraction: visibleFraction,
      maxCenterDistance: maxCenterDistance,
      onActivate: onActivate,
      onDeactivate: onDeactivate,
    );
    _syncActive();
  }

  void removeCandidate(String id) {
    final wasActive = _activeId == id;
    _candidates.remove(id);
    if (wasActive) _activeId = null;
    _syncActive();
  }

  /// Stops the active inline feed video and blocks autoplay until [resume].
  void pauseAll() {
    final previous = _activeId;
    _activeId = null;
    _suspended = true;
    if (previous != null) {
      _candidates[previous]?.onDeactivate();
    }
  }

  /// Re-enables autoplay; the centered visible candidate wins on next sync.
  void resume() {
    if (!_suspended) return;
    _suspended = false;
    _syncActive();
  }

  void _syncActive() {
    if (_suspended) return;

    String? bestId;
    var bestDistance = double.infinity;

    for (final entry in _candidates.entries) {
      final candidate = entry.value;
      if (candidate.visibleFraction < minVisibleFraction) continue;
      if (candidate.centerDistance > candidate.maxCenterDistance) continue;
      if (candidate.centerDistance < bestDistance) {
        bestDistance = candidate.centerDistance;
        bestId = entry.key;
      }
    }

    if (bestId == _activeId) return;

    final previous = _activeId;
    _activeId = bestId;

    if (previous != null && previous != bestId) {
      _candidates[previous]?.onDeactivate();
    }
    if (bestId != null) {
      _candidates[bestId]?.onActivate();
    }
  }
}

class _FeedVideoCandidate {
  final double centerDistance;
  final double visibleFraction;
  final double maxCenterDistance;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  const _FeedVideoCandidate({
    required this.centerDistance,
    required this.visibleFraction,
    required this.maxCenterDistance,
    required this.onActivate,
    required this.onDeactivate,
  });
}
