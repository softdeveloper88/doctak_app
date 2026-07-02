import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/utils/app/app_environment.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/post_comman_widget.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';

// Add a baseUrl for AI Chat API
String get baseUrl => '${AppData.remoteUrl2}/api';

// Add getHeaders function for AI Chat API
Future<Map<String, String>> getHeaders() async {
  return buildHeaderTokens(contentType: 'application/json');
}

Map<String, String> buildHeaderTokens({
  String? contentType = 'application/x-www-form-urlencoded',
}) {
  Map<String, String> header = {
    HttpHeaders.contentTypeHeader:
        contentType ?? 'application/x-www-form-urlencoded',
    HttpHeaders.acceptHeader: 'application/json',
  };

  final token = AppData.userToken?.trim();
  if (token != null && token.isNotEmpty) {
    header[HttpHeaders.authorizationHeader] = 'Bearer $token';
  }

  return header;
}

Uri buildBaseUrl(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http'))
    url = Uri.parse('${AppData.remoteUrl2}$endPoint');

  log('URL: ${url.toString()}');

  return url;
}

Uri buildBaseUrl3(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http'))
    url = Uri.parse('${AppData.remoteUrl3}$endPoint');

  log('URL: ${url.toString()}');

  return url;
}

Uri buildBaseUrl1(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http'))
    url = Uri.parse('${AppData.remoteUrl}$endPoint');

  log('URL: ${url.toString()}');

  return url;
}

Uri buildBaseUrlV6(String endPoint) {
  Uri url = Uri.parse(endPoint);
  if (!endPoint.startsWith('http'))
    url = Uri.parse('${AppData.remoteUrlV6}$endPoint');

  log('URL (v6): ${url.toString()}');

  return url;
}

Future<Response> buildHttpResponse1(
  String endPoint, {
  HttpMethod method = HttpMethod.GET,
  Map? request,
}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrl1(endPoint);

    print('Header:${headers.toString()}');

    try {
      Response response;

      if (method == HttpMethod.POST) {
        log('Request: $request');
        response = await http
            .post(
              url,
              body: request?.entries
                  .map(
                    (e) =>
                        '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                  )
                  .join('&'),
              headers: headers,
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw 'Timeout - Server not responding after 60 seconds',
            );
      } else if (method == HttpMethod.DELETE) {
        response = await delete(url, headers: headers).timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw 'Timeout - Server not responding after 60 seconds',
        );
      } else if (method == HttpMethod.PUT) {
        var headers = buildHeaderTokens(contentType: 'application/json');

        log('Request: $request');
        response = await put(url, body: jsonEncode(request), headers: headers)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw 'Timeout - Server not responding after 60 seconds',
            );
      } else {
        response = await get(url, headers: headers).timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw 'Timeout - Server not responding after 60 seconds',
        );
      }

      log(
        'Response ($method): ${url.toString()} ${response.statusCode} ${response.body}',
      );

      return response;
    } catch (e) {
      throw 'Something Went Wrong $e';
    }
  } else {
    throw 'Your internet is not working';
  }
}

Future<Response> buildHttpResponse(
  String endPoint, {
  HttpMethod method = HttpMethod.GET,
  Map? request,
}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrl(endPoint);

    print('Header:${headers.toString()}');

    try {
      Response response;

      if (method == HttpMethod.POST) {
        log('Request: $request');
        response = await http
            .post(
              url,
              body: request?.entries
                  .map(
                    (e) =>
                        '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                  )
                  .join('&'),
              headers: headers,
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw 'Timeout - Server not responding after 60 seconds',
            );
      } else if (method == HttpMethod.DELETE) {
        response = await delete(url, headers: headers).timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw 'Timeout - Server not responding after 60 seconds',
        );
      } else if (method == HttpMethod.PUT) {
        var headers = buildHeaderTokens(contentType: 'application/json');

        log('Request: $request');
        response = await put(url, body: jsonEncode(request), headers: headers)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw 'Timeout - Server not responding after 60 seconds',
            );
      } else {
        response = await get(url, headers: headers).timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw 'Timeout - Server not responding after 60 seconds',
        );
      }

      log(
        'Response ($method): ${url.toString()} ${response.statusCode} ${response.body}',
      );

      return response;
    } catch (e) {
      throw 'Something Went Wrong $e';
    }
  } else {
    throw 'Your internet is not working';
  }
}

Future<Response> buildHttpResponse2(
  String endPoint, {
  HttpMethod method = HttpMethod.GET,
  Map? request,
}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrl3(endPoint);

    print('⚠️ URL: ${url.toString()}');
    print('⚠️ Headers: ${headers.toString()}');
    print('⚠️ Method: $method');
    print('⚠️ Request: $request');

    try {
      Response response;

      if (method == HttpMethod.POST) {
        log('Request: $request');
        response = await http
            .post(
              url,
              body: request?.entries
                  .map(
                    (e) =>
                        '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                  )
                  .join('&'),
              headers: headers,
            )
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw 'Timeout - Server not responding after 60 seconds',
            );
      } else if (method == HttpMethod.DELETE) {
        response = await delete(url, headers: headers).timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw 'Timeout - Server not responding after 60 seconds',
        );
      } else if (method == HttpMethod.PUT) {
        var headers = buildHeaderTokens(contentType: 'application/json');

        log('Request: $request');
        response = await put(url, body: jsonEncode(request), headers: headers)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw 'Timeout - Server not responding after 60 seconds',
            );
      } else {
        response = await get(url, headers: headers).timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw 'Timeout - Server not responding after 60 seconds',
        );
      }

      log(
        'Response ($method): ${url.toString()} ${response.statusCode} ${response.body}',
      );

      return response;
    } catch (e) {
      throw 'Something Went Wrong $e';
    }
  } else {
    throw 'Your internet is not working';
  }
}

Future<Response> buildHttpResponseV6(
  String endPoint, {
  HttpMethod method = HttpMethod.GET,
  Map? request,
  bool jsonBody = false,
}) async {
  if (await isNetworkAvailable()) {
    var headers = buildHeaderTokens();
    Uri url = buildBaseUrlV6(endPoint);

    log('🔵 V6 API $method: ${url.toString()}');

    try {
      Response response;

      if (method == HttpMethod.POST) {
        log('Request: $request');
        if (jsonBody) {
          headers = buildHeaderTokens(contentType: 'application/json');
          response = await http
              .post(url, body: jsonEncode(request), headers: headers)
              .timeout(
                const Duration(seconds: 60),
                onTimeout: () =>
                    throw 'Timeout - Server not responding after 60 seconds',
              );
        } else {
          response = await http
              .post(
                url,
                body: request?.entries
                    .map(
                      (e) =>
                          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                    )
                    .join('&'),
                headers: headers,
              )
              .timeout(
                const Duration(seconds: 60),
                onTimeout: () =>
                    throw 'Timeout - Server not responding after 60 seconds',
              );
        }
      } else if (method == HttpMethod.DELETE) {
        response = await delete(url, headers: headers).timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw 'Timeout - Server not responding after 60 seconds',
        );
      } else if (method == HttpMethod.PUT) {
        var headers = buildHeaderTokens(contentType: 'application/json');
        log('Request: $request');
        response = await put(url, body: jsonEncode(request), headers: headers)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw 'Timeout - Server not responding after 60 seconds',
            );
      } else if (method == HttpMethod.PATCH) {
        headers = buildHeaderTokens(contentType: 'application/json');
        log('Request: $request');
        response = await http
            .patch(url, body: jsonEncode(request), headers: headers)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () =>
                  throw 'Timeout - Server not responding after 60 seconds',
            );
      } else {
        response = await get(url, headers: headers).timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw 'Timeout - Server not responding after 60 seconds',
        );
      }

      log(
        'Response (v6 $method): ${url.toString()} ${response.statusCode} ${response.body}',
      );

      return response;
    } catch (e) {
      throw 'Something Went Wrong $e';
    }
  } else {
    throw 'Your internet is not working';
  }
}

/// HTTP helper for doctak-node Next.js API routes.
/// Always sends JSON body and expects JSON responses.
/// [endPoint] should be a path like '/api/meetings/create'.
Future<Response> buildHttpResponseNode(
  String endPoint, {
  HttpMethod method = HttpMethod.GET,
  Map<String, dynamic>? body,
}) async {
  if (await isNetworkAvailable()) {
    final base = AppData.nodeApiUrl.endsWith('/') ? AppData.nodeApiUrl.substring(0, AppData.nodeApiUrl.length - 1) : AppData.nodeApiUrl;
    final path = endPoint.startsWith('/') ? endPoint : '/$endPoint';
    final url = Uri.parse('$base$path');
    final headers = {
      ...buildHeaderTokens(contentType: 'application/json'),
      ...ActingContextService.instance.actingHeaders(),
    };

    log('🟣 Node API [${AppEnvironment.environmentName}] $method: $url');

    try {
      Response response;
      switch (method) {
        case HttpMethod.POST:
          response = await http
              .post(url, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding');
          break;
        case HttpMethod.PUT:
          response = await http
              .put(url, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding');
          break;
        case HttpMethod.PATCH:
          response = await http
              .patch(url, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding');
          break;
        case HttpMethod.DELETE:
          response = await delete(url, headers: headers)
              .timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding');
          break;
        default: // GET
          response = await get(url, headers: headers)
              .timeout(const Duration(seconds: 60), onTimeout: () => throw 'Timeout - Server not responding');
      }
      log('Response (Node $method): $url ${response.statusCode} ${response.body}');
      return response;
    } catch (e) {
      throw 'Something Went Wrong $e';
    }
  } else {
    throw 'Your internet is not working';
  }
}

//region Common

Future handleResponse(Response response, [bool? avoidTokenError]) async {
  if (!await isNetworkAvailable()) {
    throw 'Your internet is not working';
  }

  // Check for HTML response (unauthorized redirect) which usually indicated session expiry disguised as 200 OK
  final bodyLower = response.body.toLowerCase();
  if (bodyLower.contains('<!doctype html') || bodyLower.contains('<html')) {
    throw 'Session expired. Please login again.';
  }

  if (response.statusCode == 401) {
    // NOTE: We do NOT force a logout here. A 401 from an arbitrary endpoint must
    // not bounce the user to login — only an unauthorized HOME FEED response
    // does (handled in HomeBloc). Just surface the error to the caller.
    throw 'Session expired. Please login again.';
  }

  if ((response.statusCode >= 200 && response.statusCode < 300) ||
      response.statusCode == 403) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      // If JSON decoding fails, it might be an unhandled HTML error page or empty response
      if (bodyLower.contains('<!doctype html') || bodyLower.contains('<html')) {
        throw 'Session expired. Please login again.';
      }
      // If content is not HTML but still fails to parse (e.g. empty body or plain text error),
      // treat it as a server error rather than crashing
      throw 'Server returned invalid response (${response.statusCode})';
    }
  } else {
    // Handle specific HTTP status codes
    if (response.statusCode == 429) {
      throw 'Too many requests. Please wait a moment and try again.';
    } else if (response.statusCode == 503) {
      throw 'Service temporarily unavailable. Please try again later.';
    } else if (response.statusCode >= 500) {
      throw 'Server error. Please try again later.';
    }

    try {
      var body = jsonDecode(response.body);
      // Extract error message from various possible response structures
      String errorMessage = _extractErrorMessage(body);
      throw errorMessage;
    } on FormatException {
      // Response body is not valid JSON (like HTML error pages)
      if (response.statusCode == 429) {
        throw 'Too many requests. Please wait a moment and try again.';
      }
      throw 'Server error (${response.statusCode})';
    } catch (e) {
      if (e is String) {
        rethrow; // Re-throw if it's already a formatted string
      }
      log(e);
      throw 'Something went wrong. Please try again.';
    }
  }
}

/// Extracts a user-friendly error message from API response body
String _extractErrorMessage(dynamic body) {
  if (body == null) {
    return 'An unexpected error occurred';
  }

  // Try different common API error response formats
  String? message;

  // Format 1: { "message": "Error text" }
  if (body is Map && body['message'] != null) {
    message = body['message'].toString();
  }
  // Format 2: { "error": "Error text" }
  else if (body is Map && body['error'] != null) {
    if (body['error'] is String) {
      message = body['error'];
    } else if (body['error'] is Map && body['error']['message'] != null) {
      message = body['error']['message'].toString();
    }
  }
  // Format 3: { "errors": { "field": ["Error 1", "Error 2"] } }
  else if (body is Map && body['errors'] != null) {
    if (body['errors'] is Map) {
      // Get first error message from validation errors
      var errors = body['errors'] as Map;
      for (var key in errors.keys) {
        var fieldErrors = errors[key];
        if (fieldErrors is List && fieldErrors.isNotEmpty) {
          message = fieldErrors.first.toString();
          break;
        } else if (fieldErrors is String) {
          message = fieldErrors;
          break;
        }
      }
    } else if (body['errors'] is List) {
      var errorsList = body['errors'] as List;
      if (errorsList.isNotEmpty) {
        message = errorsList.first.toString();
      }
    }
  }
  // Format 4: { "msg": "Error text" }
  else if (body is Map && body['msg'] != null) {
    message = body['msg'].toString();
  }
  // Format 5: Body is just a string
  else if (body is String) {
    message = body;
  }

  // Clean up HTML if present and return
  if (message != null && message.isNotEmpty) {
    return parseHtmlString(message);
  }

  return 'An unexpected error occurred';
}

enum HttpMethod { GET, POST, DELETE, PUT, PATCH }

class TokenException implements Exception {
  final String message;

  const TokenException([this.message = ""]);

  @override
  String toString() => "FormatException: $message";
}
