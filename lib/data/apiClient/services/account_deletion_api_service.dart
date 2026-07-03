import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/core/utils/app/app_environment.dart';

class AccountDeletionRequestStatus {
  final bool hasPending;
  final String? scheduledAt;
  final String? status;

  const AccountDeletionRequestStatus({
    required this.hasPending,
    this.scheduledAt,
    this.status,
  });

  factory AccountDeletionRequestStatus.fromJson(Map<String, dynamic> json) {
    final latest = json['latest_request'];
    final request = latest is Map<String, dynamic> ? latest : null;
    return AccountDeletionRequestStatus(
      hasPending: json['has_pending'] == true,
      scheduledAt: request?['scheduled_at']?.toString(),
      status: request?['status']?.toString(),
    );
  }
}

class AccountDeletionApiService {
  static const String _endpoint = '/api/v1/delete-account';
  static const String publicDeleteUrl = 'https://doctak.net/delete-account';

  static const List<String> dataCategories = [
    'Profile information (name, email, phone, specialty, credentials)',
    'Posts, comments, reactions, and shared clinical content',
    'Direct messages, chat history, and meeting participation',
    'Group memberships, invitations, and community activity',
    'Job applications and saved opportunities',
    'CME registrations, progress records, and certificates tied to your account',
    'Notifications, device sessions, and connected third-party accounts',
  ];

  static Future<AccountDeletionRequestStatus> getStatus() async {
    final response = await buildHttpResponseNode(_endpoint);
    final data = await handleResponse(response);
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected deletion status response.');
    }
    return AccountDeletionRequestStatus.fromJson(data);
  }

  static Future<String> requestDeletion({
    required String password,
    String? reason,
  }) async {
    final response = await buildHttpResponseNode(
      _endpoint,
      method: HttpMethod.POST,
      body: {
        'password': password,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    final data = await handleResponse(response);
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          'Your account is scheduled for deletion.';
    }
    return 'Your account is scheduled for deletion.';
  }

  static Future<String> cancelDeletion() async {
    final response = await buildHttpResponseNode(
      _endpoint,
      method: HttpMethod.DELETE,
    );
    final data = await handleResponse(response);
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          'Account deletion request cancelled.';
    }
    return 'Account deletion request cancelled.';
  }

  static String get deleteAccountWebUrl => AppEnvironment.isProduction
      ? publicDeleteUrl
      : '${AppEnvironment.nodeApiUrl}/delete-account';
}
