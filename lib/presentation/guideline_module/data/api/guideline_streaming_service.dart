import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

/// SSE streaming service for the Guideline Agent chat.
///
/// Modelled on the existing [StreamingMessageService] in the AI chat module
/// but adapted for the guideline API endpoint and response format.
class GuidelineStreamingService {
  final _chunkController = BehaviorSubject<String>();

  /// Stream of text deltas — listen for real-time typewriter effect.
  Stream<String> get chunkStream => _chunkController.stream;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  String _completeMessage = '';
  String get completeMessage => _completeMessage;

  /// Metadata sent in the final SSE event (sources, suggestions, session_id).
  Map<String, dynamic>? _metadata;
  Map<String, dynamic>? get metadata => _metadata;

  http.Client? _httpClient;

  final Duration _timeout = const Duration(seconds: 90);

  /// Start streaming a guideline message.
  Future<void> streamMessage({
    required String query,
    required String sessionId,
    required List<String> sources,
  }) async {
    if (_isStreaming) {
      throw Exception('Already streaming. Cancel the current stream first.');
    }

    _isStreaming = true;
    _completeMessage = '';
    _metadata = null;

    try {
      _httpClient = http.Client();

      final url =
          Uri.parse('${AppData.remoteUrlV6}/guidelines/send-message/stream');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      };
      if (AppData.userToken != null && AppData.userToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${AppData.userToken}';
      }

      final body = jsonEncode({
        'query': query,
        'session_id': sessionId,
        'sources': sources,
      });

      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;

      final response = await _httpClient!.send(request).timeout(_timeout);

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        _finish(error: 'HTTP ${response.statusCode}: $responseBody');
        return;
      }

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (String line) {
          if (line.trim().isEmpty) return;

          if (line.startsWith('data: ')) {
            final data = line.substring(6);

            if (data == '[DONE]') {
              _finish();
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;

              // Error event
              if (json.containsKey('error')) {
                _finish(error: json['error'] as String);
                return;
              }

              // Text delta chunk
              if (json.containsKey('delta') &&
                  json['delta'] is Map &&
                  (json['delta'] as Map).containsKey('content')) {
                final content = json['delta']['content'] as String;
                _completeMessage += content;
                _chunkController.add(content);
              }

              // Final metadata event (sources, suggestions)
              if (json.containsKey('done') && json['done'] == true) {
                _metadata = json;
              }
            } catch (_) {
              // Ignore unparseable lines
            }
          }
        },
        onDone: () => _finish(),
        onError: (error) => _finish(error: error.toString()),
        cancelOnError: true,
      );
    } catch (e) {
      _finish(error: e.toString());
    }
  }

  /// Cancel the in-flight streaming request.
  void cancelStream() {
    _httpClient?.close();
    _httpClient = null;
    if (_isStreaming) {
      _finish(cancelled: true);
    }
  }

  void _finish({String? error, bool cancelled = false}) {
    if (!_isStreaming) return; // Guard against double-finish
    _isStreaming = false;
    _httpClient?.close();
    _httpClient = null;

    if (error != null) {
      _chunkController.add('__ERROR__:$error');
    } else if (cancelled) {
      _chunkController.add('__CANCELLED__');
    } else {
      _chunkController.add('__DONE__');
    }
  }

  void dispose() {
    cancelStream();
    _chunkController.close();
  }
}
