import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/subscription/premium_page_model.dart';
import 'package:doctak_app/data/models/subscription/subscription_plan_model.dart';

/// Service class for all /api/v6/subscription/* endpoints.
class SubscriptionApiService {
  SubscriptionApiService._();
  static final SubscriptionApiService instance = SubscriptionApiService._();

  Dio get _dio => Dio();

  Options get _authOptions => Options(
        headers: {'Authorization': 'Bearer ${AppData.userToken}'},
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      );

  String get _base => AppData.remoteUrlV6;

  // ── GET /api/v6/subscription/status ──────────────────────────────────────────

  Future<SubscriptionStatusResponse> getStatus() async {
    final resp = await _dio.get('$_base/subscription/status', options: _authOptions);
    return SubscriptionStatusResponse.fromJson(_asMap(resp.data));
  }

  // ── GET /api/v6/subscription/plans ───────────────────────────────────────────

  Future<SubscriptionPlansResponse> getPlans() async {
    final resp = await _dio.get('$_base/subscription/plans', options: _authOptions);
    return SubscriptionPlansResponse.fromJson(_asMap(resp.data));
  }

  // ── GET /api/v6/subscription/premium-page ────────────────────────────────────

  Future<PremiumPageResponse> getPremiumPage() async {
    final resp = await _dio.get('$_base/subscription/premium-page', options: _authOptions);
    return PremiumPageResponse.fromJson(_asMap(resp.data));
  }

  // ── GET /api/v6/subscription/history ─────────────────────────────────────────

  Future<List<SubscriptionHistoryItem>> getHistory() async {
    final resp = await _dio.get('$_base/subscription/history', options: _authOptions);
    final data = _asMap(resp.data);
    final list = data['history'] as List<dynamic>? ?? [];
    return list.map((e) => SubscriptionHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── GET /api/v6/me (refresh user + subscription) ─────────────────────────────

  Future<Map<String, dynamic>> getMe() async {
    final resp = await _dio.get('$_base/me', options: _authOptions);
    return _asMap(resp.data);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
