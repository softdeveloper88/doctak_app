import 'dart:convert';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/organization_profile/organization_public_profile_model.dart';
import 'package:http/http.dart' as http;

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
}
