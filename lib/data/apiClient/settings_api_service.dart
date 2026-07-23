import 'package:doctak_app/core/network/network_utils.dart';

/// Account settings API — mobile `/api/v1/settings/*` (same handlers as website `/api/settings/*`).
class SettingsApiService {
  SettingsApiService._();

  static const String _base = '/api/v1/settings';

  static Future<Map<String, dynamic>> getPreferences({bool full = true}) async {
    final response = await buildHttpResponseNode(
      '$_base/preferences${full ? '' : '?scope=core'}',
      method: HttpMethod.GET,
    );
    final data = await handleResponse(response);
    if (data is! Map) {
      throw Exception('Could not load settings.');
    }
    final map = Map<String, dynamic>.from(data);
    if (map['success'] == false) {
      throw Exception(map['message']?.toString() ?? 'Could not load settings.');
    }
    final settings = map['settings'];
    if (settings is Map) {
      return Map<String, dynamic>.from(settings);
    }
    return map;
  }

  static Future<Map<String, dynamic>> updateNotifications(
    Map<String, bool> updates,
  ) async {
    final response = await buildHttpResponseNode(
      '$_base/preferences',
      method: HttpMethod.PATCH,
      body: {'notifications': updates},
    );
    final data = await handleResponse(response);
    if (data is! Map) {
      throw Exception('Could not save notification settings.');
    }
    final map = Map<String, dynamic>.from(data);
    if (map['success'] == false) {
      throw Exception(map['message']?.toString() ?? 'Could not save notification settings.');
    }
    final settings = map['settings'];
    if (settings is Map) {
      return Map<String, dynamic>.from(settings);
    }
    return map;
  }

  static Future<void> deleteSession(String sessionId) async {
    final encoded = Uri.encodeComponent(sessionId);
    final response = await buildHttpResponseNode(
      '$_base/sessions/$encoded',
      method: HttpMethod.DELETE,
    );
    final data = await handleResponse(response);
    if (data is Map && data['success'] == false) {
      throw Exception(data['message']?.toString() ?? 'Could not remove session.');
    }
  }

  static Future<Map<String, dynamic>> getAiUsage() async {
    final response = await buildHttpResponseNode(
      '$_base/ai-usage',
      method: HttpMethod.GET,
    );
    final data = await handleResponse(response);
    if (data is! Map) {
      throw Exception('Could not load AI usage.');
    }
    final map = Map<String, dynamic>.from(data);
    if (map['success'] == false) {
      throw Exception(map['message']?.toString() ?? 'Could not load AI usage.');
    }
    final payload = map['data'];
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return map;
  }

  static Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final response = await buildHttpResponseNode(
      '$_base/password',
      method: HttpMethod.POST,
      body: {
        'old_password': oldPassword,
        'password': newPassword,
        'password_confirmation': confirmation,
      },
    );
    final data = await handleResponse(response);
    if (data is Map) {
      if (data['success'] == false) {
        throw Exception(data['message']?.toString() ?? 'Could not update password.');
      }
      return data['message']?.toString() ?? 'Password updated successfully.';
    }
    return 'Password updated successfully.';
  }

  static Future<Map<String, dynamic>> getTwoFactorStatus() async {
    final response = await buildHttpResponseNode(
      '$_base/two-factor',
      method: HttpMethod.GET,
    );
    final data = await handleResponse(response);
    if (data is! Map) {
      throw Exception('Could not load two-factor settings.');
    }
    final map = Map<String, dynamic>.from(data);
    if (map['success'] == false) {
      throw Exception(map['message']?.toString() ?? 'Could not load two-factor settings.');
    }
    return map;
  }

  static Future<Map<String, dynamic>> toggleEmailOtp(bool enabled) async {
    final response = await buildHttpResponseNode(
      '$_base/two-factor/email',
      method: HttpMethod.POST,
      body: {'enabled': enabled},
    );
    final data = await handleResponse(response);
    if (data is! Map) {
      throw Exception('Failed to update Email OTP.');
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> setupAuthenticator({bool reset = false}) async {
    final response = await buildHttpResponseNode(
      '$_base/two-factor/app/setup',
      method: HttpMethod.POST,
      body: {'reset': reset},
    );
    final data = await handleResponse(response);
    if (data is! Map) {
      throw Exception('Could not start authenticator setup.');
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> verifyOrDisableAuthenticator({
    required String action,
    String code = '',
    String password = '',
  }) async {
    final response = await buildHttpResponseNode(
      '$_base/two-factor/app/verify',
      method: HttpMethod.POST,
      body: {
        'action': action,
        'code': code,
        'password': password,
      },
    );
    final data = await handleResponse(response);
    if (data is! Map) {
      throw Exception(action == 'disable' ? 'Could not disable authenticator.' : 'Invalid code.');
    }
    return Map<String, dynamic>.from(data);
  }
}
