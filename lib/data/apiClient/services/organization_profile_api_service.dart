import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/organization_profile/organization_public_profile_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class OrganizationProfileApiService {
  static final OrganizationProfileApiService _instance =
      OrganizationProfileApiService._internal();
  factory OrganizationProfileApiService() => _instance;
  OrganizationProfileApiService._internal();

  String get _baseUrl => AppData.remoteUrl2;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${AppData.userToken}',
        'Accept': 'application/json',
      };

  Future<OrganizationPublicProfileModel> getPublicProfile(String identifier) async {
    final encoded = Uri.encodeComponent(identifier.trim());
    final url = '$_baseUrl/organizations/$encoded/public-profile';
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 404) {
      throw Exception('Organization profile not found.');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to load organization profile (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] == false) {
      throw Exception(body['message']?.toString() ?? 'Failed to load profile.');
    }
    return OrganizationPublicProfileModel.fromJson(body);
  }

  Future<OrganizationPeoplePage> getOrganizationPeople({
    required String organizationId,
    required OrganizationPeopleListKind kind,
    int page = 1,
    int perPage = 20,
  }) async {
    final encoded = Uri.encodeComponent(organizationId.trim());
    final segment =
        kind == OrganizationPeopleListKind.followers ? 'followers' : 'members';
    final url =
        '$_baseUrl/organizations/$encoded/$segment?page=$page&per_page=$perPage';
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load $segment (${response.statusCode}).');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] == false) {
      throw Exception(body['message']?.toString() ?? 'Failed to load $segment.');
    }
    return OrganizationPeoplePage.fromJson(body);
  }

  /// PATCH /api/business/{businessId}/profile — mirrors the website's
  /// workspace editor. Only owners/admins pass the server-side check.
  Future<void> updateBusinessProfile({
    required String businessId,
    required Map<String, dynamic> payload,
  }) async {
    final encoded = Uri.encodeComponent(businessId.trim());
    final response = await buildHttpResponseNode(
      '/api/business/$encoded/profile',
      method: HttpMethod.PATCH,
      body: payload,
    );
    final data = await handleResponse(response);
    if (data is Map && data['success'] == false) {
      throw Exception(
        data['message']?.toString() ?? 'Failed to update the business profile.',
      );
    }
  }

  /// DELETE /api/business/{businessId} — owner-only soft delete.
  Future<void> deleteBusiness({required String businessId}) async {
    final encoded = Uri.encodeComponent(businessId.trim());
    final response = await buildHttpResponseNode(
      '/api/business/$encoded',
      method: HttpMethod.DELETE,
    );
    final data = await handleResponse(response);
    if (data is Map && data['success'] == false) {
      throw Exception(
        data['message']?.toString() ?? 'Failed to delete the business page.',
      );
    }
  }

  /// POST /api/business/media — uploads the organization logo or cover
  /// (kind: 'logo' | 'cover'). Returns the public URL of the stored image.
  Future<String?> uploadBusinessMedia({
    required String organizationId,
    required String kind,
    required File file,
  }) async {
    final base = AppData.nodeApiUrl.endsWith('/')
        ? AppData.nodeApiUrl.substring(0, AppData.nodeApiUrl.length - 1)
        : AppData.nodeApiUrl;
    final request =
        http.MultipartRequest('POST', Uri.parse('$base/api/business/media'));

    final token = AppData.userToken?.trim();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    request.headers.addAll(ActingContextService.instance.actingHeaders());

    request.fields['kind'] = kind;
    request.fields['organizationId'] = organizationId;

    final name = file.path.split('/').last.toLowerCase();
    var mime = 'image/jpeg';
    if (name.endsWith('.png')) mime = 'image/png';
    if (name.endsWith('.webp')) mime = 'image/webp';
    if (name.endsWith('.gif')) mime = 'image/gif';

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType.parse(mime),
    ));

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is Map &&
        decoded['success'] == true) {
      final url = decoded['url']?.toString() ?? decoded['path']?.toString();
      return (url == null || url.isEmpty) ? null : AppData.fullImageUrl(url);
    }
    throw Exception(
      decoded is Map
          ? (decoded['message']?.toString() ?? 'Failed to upload image.')
          : 'Failed to upload image.',
    );
  }
}
