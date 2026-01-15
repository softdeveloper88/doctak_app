import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:rxdart/rxdart.dart';

/// A service for handling streaming AI message responses
class StreamingMessageService {
  // Stream controller for the message chunks
  final _messageStreamController = BehaviorSubject<String>();

  // Public stream that can be listened to
  Stream<String> get messageStream => _messageStreamController.stream;

  // Track if we're currently streaming
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  // Track total message content for final delivery
  String _completeMessage = '';
  String get completeMessage => _completeMessage;

  // Timeout settings
  final Duration _timeout = const Duration(seconds: 45);

  // Keep track of the HTTP client to enable cancellation
  http.Client? _httpClient;

  // Constructor - initialize any dependencies here
  StreamingMessageService();

  /// Stream a message from the AI service
  /// Returns a stream of message chunks that can be listened to for real-time updates
  Future<void> streamMessage({
    required String sessionId,
    required String message,
    required String model,
    double temperature = 0.7,
    int maxTokens = 1024,
    bool webSearch = false,
    String? searchContextSize,
    File? file,
  }) async {
    if (_isStreaming) {
      throw Exception('Already streaming a message. Cancel the current stream first.');
    }

    // Reset state
    _isStreaming = true;
    _completeMessage = '';

    try {
      // Create a new HTTP client for this streaming request
      _httpClient = http.Client();

      // Prepare the request URL and headers
      final url = Uri.parse('${AppData.remoteUrl3}/chat/messages/stream');

      final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'text/event-stream'};

      if (AppData.userToken != null) {
        headers['Authorization'] = 'Bearer ${AppData.userToken}';
      }

      // Prepare the request body
      final Map<String, dynamic> body = {
        'session_id': sessionId,
        'message': message,
        'model': model,
        'temperature': temperature.toString(),
        'max_tokens': maxTokens.toString(),
        'web_search': webSearch ? '1' : '0',
      };

      // Include optional web search parameters if needed
      if (webSearch && searchContextSize != null) {
        body['search_context_size'] = searchContextSize;
      }

      // Send the request - we can't use file uploads in the streaming implementation yet
      // For file uploads, we'll fall back to the regular API method
      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = json.encode(body);

      // Send the request and get the response stream
      final response = await _httpClient!.send(request).timeout(_timeout);

      if (response.statusCode != 200) {
        // Handle non-200 responses
        final responseBody = await response.stream.bytesToString();
        throw Exception('Error streaming message: ${response.statusCode} - $responseBody');
      }

      // Process the streaming response
      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (String line) {
              // Skip empty lines
              if (line.trim().isEmpty) return;

              // Server-sent events format: lines starting with "data: "
              if (line.startsWith('data: ')) {
                final data = line.substring(6);

                // Check for the end of the stream marker
                if (data == '[DONE]') {
                  _completeMessageProcessing();
                  return;
                }

                try {
                  // Parse the JSON data
                  final jsonData = json.decode(data);

                  // Extract the content chunk
                  if (jsonData.containsKey('choices') && jsonData['choices'].isNotEmpty && jsonData['choices'][0].containsKey('delta') && jsonData['choices'][0]['delta'].containsKey('content')) {
                    final content = jsonData['choices'][0]['delta']['content'] as String;

                    // Add to the complete message
                    _completeMessage += content;

                    // Add to the stream
                    _messageStreamController.add(content);
                  }
                } catch (e) {
                  print('Error processing streaming chunk: $e');
                }
              }
            },
            onDone: () {
              _completeMessageProcessing();
            },
            onError: (error) {
              print('Stream error: $error');
              _completeMessageProcessing(error: error.toString());
            },
            cancelOnError: true,
          );
    } catch (e) {
      _completeMessageProcessing(error: e.toString());
      rethrow;
    }
  }

  /// Cancel the current streaming request
  void cancelStream() {
    _httpClient?.close();
    _httpClient = null;

    if (_isStreaming) {
      _completeMessageProcessing(cancelled: true);
    }
  }

  /// Clean up the streaming state and mark as complete
  void _completeMessageProcessing({String? error, bool cancelled = false}) {
    _isStreaming = false;
    _httpClient?.close();
    _httpClient = null;

    // Add a special marker to indicate completion with status
    if (error != null) {
      _messageStreamController.add('__ERROR__:$error');
    } else if (cancelled) {
      _messageStreamController.add('__CANCELLED__');
    } else {
      _messageStreamController.add('__DONE__');
    }
  }

  /// Close and clean up resources - call this when done with the service
  void dispose() {
    cancelStream();
    _messageStreamController.close();
  }
}
