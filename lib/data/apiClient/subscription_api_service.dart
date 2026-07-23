import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_environment.dart';
import 'package:doctak_app/data/models/subscription/premium_page_model.dart';
import 'package:doctak_app/data/models/subscription/subscription_plan_model.dart';

/// Subscription APIs from **doctak-node** (`/api/v1/subscription/*`).
/// Do not call Laravel for plans, status, premium-page, or history.
class SubscriptionApiService {
  SubscriptionApiService._();
  static final SubscriptionApiService instance = SubscriptionApiService._();

  Dio get _dio => Dio();

  Options get _authOptions => Options(
        headers: {'Authorization': 'Bearer ${AppData.userToken}'},
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      );

  /// doctak-node Next.js API root (production: https://doctak.net/api/v1).
  String get _base => '${AppEnvironment.nodeApiUrl}/api/v1';

  // ── GET /api/v1/subscription/status ──────────────────────────────────────────

  Future<SubscriptionStatusResponse> getStatus() async {
    final resp = await _dio.get('$_base/subscription/status', options: _authOptions);
    return SubscriptionStatusResponse.fromJson(_asMap(resp.data));
  }

  // ── GET /api/v1/subscription/plans ───────────────────────────────────────────

  Future<SubscriptionPlansResponse> getPlans() async {
    final resp = await _dio.get('$_base/subscription/plans', options: _authOptions);
    return SubscriptionPlansResponse.fromJson(_asMap(resp.data));
  }

  // ── GET /api/v1/subscription/premium-page ────────────────────────────────────

  Future<PremiumPageResponse> getPremiumPage() async {
    final resp = await _dio.get('$_base/subscription/premium-page', options: _authOptions);
    return PremiumPageResponse.fromJson(_asMap(resp.data));
  }

  // ── GET /api/v1/subscription/history ─────────────────────────────────────────

  Future<List<SubscriptionHistoryItem>> getHistory() async {
    final resp = await _dio.get('$_base/subscription/history', options: _authOptions);
    final data = _asMap(resp.data);
    final list = data['history'] as List<dynamic>? ?? [];
    return list
        .map((e) => SubscriptionHistoryItem.fromJson(
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  // ── GET /api/v1/me (refresh user + subscription) ─────────────────────────────

  Future<Map<String, dynamic>> getMe() async {
    final resp = await _dio.get('$_base/me', options: _authOptions);
    return _asMap(resp.data);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
