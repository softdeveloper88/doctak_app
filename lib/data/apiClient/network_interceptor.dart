// ignore_for_file: unnecessary_overrides

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// NetworkInterceptor class for intercepting API requests, responses, and exceptions.
///
/// This class extends the [Interceptor] class from the Dio HTTP client library
/// and overrides the [onRequest], [onError] and [onResponse] methods to intercept
/// different stages of the API request lifecycle.
///
/// Enhanced with detailed logging and diagnostics for troubleshooting network issues.
class NetworkInterceptor extends Interceptor {
  // Track response times for performance monitoring
  final Map<String, DateTime> _requestStartTimes = {};

  // Configure debug logging
  final bool enableDetailedLogging;

  // Configure max content log length
  final int maxLogContentLength;

  NetworkInterceptor({this.enableDetailedLogging = true, this.maxLogContentLength = 1000});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Start timing the request
    _requestStartTimes[options.uri.toString()] = DateTime.now();

    // Enhanced logging for request
    if (enableDetailedLogging) {
      debugPrint('┌────── 📡 API REQUEST ──────');
      debugPrint('│ URL: ${options.uri}');
      debugPrint('│ METHOD: ${options.method}');

      // Log headers (excluding sensitive information)
      final Map<String, dynamic> safeHeaders = Map.from(options.headers);
      // Redact auth tokens for security
      if (safeHeaders.containsKey('Authorization')) {
        final auth = safeHeaders['Authorization'] as String;
        if (auth.length > 15) {
          safeHeaders['Authorization'] = '${auth.substring(0, 15)}...';
        }
      }
      debugPrint('│ HEADERS: $safeHeaders');

      // Log query parameters
      if (options.queryParameters.isNotEmpty) {
        debugPrint('│ QUERY PARAMS: ${options.queryParameters}');
      }

      // Log request data (with length limits)
      if (options.data != null) {
        var dataStr = options.data.toString();
        if (dataStr.length > maxLogContentLength) {
          dataStr = '${dataStr.substring(0, maxLogContentLength)}...';
        }
        debugPrint('│ DATA: $dataStr');
      }

      debugPrint('└──────────────────────────');
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Calculate response time
    final requestTime = _calculateRequestTime(err.requestOptions.uri.toString());

    // Enhanced error logging
    debugPrint('┌────── ❌ API ERROR (${err.type}) ──────');
    debugPrint('│ URL: ${err.requestOptions.uri}');
    debugPrint('│ METHOD: ${err.requestOptions.method}');
    debugPrint('│ REQUEST TIME: ${requestTime}ms');

    // Log specific error information based on error type
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        debugPrint('│ ⏱️ TIMEOUT: Connection timeout (${err.requestOptions.connectTimeout}ms)');
        debugPrint('│ 📊 CONTEXT: This error occurs when Dio cannot establish a connection within the specified timeout');
        debugPrint('│ 🔍 SOLUTION: Check network connectivity, server load, or increase connectTimeout');
        break;
      case DioExceptionType.sendTimeout:
        debugPrint('│ ⏱️ TIMEOUT: Send timeout (${err.requestOptions.sendTimeout}ms)');
        debugPrint('│ 📊 CONTEXT: This error occurs when Dio cannot send data to the server within the specified timeout');
        debugPrint('│ 🔍 SOLUTION: Check for large request payload, server load, or increase sendTimeout');
        break;
      case DioExceptionType.receiveTimeout:
        debugPrint('│ ⏱️ TIMEOUT: Receive timeout (${err.requestOptions.receiveTimeout}ms)');
        debugPrint('│ 📊 CONTEXT: This error occurs when Dio doesn\'t receive a response within the specified timeout');
        debugPrint('│ 🔍 SOLUTION: The server might be overloaded or processing a complex query. Consider increasing receiveTimeout');
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        debugPrint('│ 🔥 STATUS CODE: $statusCode');

        // Add more context by status code
        if (statusCode == 500) {
          debugPrint('│ 📊 CONTEXT: Server error (500) - The server encountered an unexpected condition');
          debugPrint('│ 🔍 SOLUTION: Check server logs, this is a problem on the server side');
        } else if (statusCode == 502) {
          debugPrint('│ 📊 CONTEXT: Bad Gateway (502) - The server received an invalid response from upstream');
          debugPrint('│ 🔍 SOLUTION: Check if backend services/databases are running correctly');
        } else if (statusCode == 503) {
          debugPrint('│ 📊 CONTEXT: Service Unavailable (503) - The server is temporarily unable to handle the request');
          debugPrint('│ 🔍 SOLUTION: Server might be down for maintenance or overloaded');
        } else if (statusCode == 504) {
          debugPrint('│ 📊 CONTEXT: Gateway Timeout (504) - The server didn\'t receive a timely response from upstream');
          debugPrint('│ 🔍 SOLUTION: Check if backend services are responding slowly');
        } else if (statusCode == 401) {
          debugPrint('│ 📊 CONTEXT: Unauthorized (401) - Authentication is required and has failed');
          debugPrint('│ 🔍 SOLUTION: Check user authentication token or credentials');
        } else if (statusCode == 403) {
          debugPrint('│ 📊 CONTEXT: Forbidden (403) - Server understood but refuses to authorize the request');
          debugPrint('│ 🔍 SOLUTION: Check user permissions for this resource');
        } else if (statusCode == 404) {
          debugPrint('│ 📊 CONTEXT: Not Found (404) - The requested resource could not be found');
          debugPrint('│ 🔍 SOLUTION: Verify the endpoint URL is correct');
        }

        _logResponseData(err.response);
        break;
      case DioExceptionType.cancel:
        debugPrint('│ ❌ CANCELLED: Request was cancelled');
        debugPrint('│ 📊 CONTEXT: The request was manually cancelled via CancelToken');
        break;
      case DioExceptionType.connectionError:
        debugPrint('│ 🌐 CONNECTION ERROR: ${err.error}');
        // Check for specific connection issues
        if (err.error is SocketException) {
          final socketErr = err.error as SocketException;
          debugPrint('│ 🔌 SOCKET ERROR: ${socketErr.message}');
          debugPrint('│ 📊 ADDRESS: ${socketErr.address}');
          debugPrint('│ 🔢 PORT: ${socketErr.port}');
          debugPrint('│ 🔍 SOLUTION: Check network connectivity, VPN settings, or firewall rules');
        }
        debugPrint('│ 📊 CONTEXT: Failed to connect to the server, often due to network issues');
        debugPrint('│ 🔍 SOLUTION: Check internet connection, server availability, or DNS settings');
        break;
      case DioExceptionType.badCertificate:
        debugPrint('│ 🔒 BAD CERTIFICATE: Certificate verification failed');
        debugPrint('│ 📊 CONTEXT: The server\'s SSL certificate could not be verified');
        debugPrint('│ 🔍 SOLUTION: Check certificate validity or consider using a custom HttpClient');
        break;
      default:
        debugPrint('│ ⚠️ ERROR: ${err.error}');
        debugPrint('│ 📊 CONTEXT: An unknown error occurred with Dio request');
        break;
    }

    // Log the stack trace for debugging
    debugPrint('│ STACK TRACE: ${err.stackTrace.toString().split('\n').first}');

    debugPrint('└──────────────────────────');

    // Continue with error handling
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Calculate response time
    final requestTime = _calculateRequestTime(response.requestOptions.uri.toString());

    // Enhanced logging for successful responses
    if (enableDetailedLogging) {
      debugPrint('┌────── ✅ API RESPONSE (${response.statusCode}) ──────');
      debugPrint('│ URL: ${response.requestOptions.uri}');
      debugPrint('│ METHOD: ${response.requestOptions.method}');
      debugPrint('│ REQUEST TIME: ${requestTime}ms');

      // Log headers
      if (response.headers.map.isNotEmpty) {
        debugPrint('│ HEADERS: ${response.headers.map}');
      }

      // Log response data
      _logResponseData(response);

      debugPrint('└──────────────────────────');
    }

    super.onResponse(response, handler);
  }

  /// Calculate request time in milliseconds
  int _calculateRequestTime(String uri) {
    final startTime = _requestStartTimes[uri];
    if (startTime != null) {
      _requestStartTimes.remove(uri);
      return DateTime.now().difference(startTime).inMilliseconds;
    }
    return -1;
  }

  /// Log response data with proper formatting and truncation
  void _logResponseData(Response? response) {
    if (response?.data != null) {
      var dataStr = response!.data.toString();

      // Check if it's too large to log
      if (dataStr.length > maxLogContentLength) {
        // Truncate and indicate truncation
        dataStr = '${dataStr.substring(0, maxLogContentLength)}... [${dataStr.length - maxLogContentLength} more bytes]';
      }

      // Special handling for JSON objects to improve readability
      if (response.data is Map || response.data is List) {
        // For large JSON, just log the structure/keys
        if (dataStr.length > maxLogContentLength / 2) {
          try {
            if (response.data is Map) {
              final keys = (response.data as Map).keys.toList();
              debugPrint('│ DATA: Map with keys $keys (truncated)');
            } else if (response.data is List) {
              final list = response.data as List;
              debugPrint('│ DATA: List with ${list.length} items (truncated)');
            }
          } catch (e) {
            debugPrint('│ DATA: [Error processing data structure: $e]');
          }
        } else {
          debugPrint('│ DATA: $dataStr');
        }
      } else {
        debugPrint('│ DATA: $dataStr');
      }
    } else {
      debugPrint('│ DATA: null');
    }
  }
}
