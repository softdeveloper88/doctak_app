import 'dart:convert';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_environment.dart';
import 'package:http/http.dart' as http;

enum EmailVerificationCode {
  sent,
  alreadyVerified,
  sendFailed,
  notFound,
  rateLimited,
  unknown,
}

class EmailVerificationResult {
  const EmailVerificationResult({
    required this.success,
    required this.message,
    required this.code,
  });

  final bool success;
  final String message;
  final EmailVerificationCode code;
}

/// Resends the account verification email via doctak-node.
/// Account verification uses an email link (open link to verify).
class EmailVerificationService {
  static String get _base {
    final url = AppEnvironment.nodeApiUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static Future<EmailVerificationResult> resend(String email) async {
    final trimmedEmail = email.trim();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final auth = AppData.userToken?.trim();
    if (auth != null && auth.isNotEmpty) {
      headers['Authorization'] = 'Bearer $auth';
    }

    final response = await http.post(
      Uri.parse('$_base/api/auth/resend-verification'),
      headers: headers,
      body: jsonEncode({'email': trimmedEmail}),
    );

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    final message = json?['message']?.toString().trim() ?? '';

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json?['success'] == true) {
      return EmailVerificationResult(
        success: true,
        message: message.isNotEmpty
            ? message
            : 'Verification link sent. Please check your inbox and open the link.',
        code: EmailVerificationCode.sent,
      );
    }

    if (response.statusCode == 409) {
      return EmailVerificationResult(
        success: false,
        message: message.isNotEmpty
            ? message
            : 'This email address is already verified.',
        code: EmailVerificationCode.alreadyVerified,
      );
    }

    if (response.statusCode == 503) {
      return EmailVerificationResult(
        success: false,
        message: message.isNotEmpty
            ? message
            : 'We could not send the verification email right now. Please try again shortly.',
        code: EmailVerificationCode.sendFailed,
      );
    }

    if (response.statusCode == 404) {
      return EmailVerificationResult(
        success: false,
        message: message.isNotEmpty
            ? message
            : 'We could not find an account that needs verification.',
        code: EmailVerificationCode.notFound,
      );
    }

    if (response.statusCode == 429) {
      return EmailVerificationResult(
        success: false,
        message: message.isNotEmpty
            ? message
            : 'Too many requests. Please wait a few minutes and try again.',
        code: EmailVerificationCode.rateLimited,
      );
    }

    return EmailVerificationResult(
      success: false,
      message: message.isNotEmpty ? message : 'Something went wrong. Please try again.',
      code: EmailVerificationCode.unknown,
    );
  }

  /// Submit the 6-digit code from the verification email.
  static Future<EmailVerificationResult> verifyCode({
    required String email,
    required String code,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final auth = AppData.userToken?.trim();
    if (auth != null && auth.isNotEmpty) {
      headers['Authorization'] = 'Bearer $auth';
    }

    final response = await http.post(
      Uri.parse('$_base/api/auth/verify-email'),
      headers: headers,
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
      }),
    );

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    final message = json?['message']?.toString().trim() ?? '';

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json?['success'] == true) {
      return EmailVerificationResult(
        success: true,
        message: message.isNotEmpty ? message : 'Email verified successfully.',
        code: EmailVerificationCode.alreadyVerified,
      );
    }

    return EmailVerificationResult(
      success: false,
      message: message.isNotEmpty
          ? message
          : 'That verification code is invalid. Request a new one and try again.',
      code: EmailVerificationCode.unknown,
    );
  }
}
