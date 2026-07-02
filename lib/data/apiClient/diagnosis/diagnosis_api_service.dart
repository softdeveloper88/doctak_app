import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/diagnosis/diagnosis_model.dart';

class DiagnosisApiService {
  static String get _baseUrl => '${AppData.remoteUrlV6}/diagnosis';

  /// List all diagnoses with optional filters
  static Future<DiagnosisListResponse> getDiagnoses({
    int page = 1,
    String? search,
    String? contentType,
    String? dateFrom,
    String? dateTo,
    String? gender,
  }) async {
    final params = <String, String>{'page': '$page'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (contentType != null && contentType.isNotEmpty) {
      params['content_type'] = contentType;
    }
    if (dateFrom != null && dateFrom.isNotEmpty) params['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) params['date_to'] = dateTo;
    if (gender != null && gender.isNotEmpty) params['gender'] = gender;

    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await buildHttpResponse1('$_baseUrl?$query');
    final data = await handleResponse(response);
    return DiagnosisListResponse.fromJson(data);
  }

  /// Get a single diagnosis by ID
  static Future<DiagnosisDetailResponse> getDiagnosis(int id) async {
    final response = await buildHttpResponse1('$_baseUrl/$id');
    final data = await handleResponse(response);
    return DiagnosisDetailResponse.fromJson(data);
  }

  /// Create a new diagnosis (POST /diagnosis)
  static Future<DiagnosisStoreResponse> storeDiagnosis(
      DiagnosisModel diagnosis) async {
    final response = await buildHttpResponse1(
      _baseUrl,
      method: HttpMethod.POST,
      request: diagnosis.toRequestBody(),
    );
    final data = await handleResponse(response);
    return DiagnosisStoreResponse.fromJson(data);
  }

  /// Update an existing diagnosis (PUT /diagnosis/{id})
  static Future<DiagnosisStoreResponse> updateDiagnosis(
      int id, DiagnosisModel diagnosis) async {
    final body = diagnosis.toRequestBody();
    final response = await buildHttpResponse1(
      '$_baseUrl/$id',
      method: HttpMethod.PUT,
      request: body,
    );
    final data = await handleResponse(response);
    return DiagnosisStoreResponse.fromJson(data);
  }

  /// Delete a diagnosis (DELETE /diagnosis/{id})
  static Future<void> deleteDiagnosis(int id) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/$id',
      method: HttpMethod.DELETE,
    );
    await handleResponse(response);
  }

  /// Regenerate AI analysis for a specific content type
  static Future<AnalyzeResponse> analyzeDiagnosis(
      int id, String contentType) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/$id/analyze',
      method: HttpMethod.POST,
      request: {'content_type': contentType},
    );
    final data = await handleResponse(response);
    return AnalyzeResponse.fromJson(data);
  }

  /// Search for similar cases
  static Future<List<SimilarCaseItem>> searchSimilar(String complaint) async {
    final query = Uri.encodeComponent(complaint);
    final response = await buildHttpResponse1(
      '$_baseUrl/assistant/similar?complaint=$query',
    );
    final data = await handleResponse(response);
    if (data['cases'] != null) {
      return (data['cases'] as List)
          .map((e) => SimilarCaseItem.fromJson(e))
          .toList();
    }
    return [];
  }
}
