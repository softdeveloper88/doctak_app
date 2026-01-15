import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum HttpMethod { get, post, put, delete }

class ApiCaller {
  // Default timeout of 20 seconds for all requests
  static const Duration defaultTimeout = Duration(seconds: 20);

  Future<dynamic> callApi({required String endpoint, required HttpMethod method, Map<String, dynamic>? params, Map<String, String>? headers, dynamic body, Duration timeout = defaultTimeout}) async {
    // Construct URL
    Uri fullUri = Uri.parse('${AppData.remoteUrl2}/').resolve(endpoint);

    // Add query parameters
    if (params != null && params.isNotEmpty) {
      final queryParams = Map<String, String>.from(fullUri.queryParameters);
      queryParams.addAll(params.map((k, v) => MapEntry(k, v.toString())));
      fullUri = fullUri.replace(queryParameters: queryParams);
    }

    debugPrint('📡 API Request: ${method.toString().split('.').last.toUpperCase()} $fullUri');

    // Prepare headers
    final requestHeaders = Map<String, String>.from({'Authorization': 'Bearer ${AppData.userToken}'});
    if (headers != null) requestHeaders.addAll(headers);

    // Prepare body
    String? bodyJson;
    if (body != null) {
      if (body is Map || body is List) {
        bodyJson = jsonEncode(body);
        if (!requestHeaders.containsKey('Content-Type')) {
          requestHeaders['Content-Type'] = 'application/json';
        }
      } else if (body is String) {
        bodyJson = body;
      } else {
        throw ArgumentError('Unsupported body type. Use Map, List, or String.');
      }
    }

    // Execute request with timeout
    final client = http.Client();
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final response = await _executeRequest(method: method, uri: fullUri, headers: requestHeaders, body: bodyJson, client: client, timeout: timeout);

      stopwatch.stop();
      debugPrint('✅ API Response: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');

      return _handleResponse(response);
    } on TimeoutException catch (e) {
      stopwatch.stop();
      debugPrint('⏱️ API Timeout: $fullUri (${stopwatch.elapsedMilliseconds}ms)');
      throw ApiException(
        statusCode: 408, // Request Timeout
        message: 'Request timed out after ${timeout.inSeconds} seconds',
        response: {'error': 'timeout', 'details': e.toString()},
        isTimeout: true,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      debugPrint('🌐 Network Error: ${e.message} (${stopwatch.elapsedMilliseconds}ms)');
      throw ApiException(statusCode: 0, message: 'Network connection error', response: {'error': 'network', 'details': e.toString()}, isNetworkError: true);
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ API Error: $e (${stopwatch.elapsedMilliseconds}ms)');

      if (e is ApiException) {
        rethrow;
      }

      throw ApiException(statusCode: 0, message: 'Unknown error occurred', response: {'error': 'unknown', 'details': e.toString()});
    } finally {
      client.close();
    }
  }

  Future<http.Response> _executeRequest({
    required HttpMethod method,
    required Uri uri,
    required Map<String, String> headers,
    required String? body,
    required http.Client client,
    required Duration timeout,
  }) async {
    // Apply timeout to all requests
    switch (method) {
      case HttpMethod.get:
        return await client.get(uri, headers: headers).timeout(timeout);
      case HttpMethod.post:
        return await client.post(uri, headers: headers, body: body).timeout(timeout);
      case HttpMethod.put:
        return await client.put(uri, headers: headers, body: body).timeout(timeout);
      case HttpMethod.delete:
        return await client.delete(uri, headers: headers).timeout(timeout);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if ((response.statusCode >= 200 && response.statusCode < 300) || response.statusCode == 403) {
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    } else {
      dynamic errorBody;
      try {
        errorBody = jsonDecode(response.body);
      } catch (_) {
        errorBody = response.body;
      }
      throw ApiException(statusCode: response.statusCode, message: 'Request failed with status code ${response.statusCode}', response: errorBody);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic response;
  final bool isTimeout;
  final bool isNetworkError;

  ApiException({required this.statusCode, required this.message, this.response, this.isTimeout = false, this.isNetworkError = false});

  bool get isServerError => statusCode >= 500 && statusCode < 600;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isConnectionError => isTimeout || isNetworkError;

  @override
  String toString() => 'ApiException: $statusCode - $message\nResponse: $response';
}
