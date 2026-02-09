import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Configuration for lazy loading behavior
class LazyLoadConfig {
  final double preloadDistance;
  final int minPreloadItems;
  final Duration debounceDelay;
  
  const LazyLoadConfig({
    this.preloadDistance = 500.0,
    this.minPreloadItems = 3,
    this.debounceDelay = const Duration(milliseconds: 100),
  });
}

/// A widget that only builds its child when visible
/// Dramatically improves scrolling performance for heavy items
class LazyLoadItem extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Widget? placeholder;
  final double estimatedHeight;
  final String? itemKey;
  final bool keepAlive;
  final VoidCallback? onBecameVisible;
  final VoidCallback? onBecameInvisible;

  const LazyLoadItem({
    super.key,
    required this.builder,
    this.placeholder,
    this.estimatedHeight = 300,
    this.itemKey,
    this.keepAlive = false,
    this.onBecameVisible,
    this.onBecameInvisible,
  });

  @override
  State<LazyLoadItem> createState() => _LazyLoadItemState();
}

class _LazyLoadItemState extends State<LazyLoadItem>
    with AutomaticKeepAliveClientMixin {
  bool _isVisible = false;
  bool _hasBeenVisible = false;
  Widget? _cachedChild;

  @override
  bool get wantKeepAlive => widget.keepAlive && _hasBeenVisible;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return VisibilityDetector(
      key: Key(widget.itemKey ?? hashCode.toString()),
      onVisibilityChanged: _handleVisibilityChanged,
      child: _buildContent(),
    );
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    // Check if the info has valid bounds before processing
    if (info.size.isEmpty) return;
    
    final wasVisible = _isVisible;
    _isVisible = info.visibleFraction > 0;
    
    if (_isVisible && !wasVisible) {
      _hasBeenVisible = true;
      widget.onBecameVisible?.call();
      if (mounted) setState(() {});
    } else if (!_isVisible && wasVisible) {
      widget.onBecameInvisible?.call();
      // Don't clear cache immediately - keep for scroll back
    }
  }

  Widget _buildContent() {
    // If visible or has been visible and keepAlive, show real content
    if (_isVisible || (_hasBeenVisible && widget.keepAlive)) {
      _cachedChild ??= widget.builder(context);
      return _cachedChild!;
    }
    
    // Show placeholder
    return widget.placeholder ?? 
        SizedBox(height: widget.estimatedHeight);
  }

  @override
  void dispose() {
    _cachedChild = null;
    super.dispose();
  }
}

/// Optimized scroll physics for smoother scrolling
class OptimizedScrollPhysics extends ScrollPhysics {
  const OptimizedScrollPhysics({super.parent});

  @override
  OptimizedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OptimizedScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 50.0; // Lower threshold for fling
  
  @override
  double get maxFlingVelocity => 8000.0; // Cap max velocity
  
  @override
  double carriedMomentum(double existingVelocity) {
    // Smoother momentum carry-over
    return existingVelocity.sign * 
           (existingVelocity.abs() * 0.6).clamp(0.0, 3000.0);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position, 
    double velocity,
  ) {
    // Use smoother deceleration
    if (velocity.abs() < minFlingVelocity) return null;
    
    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      friction: 0.015, // Smoother friction
    );
  }
}

/// Controller for optimized list with preloading
class OptimizedListController extends ChangeNotifier {
  final Set<int> _visibleIndices = {};
  final Set<int> _preloadedIndices = {};
  int _totalItems = 0;
  
  Set<int> get visibleIndices => Set.from(_visibleIndices);
  Set<int> get preloadedIndices => Set.from(_preloadedIndices);
  
  void updateTotalItems(int count) {
    _totalItems = count;
  }
  
  void markVisible(int index) {
    if (_visibleIndices.add(index)) {
      _updatePreloadRange();
      notifyListeners();
    }
  }
  
  void markInvisible(int index) {
    if (_visibleIndices.remove(index)) {
      _updatePreloadRange();
      notifyListeners();
    }
  }
  
  void _updatePreloadRange() {
    if (_visibleIndices.isEmpty) return;
    
    final minVisible = _visibleIndices.reduce((a, b) => a < b ? a : b);
    final maxVisible = _visibleIndices.reduce((a, b) => a > b ? a : b);
    
    // Preload 3 items before and after visible range
    _preloadedIndices.clear();
    for (int i = (minVisible - 3).clamp(0, _totalItems); 
         i <= (maxVisible + 3).clamp(0, _totalItems - 1); 
         i++) {
      _preloadedIndices.add(i);
    }
  }
  
  bool shouldPreload(int index) {
    return _preloadedIndices.contains(index);
  }

  @override
  void dispose() {
    _visibleIndices.clear();
    _preloadedIndices.clear();
    super.dispose();
  }
}

/// Scroll behavior that enables smooth scrolling on all platforms
class SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // No glow effect for smoother appearance
    return child;
  }
}

/// Widget wrapper that prevents unnecessary rebuilds
class StableWidget extends StatefulWidget {
  final Widget child;
  final List<Object?> deps;

  const StableWidget({
    super.key,
    required this.child,
    this.deps = const [],
  });

  @override
  State<StableWidget> createState() => _StableWidgetState();
}

class _StableWidgetState extends State<StableWidget> {
  late Widget _cachedChild;
  late List<Object?> _cachedDeps;

  @override
  void initState() {
    super.initState();
    _cachedChild = widget.child;
    _cachedDeps = List.from(widget.deps);
  }

  @override
  void didUpdateWidget(StableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only rebuild if dependencies changed
    if (!_listEquals(_cachedDeps, widget.deps)) {
      _cachedChild = widget.child;
      _cachedDeps = List.from(widget.deps);
    }
  }

  bool _listEquals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _cachedChild;
  }
}
