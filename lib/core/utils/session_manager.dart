import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/notification_counter_service.dart';
import 'package:doctak_app/core/notification_service.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Result of validating a stored session against the server.
enum SessionCheck {
  /// Server accepted the token — the session is usable.
  valid,

  /// Server rejected the token (401) — the session was cleared.
  invalid,

  /// Couldn't determine (no network / server error). Caller should proceed and
  /// let the in-app 401 handler catch it later.
  unknown,
}

/// Centralised session / authentication gatekeeper.
///
/// Solves the iOS problem where data written by `flutter_secure_storage` lives
/// in the **Keychain**, which is NOT removed when the app is uninstalled. So a
/// user who deletes the app (or installs a fresh TestFlight build) still has the
/// old `token` / `rememberMe` flags, and the splash screen would auto-navigate
/// them to home instead of login.
///
/// Rather than blindly wiping that storage on a fresh install — which would log
/// out every existing user the first time they install an app *update* — we
/// **validate the stored token with the server exactly once per install**
/// ([verifyStoredSessionOncePerInstall]):
///   * token still valid  -> the session is kept (a normal update never logs the
///                           user out);
///   * token rejected (401)-> the session is cleared and the user lands on login;
///   * no network / error -> the session is kept and the runtime 401 handler
///                           ([handleUnauthorized]) catches it on the first real
///                           request.
///
/// [handleUnauthorized] / [forceLogoutToLogin] also clear the session and route
/// to login whenever any authenticated request comes back 401 (e.g. the feed),
/// for *any* reason the session expires while the app is running.
class SessionManager {
  SessionManager._();

  /// SharedPreferences key (NSUserDefaults is wiped on uninstall, unlike the
  /// Keychain) that records the stored session has been validated for this
  /// installation. Bump the suffix to force a re-validation for everyone.
  static const String _sessionCheckedKey = 'dt_session_checked_v1';

  /// Auth-related keys that constitute a "session". Removing these is enough to
  /// force the splash screen to route to login on the next cold start.
  static const List<String> _sessionKeys = [
    'rememberMe',
    'token',
    'token_expires_at',
    'device_token',
    'userId',
    'name',
    'profile_pic',
    'background',
    'email',
    'phone',
    'specialty',
    'is_verified',
    'email_verified_at',
    'licenseNo',
    'title',
    'city',
    'countryOrigin',
    'college',
    'clinicName',
    'dob',
    'practicingCountry',
    'gender',
    'country',
    'countryName',
    'currency',
    'university',
    'user_type',
    'is_premium',
    'account_type',
    'plan_name',
    'plan_slug',
    'subscription_json',
    'features_json',
  ];

  /// Re-entrancy guard so multiple in-flight requests failing with 401 at the
  /// same time don't each push a login screen.
  static bool _isHandlingLogout = false;

  /// Validates the stored [token] against the server **once per install** so a
  /// stale Keychain session left over from a previous install (iOS keeps the
  /// Keychain across uninstalls) doesn't auto-log the user into home.
  ///
  /// Must be awaited by the splash screen before it decides home-vs-login.
  /// A normal app update keeps a valid token, so this never logs the user out.
  static Future<SessionCheck> verifyStoredSessionOncePerInstall({
    required String token,
    String? userId,
  }) async {
    if (token.trim().isEmpty) return SessionCheck.invalid;

    try {
      final sp = await SharedPreferences.getInstance();
      final alreadyChecked = sp.getBool(_sessionCheckedKey) ?? false;

      // Already validated on this install — trust local storage (fast path for
      // every normal launch, including after an update).
      if (alreadyChecked) return SessionCheck.valid;

      final result = await _validateTokenWithServer(token: token, userId: userId);

      switch (result) {
        case SessionCheck.valid:
          await sp.setBool(_sessionCheckedKey, true);
          return SessionCheck.valid;
        case SessionCheck.invalid:
          // Stale / revoked token (e.g. reinstall after uninstall, or logged out
          // elsewhere) — wipe it so the splash routes to login.
          await _clearStoredSession();
          await sp.setBool(_sessionCheckedKey, true);
          return SessionCheck.invalid;
        case SessionCheck.unknown:
          // Couldn't reach the server — don't penalise the user. Leave the flag
          // unset so we re-validate next launch; the 401 handler is the safety
          // net if the token really is dead.
          return SessionCheck.unknown;
      }
    } catch (e) {
      debugPrint('SessionManager.verifyStoredSessionOncePerInstall error: $e');
      return SessionCheck.unknown;
    }
  }

  /// Performs a lightweight authenticated request and maps the status code to a
  /// [SessionCheck]. Self-contained (does not go through `handleResponse`) so it
  /// never triggers navigation by itself — the caller stays in control.
  static Future<SessionCheck> _validateTokenWithServer({
    required String token,
    String? userId,
  }) async {
    try {
      final id = (userId ?? AppData.logInUserId ?? '').toString();
      final uri = Uri.parse('${AppData.remoteUrl2}/profile?user_id=$id');

      final response = await http.get(
        uri,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.acceptHeader: 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) return SessionCheck.invalid;

      // An HTML login redirect disguised as 200 also means the session is dead.
      final bodyLower = response.body.toLowerCase();
      if (bodyLower.contains('<!doctype html') || bodyLower.contains('<html')) {
        return SessionCheck.invalid;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SessionCheck.valid;
      }

      // 5xx / 403 / other: inconclusive — don't log the user out over it.
      return SessionCheck.unknown;
    } catch (e) {
      debugPrint('SessionManager: token validation request failed: $e');
      return SessionCheck.unknown;
    }
  }

  /// Called when an authenticated request comes back unauthorized (HTTP 401 or a
  /// session-expiry redirect) while the app is running. Clears the session and
  /// routes to login.
  static Future<void> handleUnauthorized({String reason = 'unauthorized'}) async {
    final token = AppData.userToken?.trim() ?? '';
    if (token.isEmpty) return;

    await forceLogoutToLogin(reason: reason);
  }

  /// Clears the persisted + in-memory session and navigates to [LoginScreen],
  /// removing the entire navigation stack. Re-entrant calls are ignored.
  static Future<void> forceLogoutToLogin({String reason = 'logout'}) async {
    if (_isHandlingLogout) return;
    _isHandlingLogout = true;

    debugPrint('🔒 SessionManager: forcing logout to login ($reason)');

    try {
      _resetAppDataSession();
      await NotificationService.deregisterDeviceToken();
      NotificationCounterService().dispose();
      await _clearStoredSession();

      // Navigate to login on the next frame, removing the back stack.
      final navigator = NavigatorService.navigatorKey.currentState;
      if (navigator != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        });
      }
    } finally {
      // Allow a future expiry to trigger again once the redirect has settled.
      Future.delayed(const Duration(seconds: 3), () {
        _isHandlingLogout = false;
      });
    }
  }

  /// Removes the persisted session keys from secure storage.
  static Future<void> _clearStoredSession() async {
    try {
      final secure = SecureStorageService.instance;
      await secure.initialize();
      for (final key in _sessionKeys) {
        await secure.remove(key);
      }
    } catch (e) {
      debugPrint('SessionManager: error clearing secure storage: $e');
    }
  }

  /// Resets the in-memory [AppData] session statics.
  static void _resetAppDataSession() {
    AppData.userToken = null;
    AppData.logInUserId = null;
    AppData.name = '';
    AppData.email = '';
    AppData.profile_pic = '';
    AppData.profilePicNotifier.value = '';
    AppData.background = '';
    AppData.specialty = '';
    AppData.isVerified = false;
    AppData.clearSubscriptionData();
    AppData.clearVerificationData();
  }
}
