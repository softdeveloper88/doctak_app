import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/core/utils/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Keeps the auth token in sync with secure storage and refreshes it before expiry.
class AuthTokenService {
  AuthTokenService._();
  static final AuthTokenService instance = AuthTokenService._();

  bool _refreshing = false;
  Completer<bool>? _refreshCompleter;

  /// Load token from secure storage into [AppData] when memory is empty.
  Future<void> ensureTokenLoaded() async {
    final cached = AppData.userToken?.trim();
    if (cached != null && cached.isNotEmpty) return;

    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      final stored = (await prefs.getString('token'))?.trim();
      if (stored != null && stored.isNotEmpty) {
        AppData.userToken = stored;
      }
    } catch (e) {
      debugPrint('AuthTokenService.ensureTokenLoaded error: $e');
    }
  }

  Future<String?> getToken() async {
    await ensureTokenLoaded();
    final token = AppData.userToken?.trim();
    return (token != null && token.isNotEmpty) ? token : null;
  }

  Future<Map<String, String>> authHeaders({
    String contentType = 'application/json',
    bool includeContentType = true,
  }) async {
    final token = await getToken();
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (includeContentType && contentType.isNotEmpty) {
      headers[HttpHeaders.contentTypeHeader] = contentType;
    }
    if (token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> _persistNewToken(String token, {int? expiresAt}) async {
    AppData.userToken = token;
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      await prefs.setString('token', token);
      if (expiresAt != null && expiresAt > 0) {
        await prefs.setString('token_expires_at', '$expiresAt');
      }
    } catch (e) {
      debugPrint('AuthTokenService._persistNewToken error: $e');
    }
  }

  /// Exchange the current JWT for a new one. Safe to call concurrently.
  Future<bool> refreshToken() async {
    if (_refreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _refreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      await ensureTokenLoaded();
      final token = AppData.userToken?.trim();
      if (token == null || token.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final base = AppData.remoteUrl2.endsWith('/')
          ? AppData.remoteUrl2.substring(0, AppData.remoteUrl2.length - 1)
          : AppData.remoteUrl2;
      final response = await http
          .post(
            Uri.parse('$base/refresh-token'),
            headers: {
              HttpHeaders.authorizationHeader: 'Bearer $token',
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map) {
          final newToken = (body['token'] ?? '').toString();
          if (newToken.isNotEmpty) {
            final expiresAt = int.tryParse('${body['expires_at'] ?? ''}');
            await _persistNewToken(newToken, expiresAt: expiresAt);
            debugPrint('AuthTokenService: token refreshed');
            _refreshCompleter!.complete(true);
            return true;
          }
        }
      }

      debugPrint(
        'AuthTokenService.refreshToken failed: ${response.statusCode} ${response.body}',
      );
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      debugPrint('AuthTokenService.refreshToken error: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Proactively refresh when the stored expiry is within [threshold].
  Future<void> refreshIfExpiringSoon({
    Duration threshold = const Duration(days: 3),
  }) async {
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      final expiresRaw = await prefs.getString('token_expires_at');
      final expiresAt = int.tryParse(expiresRaw ?? '');
      if (expiresAt == null || expiresAt <= 0) return;

      final expiresMs = expiresAt * 1000;
      if (DateTime.now().add(threshold).millisecondsSinceEpoch >= expiresMs) {
        await refreshToken();
      }
    } catch (e) {
      debugPrint('AuthTokenService.refreshIfExpiringSoon error: $e');
    }
  }

  Future<http.Response> get(
    Uri url, {
    Duration timeout = const Duration(seconds: 15),
    String contentType = 'application/json',
  }) {
    return _authorizedRequest(
      (headers) => http.get(url, headers: headers).timeout(timeout),
      contentType: contentType,
      url: url,
    );
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? body,
    Duration timeout = const Duration(seconds: 15),
    String contentType = 'application/x-www-form-urlencoded',
  }) {
    return _authorizedRequest(
      (headers) => http.post(url, headers: headers, body: body).timeout(timeout),
      contentType: contentType,
      url: url,
    );
  }

  Future<http.Response> delete(
    Uri url, {
    Duration timeout = const Duration(seconds: 15),
    String contentType = 'application/json',
  }) {
    return _authorizedRequest(
      (headers) => http.delete(url, headers: headers).timeout(timeout),
      contentType: contentType,
      url: url,
    );
  }

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) send, {
    required String contentType,
    Uri? url,
  }) async {
    await ensureTokenLoaded();
    var headers = await authHeaders(contentType: contentType);
    var response = await send(headers);

    if (response.statusCode != 401) return response;

    final token = await getToken();
    if (token == null || token.isEmpty) {
      return response;
    }

    if (url != null && _isPublicAuthPath(url)) {
      return response;
    }

    final refreshed = await refreshToken();
    if (refreshed) {
      headers = await authHeaders(contentType: contentType);
      response = await send(headers);
      if (response.statusCode != 401) return response;
    }

    await SessionManager.handleUnauthorized(reason: 'api-401');
    return response;
  }

  bool _isPublicAuthPath(Uri url) {
    final path = url.path.toLowerCase();
    return path.endsWith('/login') ||
        path.endsWith('/register') ||
        path.endsWith('/refresh-token') ||
        path.contains('/social-login') ||
        path.contains('/forgot-password');
  }
}
