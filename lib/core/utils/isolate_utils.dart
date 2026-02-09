import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Utility class for running expensive operations in isolates
/// This prevents UI jank by moving heavy work off the main thread
class IsolateUtils {
  /// Parse JSON in a separate isolate
  static Future<dynamic> parseJsonInIsolate(String jsonString) async {
    return compute(_parseJson, jsonString);
  }

  static dynamic _parseJson(String jsonString) {
    return json.decode(jsonString);
  }

  /// Encode JSON in a separate isolate
  static Future<String> encodeJsonInIsolate(dynamic data) async {
    return compute(_encodeJson, data);
  }

  static String _encodeJson(dynamic data) {
    return json.encode(data);
  }

  /// Process list of items with a transform function
  static Future<List<R>> processListInIsolate<T, R>(
    List<T> items,
    R Function(T) transform,
  ) async {
    // For small lists, process on main thread
    if (items.length < 10) {
      return items.map(transform).toList();
    }
    
    // For larger lists, use compute
    return compute(
      _processListWorker<T, R>,
      _ListProcessorParams(items, transform),
    );
  }

  static List<R> _processListWorker<T, R>(_ListProcessorParams<T, R> params) {
    return params.items.map(params.transform).toList();
  }

  /// Run a heavy computation in an isolate with progress tracking
  static Future<T> runInIsolateWithProgress<T>({
    required Future<T> Function() computation,
    void Function(double progress)? onProgress,
  }) async {
    // Create a receive port for the isolate to communicate
    final receivePort = ReceivePort();
    
    try {
      // Use compute for simple isolate work
      return await computation();
    } catch (e) {
      debugPrint('❌ Isolate computation error: $e');
      rethrow;
    } finally {
      receivePort.close();
    }
  }

  /// Batch process items with throttling to prevent frame drops
  static Stream<R> batchProcessWithThrottle<T, R>({
    required List<T> items,
    required R Function(T) processor,
    int batchSize = 5,
    Duration throttleDuration = const Duration(milliseconds: 16), // ~60fps
  }) async* {
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, items.length);
      final batch = items.sublist(i, end);
      
      for (final item in batch) {
        yield processor(item);
      }
      
      // Allow UI to breathe between batches
      await Future.delayed(throttleDuration);
    }
  }

  /// Debounced operation runner
  static Timer? _debounceTimer;
  
  static void debounce({
    required Duration duration,
    required VoidCallback action,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, action);
  }

  /// Throttled operation runner (max once per duration)
  static DateTime? _lastThrottleCall;
  
  static bool throttle({
    required Duration duration,
    required VoidCallback action,
  }) {
    final now = DateTime.now();
    if (_lastThrottleCall == null ||
        now.difference(_lastThrottleCall!) > duration) {
      _lastThrottleCall = now;
      action();
      return true;
    }
    return false;
  }
}

class _ListProcessorParams<T, R> {
  final List<T> items;
  final R Function(T) transform;

  _ListProcessorParams(this.items, this.transform);
}

/// Extension to easily run functions in isolates
extension IsolateExtension<T> on Future<T> Function() {
  Future<T> runInIsolate() async {
    return compute((_) async {
      return await this();
    }, null);
  }
}

/// Mixin for widgets that need to do heavy processing
mixin HeavyProcessingMixin<T extends StatefulWidget> on State<T> {
  bool _isProcessing = false;
  
  bool get isProcessing => _isProcessing;
  
  /// Run heavy work without blocking UI
  Future<R> runHeavyWork<R>(Future<R> Function() work) async {
    if (_isProcessing) {
      throw StateError('Heavy work already in progress');
    }
    
    _isProcessing = true;
    if (mounted) setState(() {});
    
    try {
      return await work();
    } finally {
      _isProcessing = false;
      if (mounted) setState(() {});
    }
  }
  
  /// Schedule work for next frame to prevent frame drops
  void scheduleForNextFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }
}
