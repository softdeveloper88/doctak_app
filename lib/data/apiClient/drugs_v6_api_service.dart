import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';

/// Drugs V6 API Service
/// Covers all /api/v6/drugs/* endpoints.
class DrugsV6ApiService {
  DrugsV6ApiService._();
  static final DrugsV6ApiService instance = DrugsV6ApiService._();

  static const Duration _timeout = Duration(seconds: 20);

  Dio get _dio => Dio();

  String get _base => AppData.remoteUrlV6;

  Options get _auth => Options(
        headers: {'Authorization': 'Bearer ${AppData.userToken}'},
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // 1. LIST DRUGS  GET /v6/drugs
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches paginated drug list with optional filters.
  Future<DrugV6ListResponse> getDrugs({
    String? countryId,
    int page = 1,
    int perPage = 15,
    DrugActiveFilters? filters,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (countryId != null && countryId.isNotEmpty) params['country_id'] = countryId;
    if (filters != null) params.addAll(filters.toQueryParams());

    final resp = await _dio.get(
      '$_base/drugs',
      queryParameters: params,
      options: _auth,
    );
    return DrugV6ListResponse.fromJson(_asMap(resp.data));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. SINGLE DRUG  GET /v6/drugs/{id}
  // ─────────────────────────────────────────────────────────────────────────

  Future<DrugV6Item?> getDrugDetail(int id, {String? countryId}) async {
    final params = <String, dynamic>{};
    if (countryId != null) params['country_id'] = countryId;
    final resp = await _dio.get(
      '$_base/drugs/$id',
      queryParameters: params,
      options: _auth,
    );
    final body = _asMap(resp.data);
    if (body['success'] != true) return null;
    final data = body['data'];
    if (data == null) return null;
    return DrugV6Item.fromJson(data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. SEARCH SUGGESTIONS  GET /v6/drugs/search-suggestions
  // ─────────────────────────────────────────────────────────────────────────

  Future<DrugV6Suggestions> getSearchSuggestions({
    required String q,
    String type = 'Brand',
    String? countryId,
    int limit = 10,
  }) async {
    final params = <String, dynamic>{
      'q': q,
      'type': type,
      'limit': limit,
    };
    if (countryId != null) params['country_id'] = countryId;
    try {
      final resp = await _dio.get(
        '$_base/drugs/search-suggestions',
        queryParameters: params,
        options: _auth,
      );
      return DrugV6Suggestions.fromJson(_asMap(resp.data));
    } catch (_) {
      return const DrugV6Suggestions(success: false, data: [], type: 'Brand');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. COUNTRIES WITH DRUG DATA  GET /v6/drugs/countries
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDrugCountries() async {
    try {
      final resp = await _dio.get('$_base/drugs/countries', options: _auth);
      final body = _asMap(resp.data);
      final list = body['data'] as List<dynamic>? ?? [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. FILTER OPTIONS  GET /v6/drugs/filters
  // ─────────────────────────────────────────────────────────────────────────

  Future<DrugV6Filters> getFilters({String? countryId}) async {
    final params = <String, dynamic>{};
    if (countryId != null) params['country_id'] = countryId;
    try {
      final resp = await _dio.get(
        '$_base/drugs/filters',
        queryParameters: params,
        options: _auth,
      );
      return DrugV6Filters.fromJson(_asMap(resp.data));
    } catch (_) {
      return const DrugV6Filters();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 6. FEATURED DRUGS  GET /v6/drugs/featured
  // ─────────────────────────────────────────────────────────────────────────

  Future<DrugV6Featured> getFeatured({String? countryId, int limit = 8}) async {
    final params = <String, dynamic>{'limit': limit};
    if (countryId != null) params['country_id'] = countryId;
    try {
      final resp = await _dio.get(
        '$_base/drugs/featured',
        queryParameters: params,
        options: _auth,
      );
      return DrugV6Featured.fromJson(_asMap(resp.data));
    } catch (_) {
      return const DrugV6Featured(success: false, data: []);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 7. AI USAGE  GET /v6/drugs/ai/usage
  // ─────────────────────────────────────────────────────────────────────────

  Future<DrugAIUsage> getAIUsage() async {
    final resp = await _dio.get('$_base/drugs/ai/usage', options: _auth);
    return DrugAIUsage.fromJson(_asMap(resp.data));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 8. CREATE / GET AI SESSION  POST /v6/drugs/ai/session
  // ─────────────────────────────────────────────────────────────────────────

  Future<DrugAISession> createAISession({
    required String genericName,
    String? tradeName,
  }) async {
    final resp = await _dio.post(
      '$_base/drugs/ai/session',
      data: {
        'generic_name': genericName,
        if (tradeName != null) 'trade_name': tradeName,
      },
      options: _auth,
    );
    return DrugAISession.fromJson(_asMap(resp.data));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 9. ASK AI  POST /v6/drugs/ai/ask
  // ─────────────────────────────────────────────────────────────────────────

  Future<DrugAIAskResponse> askAI({
    required String question,
    required String genericName,
    String? tradeName,
    int? sessionId,
  }) async {
    final resp = await _dio.post(
      '$_base/drugs/ai/ask',
      data: {
        'question': question,
        'generic_name': genericName,
        if (tradeName != null) 'trade_name': tradeName,
        if (sessionId != null) 'session_id': sessionId,
      },
      options: _auth,
    );
    return DrugAIAskResponse.fromJson(_asMap(resp.data));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
