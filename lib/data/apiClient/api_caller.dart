import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

enum HttpMethod { get, post, put, delete }

class ApiCaller {

  Future<dynamic> callApi({
    required String endpoint,
    required HttpMethod method,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    // Construct URL
    Uri fullUri = Uri.parse('${AppData.remoteUrl2}/').resolve(endpoint);
 print(fullUri);
    // Add query parameters
    if (params != null && params.isNotEmpty) {
      final queryParams = Map<String, String>.from(fullUri.queryParameters);
      queryParams.addAll(params.map((k, v) => MapEntry(k, v.toString())));
      fullUri = fullUri.replace(queryParameters: queryParams);
    }
      print(fullUri);
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

    // Execute request
    final client = http.Client();
    try {
      final response = await _executeRequest(
        method: method,
        uri: fullUri,
        headers: requestHeaders,
        body: bodyJson,
        client: client,
      );

      return _handleResponse(response);
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
  }) async {
    switch (method) {
      case HttpMethod.get:
        return await client.get(uri, headers: headers);
      case HttpMethod.post:
        return await client.post(uri, headers: headers, body: body);
      case HttpMethod.put:
        return await client.put(uri, headers: headers, body: body);
      case HttpMethod.delete:
        return await client.delete(uri, headers: headers);
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
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Request failed',
        response: errorBody,
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic response;

  ApiException({
    required this.statusCode,
    required this.message,
    this.response,
  });

  @override
  String toString() => 'ApiException: $statusCode - $message\nResponse: $response';
}