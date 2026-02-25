import 'dart:convert';

import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/profile_model/award_model.dart';
import 'package:doctak_app/data/models/profile_model/business_hour_model.dart';
import 'package:doctak_app/data/models/profile_model/education_detail_model.dart';
import 'package:doctak_app/data/models/profile_model/experience_model.dart';
import 'package:doctak_app/data/models/profile_model/full_profile_model.dart';
import 'package:doctak_app/data/models/profile_model/medical_license_model.dart';
import 'package:doctak_app/data/models/profile_model/publication_model.dart';
import 'package:doctak_app/data/models/profile_model/social_profile_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';
import 'package:http/http.dart' as http;

/// V5 Profile API Service
/// All endpoints use /api/v5/ prefix
class V5ProfileApiService {
  static final V5ProfileApiService _instance = V5ProfileApiService._internal();
  factory V5ProfileApiService() => _instance;
  V5ProfileApiService._internal();

  /// Get v5 base URL by replacing v4 with v5 in the current API URL
  static String get _v5BaseUrl =>
      AppData.remoteUrl2.replaceAll('/v4', '/v5');

  /// Get v4 base URL (the standard API URL)
  static String get _v4BaseUrl => AppData.remoteUrl2;

  /// Build headers with Bearer token
  Map<String, String> _headers({String contentType = 'application/x-www-form-urlencoded'}) {
    return {
      'Authorization': 'Bearer ${AppData.userToken}',
      'Accept': 'application/json',
      'Content-Type': contentType,
    };
  }

  /// Try a request on v5 first, fall back to v4 if v5 returns 404/unreachable
  Future<http.Response> _tryRequest(
    Future<http.Response> Function(String baseUrl) requestFn,
  ) async {
    try {
      final response = await requestFn(_v5BaseUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode != 404) return response;
      print('🌐 V5 returned 404, trying v4 fallback...');
    } catch (e) {
      print('🌐 V5 request failed ($e), trying v4 fallback...');
    }
    // Fallback to v4
    return await requestFn(_v4BaseUrl).timeout(const Duration(seconds: 15));
  }

  /// Generic GET request (tries v5 then v4)
  Future<Map<String, dynamic>> _getRequest(String endpoint) async {
    print('🌐 API GET: $endpoint');
    final response = await _tryRequest(
      (baseUrl) => http.get(Uri.parse('$baseUrl$endpoint'), headers: _headers()),
    );
    print('🌐 API Response: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Generic POST request (tries v5 then v4)
  Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, String> body,
  ) async {
    print('🌐 API POST: $endpoint');
    final response = await _tryRequest(
      (baseUrl) => http.post(Uri.parse('$baseUrl$endpoint'), headers: _headers(), body: body),
    );
    print('🌐 API Response: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Generic PUT request (tries v5 then v4, JSON body)
  Future<Map<String, dynamic>> _putRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    print('🌐 API PUT: $endpoint');
    final response = await _tryRequest(
      (baseUrl) => http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers(contentType: 'application/json'),
        body: jsonEncode(body),
      ),
    );
    print('🌐 API Response: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  /// Generic DELETE request (tries v5 then v4)
  Future<Map<String, dynamic>> _deleteRequest(String endpoint) async {
    print('🌐 API DELETE: $endpoint');
    final response = await _tryRequest(
      (baseUrl) => http.delete(Uri.parse('$baseUrl$endpoint'), headers: _headers()),
    );
    print('🌐 API Response: ${response.statusCode}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  // ═══════════════════════════════════════════════
  //  FULL PROFILE
  // ═══════════════════════════════════════════════

  /// Get complete profile data (single endpoint for mobile)
  Future<ApiResponse<FullProfileModel>> getFullProfile({
    required String userId,
  }) async {
    try {
      print('🌐 V5 getFullProfile called for userId=$userId');
      final data = await _getRequest('/full-profile?user_id=$userId');
      print('🌐 V5 getFullProfile success');
      return ApiResponse.success(FullProfileModel.fromJson(data));
    } catch (e) {
      print('🌐 V5 getFullProfile error: $e');
      return ApiResponse.error('Failed to load profile: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  PROFILE UPDATE (v5 — replaces v4/profile/update)
  // ═══════════════════════════════════════════════

  /// Update user table fields (name, phone, specialty, DOB, gender, etc.)
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? licenseNo,
    String? specialty,
    String? dob,
    String? gender,
    String? country,
    String? city,
    String? state,
    String? countryOrigin,
    String? stateOrigin,
    String? clinicName,
    String? college,
    String? practicingCountry,
    // Privacy fields
    String? dobPrivacy,
    String? emailPrivacy,
    String? genderPrivacy,
    String? phonePrivacy,
    String? licenseNoPrivacy,
    String? specialtyPrivacy,
    String? countryPrivacy,
    String? cityPrivacy,
    String? statePrivacy,
    String? countryOriginPrivacy,
    String? clinicNamePrivacy,
  }) async {
    try {
      final body = <String, String>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phone != null) body['phone'] = phone;
      if (licenseNo != null) body['license_no'] = licenseNo;
      if (specialty != null) body['specialty'] = specialty;
      if (dob != null) body['dob'] = dob;
      if (gender != null) body['gender'] = gender;
      if (country != null) body['country'] = country;
      if (city != null) body['city'] = city;
      if (state != null) body['state'] = state;
      if (countryOrigin != null) body['country_origin'] = countryOrigin;
      if (stateOrigin != null) body['state_origin'] = stateOrigin;
      if (clinicName != null) body['clinic_name'] = clinicName;
      if (college != null) body['college'] = college;
      if (practicingCountry != null) body['practicing_country'] = practicingCountry;
      // Privacy
      if (dobPrivacy != null) body['dob_privacy'] = dobPrivacy;
      if (emailPrivacy != null) body['email_privacy'] = emailPrivacy;
      if (genderPrivacy != null) body['gender_privacy'] = genderPrivacy;
      if (phonePrivacy != null) body['phone_privacy'] = phonePrivacy;
      if (licenseNoPrivacy != null) body['license_no_privacy'] = licenseNoPrivacy;
      if (specialtyPrivacy != null) body['specialty_privacy'] = specialtyPrivacy;
      if (countryPrivacy != null) body['country_privacy'] = countryPrivacy;
      if (cityPrivacy != null) body['city_privacy'] = cityPrivacy;
      if (statePrivacy != null) body['state_privacy'] = statePrivacy;
      if (countryOriginPrivacy != null) body['country_origin_privacy'] = countryOriginPrivacy;
      if (clinicNamePrivacy != null) body['clinic_name_privacy'] = clinicNamePrivacy;

      final data = await _postRequest('/profile/update', body);
      return ApiResponse.success(data);
    } catch (e) {
      return ApiResponse.error('Failed to update profile: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  ABOUT ME UPDATE (v5 — replaces v4/about-me/update)
  // ═══════════════════════════════════════════════

  /// Update profiles table fields (about_me, address, birthplace, etc.)
  Future<ApiResponse<Map<String, dynamic>>> updateAboutMe({
    String? aboutMe,
    String? address,
    String? birthplace,
    String? livesIn,
    String? languages,
    // Privacy fields
    String? aboutMePrivacy,
    String? addressPrivacy,
    String? birthplacePrivacy,
    String? languagesPrivacy,
    String? livesInPrivacy,
    String? phonePrivacy,
  }) async {
    try {
      final body = <String, String>{};
      if (aboutMe != null) body['about_me'] = aboutMe;
      if (address != null) body['address'] = address;
      if (birthplace != null) body['birthplace'] = birthplace;
      if (livesIn != null) body['lives_in'] = livesIn;
      if (languages != null) body['languages'] = languages;
      // Privacy
      if (aboutMePrivacy != null) body['about_me_privacy'] = aboutMePrivacy;
      if (addressPrivacy != null) body['address_privacy'] = addressPrivacy;
      if (birthplacePrivacy != null) body['birthplace_privacy'] = birthplacePrivacy;
      if (languagesPrivacy != null) body['languages_privacy'] = languagesPrivacy;
      if (livesInPrivacy != null) body['lives_in_privacy'] = livesInPrivacy;
      if (phonePrivacy != null) body['phone_privacy'] = phonePrivacy;

      final data = await _postRequest('/about-me/update', body);
      return ApiResponse.success(data);
    } catch (e) {
      return ApiResponse.error('Failed to update about me: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  PRIVACY SETTINGS
  // ═══════════════════════════════════════════════

  /// Get all privacy settings for the current user
  Future<ApiResponse<Map<String, dynamic>>> getPrivacySettings() async {
    try {
      final data = await _getRequest('/privacy-settings');
      if (data['success'] == true) {
        return ApiResponse.success(Map<String, dynamic>.from(data['data'] ?? {}));
      }
      return ApiResponse.error('Failed to load privacy settings');
    } catch (e) {
      return ApiResponse.error('Failed to load privacy settings: $e');
    }
  }

  /// Bulk update privacy settings
  Future<ApiResponse<Map<String, dynamic>>> updatePrivacySettings({
    required Map<String, String> settings,
  }) async {
    try {
      // Need JSON body for nested map
      final response = await _tryRequest(
        (baseUrl) => http.post(
          Uri.parse('$baseUrl/privacy-settings'),
          headers: _headers(contentType: 'application/json'),
          body: jsonEncode({'settings': settings}),
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse.success(data);
      }
      return ApiResponse.error('Failed: ${response.statusCode}');
    } catch (e) {
      return ApiResponse.error('Failed to update privacy settings: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  EXPERIENCES CRUD
  // ═══════════════════════════════════════════════

  Future<ApiResponse<List<ExperienceModel>>> getExperiences({
    required String userId,
  }) async {
    try {
      final data = await _getRequest('/experiences?user_id=$userId');
      final list = (data['data'] as List<dynamic>)
          .map((e) => ExperienceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error('Failed to load experiences: $e');
    }
  }

  Future<ApiResponse<ExperienceModel>> storeExperience({
    required String position,
    required String companyName,
    required String startDate,
    String? endDate,
    String? location,
    String? description,
  }) async {
    try {
      final body = <String, String>{
        'position': position,
        'company_name': companyName,
        'start_date': startDate,
      };
      if (endDate != null) body['end_date'] = endDate;
      if (location != null) body['location'] = location;
      if (description != null) body['description'] = description;

      final data = await _postRequest('/experiences', body);
      return ApiResponse.success(
        ExperienceModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to add experience: $e');
    }
  }

  Future<ApiResponse<ExperienceModel>> updateExperience({
    required int id,
    required String position,
    required String companyName,
    required String startDate,
    String? endDate,
    String? location,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{
        'position': position,
        'company_name': companyName,
        'start_date': startDate,
      };
      if (endDate != null) body['end_date'] = endDate;
      if (location != null) body['location'] = location;
      if (description != null) body['description'] = description;

      final data = await _putRequest('/experiences/$id', body);
      return ApiResponse.success(
        ExperienceModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to update experience: $e');
    }
  }

  Future<ApiResponse<bool>> deleteExperience({required int id}) async {
    try {
      await _deleteRequest('/experiences/$id');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to delete experience: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  EDUCATION CRUD
  // ═══════════════════════════════════════════════

  Future<ApiResponse<List<EducationDetailModel>>> getEducation({
    required String userId,
  }) async {
    try {
      final data = await _getRequest('/education?user_id=$userId');
      final list = (data['data'] as List<dynamic>)
          .map((e) =>
              EducationDetailModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error('Failed to load education: $e');
    }
  }

  Future<ApiResponse<EducationDetailModel>> storeEducation({
    required String degree,
    required String institution,
    String? fieldOfStudy,
    required int startYear,
    int? endYear,
    bool currentStudy = false,
    String? gpa,
    String? honors,
    String? thesisTitle,
    String? description,
    String? location,
    String? specialization,
    String? activities,
    String privacy = 'public',
  }) async {
    try {
      final body = <String, String>{
        'degree': degree,
        'institution': institution,
        'start_year': startYear.toString(),
        'privacy': privacy,
      };
      if (fieldOfStudy != null && fieldOfStudy.isNotEmpty) body['field_of_study'] = fieldOfStudy;
      if (currentStudy) {
        body['current_study'] = '1';
      } else if (endYear != null) {
        body['end_year'] = endYear.toString();
      }
      if (gpa != null && gpa.isNotEmpty) body['gpa'] = gpa;
      if (honors != null && honors.isNotEmpty) body['honors'] = honors;
      if (thesisTitle != null && thesisTitle.isNotEmpty) body['thesis_title'] = thesisTitle;
      if (description != null && description.isNotEmpty) body['description'] = description;
      if (location != null && location.isNotEmpty) body['location'] = location;
      if (specialization != null && specialization.isNotEmpty) body['specialization'] = specialization;
      if (activities != null && activities.isNotEmpty) body['activities'] = activities;

      final data = await _postRequest('/education', body);
      return ApiResponse.success(
        EducationDetailModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to add education: $e');
    }
  }

  Future<ApiResponse<EducationDetailModel>> updateEducation({
    required int id,
    required String degree,
    required String institution,
    String? fieldOfStudy,
    required int startYear,
    int? endYear,
    bool currentStudy = false,
    String? gpa,
    String? honors,
    String? thesisTitle,
    String? description,
    String? location,
    String? specialization,
    String? activities,
    String privacy = 'public',
  }) async {
    try {
      final body = <String, dynamic>{
        'degree': degree,
        'institution': institution,
        'start_year': startYear,
        'privacy': privacy,
      };
      if (fieldOfStudy != null && fieldOfStudy.isNotEmpty) body['field_of_study'] = fieldOfStudy;
      if (currentStudy) {
        body['current_study'] = true;
      } else if (endYear != null) {
        body['end_year'] = endYear;
      }
      if (gpa != null && gpa.isNotEmpty) body['gpa'] = gpa;
      if (honors != null && honors.isNotEmpty) body['honors'] = honors;
      if (thesisTitle != null && thesisTitle.isNotEmpty) body['thesis_title'] = thesisTitle;
      if (description != null && description.isNotEmpty) body['description'] = description;
      if (location != null && location.isNotEmpty) body['location'] = location;
      if (specialization != null && specialization.isNotEmpty) body['specialization'] = specialization;
      if (activities != null && activities.isNotEmpty) body['activities'] = activities;

      final data = await _putRequest('/education/$id', body);
      return ApiResponse.success(
        EducationDetailModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to update education: $e');
    }
  }

  Future<ApiResponse<bool>> deleteEducation({required int id}) async {
    try {
      await _deleteRequest('/education/$id');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to delete education: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  PUBLICATIONS CRUD
  // ═══════════════════════════════════════════════

  Future<ApiResponse<List<PublicationModel>>> getPublications({
    required String userId,
  }) async {
    try {
      final data = await _getRequest('/publications?user_id=$userId');
      final list = (data['data'] as List<dynamic>)
          .map((e) => PublicationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error('Failed to load publications: $e');
    }
  }

  Future<ApiResponse<PublicationModel>> storePublication({
    required String title,
    required String journalName,
    required String publicationDate,
    String? coAuthor,
    String? abstract_,
    String? keywords,
    String? impactFactor,
    String? citations,
    String? doiLink,
    String privacy = 'public',
  }) async {
    try {
      final body = <String, String>{
        'title': title,
        'journal_name': journalName,
        'publication_date': publicationDate,
        'privacy': privacy,
      };
      if (coAuthor != null) body['co_author'] = coAuthor;
      if (abstract_ != null) body['abstract'] = abstract_;
      if (keywords != null) body['keywords'] = keywords;
      if (impactFactor != null) body['impact_factor'] = impactFactor;
      if (citations != null) body['citations'] = citations;
      if (doiLink != null) body['doi_link'] = doiLink;

      final data = await _postRequest('/publications', body);
      return ApiResponse.success(
        PublicationModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to add publication: $e');
    }
  }

  Future<ApiResponse<PublicationModel>> updatePublication({
    required int id,
    required String title,
    required String journalName,
    required String publicationDate,
    String? coAuthor,
    String? abstract_,
    String? keywords,
    String? impactFactor,
    String? citations,
    String? doiLink,
    String privacy = 'public',
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'journal_name': journalName,
        'publication_date': publicationDate,
        'privacy': privacy,
      };
      if (coAuthor != null) body['co_author'] = coAuthor;
      if (abstract_ != null) body['abstract'] = abstract_;
      if (keywords != null) body['keywords'] = keywords;
      if (impactFactor != null) body['impact_factor'] = impactFactor;
      if (citations != null) body['citations'] = citations;
      if (doiLink != null) body['doi_link'] = doiLink;

      final data = await _putRequest('/publications/$id', body);
      return ApiResponse.success(
        PublicationModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to update publication: $e');
    }
  }

  Future<ApiResponse<bool>> deletePublication({required int id}) async {
    try {
      await _deleteRequest('/publications/$id');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to delete publication: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  AWARDS CRUD
  // ═══════════════════════════════════════════════

  Future<ApiResponse<List<AwardModel>>> getAwards({
    required String userId,
  }) async {
    try {
      final data = await _getRequest('/awards?user_id=$userId');
      final list = (data['data'] as List<dynamic>)
          .map((e) => AwardModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error('Failed to load awards: $e');
    }
  }

  Future<ApiResponse<AwardModel>> storeAward({
    required String awardName,
    String? awardingBody,
    String? dateReceived,
    String? description,
    String? level,
    String privacy = 'public',
  }) async {
    try {
      final body = <String, String>{
        'award_name': awardName,
        'privacy': privacy,
      };
      if (awardingBody != null) body['awarding_body'] = awardingBody;
      if (dateReceived != null) body['date_received'] = dateReceived;
      if (description != null) body['description'] = description;
      if (level != null) body['level'] = level;

      final data = await _postRequest('/awards', body);
      return ApiResponse.success(
        AwardModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to add award: $e');
    }
  }

  Future<ApiResponse<AwardModel>> updateAward({
    required int id,
    required String awardName,
    String? awardingBody,
    String? dateReceived,
    String? description,
    String? level,
    String privacy = 'public',
  }) async {
    try {
      final body = <String, dynamic>{
        'award_name': awardName,
        'privacy': privacy,
      };
      if (awardingBody != null) body['awarding_body'] = awardingBody;
      if (dateReceived != null) body['date_received'] = dateReceived;
      if (description != null) body['description'] = description;
      if (level != null) body['level'] = level;

      final data = await _putRequest('/awards/$id', body);
      return ApiResponse.success(
        AwardModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to update award: $e');
    }
  }

  Future<ApiResponse<bool>> deleteAward({required int id}) async {
    try {
      await _deleteRequest('/awards/$id');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to delete award: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  MEDICAL LICENSES CRUD
  // ═══════════════════════════════════════════════

  Future<ApiResponse<List<MedicalLicenseModel>>> getLicenses({
    required String userId,
  }) async {
    try {
      final data = await _getRequest('/licenses?user_id=$userId');
      final list = (data['data'] as List<dynamic>)
          .map((e) =>
              MedicalLicenseModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error('Failed to load licenses: $e');
    }
  }

  Future<ApiResponse<MedicalLicenseModel>> storeLicense({
    required String licenseType,
    required String licenseNumber,
    required String issuingAuthority,
    required String issueDate,
    String? expiryDate,
    String privacy = 'public',
  }) async {
    try {
      final body = <String, String>{
        'license_type': licenseType,
        'license_number': licenseNumber,
        'issuing_authority': issuingAuthority,
        'issue_date': issueDate,
        'privacy': privacy,
      };
      if (expiryDate != null) body['expiry_date'] = expiryDate;

      final data = await _postRequest('/licenses', body);
      return ApiResponse.success(
        MedicalLicenseModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to add license: $e');
    }
  }

  Future<ApiResponse<MedicalLicenseModel>> updateLicense({
    required int id,
    required String licenseType,
    required String licenseNumber,
    required String issuingAuthority,
    required String issueDate,
    String? expiryDate,
    String privacy = 'public',
  }) async {
    try {
      final body = <String, dynamic>{
        'license_type': licenseType,
        'license_number': licenseNumber,
        'issuing_authority': issuingAuthority,
        'issue_date': issueDate,
        'privacy': privacy,
      };
      if (expiryDate != null) body['expiry_date'] = expiryDate;

      final data = await _putRequest('/licenses/$id', body);
      return ApiResponse.success(
        MedicalLicenseModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to update license: $e');
    }
  }

  Future<ApiResponse<bool>> deleteLicense({required int id}) async {
    try {
      await _deleteRequest('/licenses/$id');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to delete license: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  SOCIAL PROFILES CRUD
  // ═══════════════════════════════════════════════

  Future<ApiResponse<List<SocialProfileModel>>> getSocialProfiles({
    required String userId,
  }) async {
    try {
      final data = await _getRequest('/social-profiles?user_id=$userId');
      final list = (data['data'] as List<dynamic>)
          .map((e) =>
              SocialProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error('Failed to load social profiles: $e');
    }
  }

  Future<ApiResponse<SocialProfileModel>> storeSocialProfile({
    required String platform,
    required String profileUrl,
    String? username,
    bool isPublic = true,
  }) async {
    try {
      final body = <String, String>{
        'platform': platform,
        'profile_url': profileUrl,
        'is_public': isPublic ? '1' : '0',
      };
      if (username != null) body['username'] = username;

      final data = await _postRequest('/social-profiles', body);
      return ApiResponse.success(
        SocialProfileModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to add social profile: $e');
    }
  }

  Future<ApiResponse<SocialProfileModel>> updateSocialProfile({
    required int id,
    required String platform,
    required String profileUrl,
    String? username,
    bool isPublic = true,
  }) async {
    try {
      final body = <String, dynamic>{
        'platform': platform,
        'profile_url': profileUrl,
        'is_public': isPublic,
      };
      if (username != null) body['username'] = username;

      final data = await _putRequest('/social-profiles/$id', body);
      return ApiResponse.success(
        SocialProfileModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to update social profile: $e');
    }
  }

  Future<ApiResponse<bool>> deleteSocialProfile({required int id}) async {
    try {
      await _deleteRequest('/social-profiles/$id');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to delete social profile: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  BUSINESS HOURS CRUD
  // ═══════════════════════════════════════════════

  Future<ApiResponse<List<BusinessHourModel>>> getBusinessHours({
    required String userId,
  }) async {
    try {
      final data = await _getRequest('/business-hours?user_id=$userId');
      final List<BusinessHourModel> allHours = [];
      final rawData = data['data'] as List<dynamic>;

      for (final item in rawData) {
        final itemMap = item as Map<String, dynamic>;
        // Handle grouped format: { location_name, hours: [...] }
        if (itemMap.containsKey('hours') && itemMap['hours'] is List) {
          for (final hour in (itemMap['hours'] as List<dynamic>)) {
            allHours.add(BusinessHourModel.fromJson(hour as Map<String, dynamic>));
          }
        } else {
          // Handle flat format: individual business hour objects
          allHours.add(BusinessHourModel.fromJson(itemMap));
        }
      }
      return ApiResponse.success(allHours);
    } catch (e) {
      return ApiResponse.error('Failed to load business hours: $e');
    }
  }

  Future<ApiResponse<BusinessHourModel>> storeBusinessHour({
    required String locationName,
    String? locationAddress,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    bool isAvailable = true,
    String? notes,
  }) async {
    try {
      final body = <String, String>{
        'location_name': locationName,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_available': isAvailable ? '1' : '0',
      };
      if (locationAddress != null) body['location_address'] = locationAddress;
      if (notes != null) body['notes'] = notes;

      final data = await _postRequest('/business-hours', body);
      return ApiResponse.success(
        BusinessHourModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to add business hours: $e');
    }
  }

  Future<ApiResponse<BusinessHourModel>> updateBusinessHour({
    required dynamic id,
    required String locationName,
    String? locationAddress,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    bool isAvailable = true,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'location_name': locationName,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_available': isAvailable,
      };
      if (locationAddress != null) body['location_address'] = locationAddress;
      if (notes != null) body['notes'] = notes;

      final data = await _putRequest('/business-hours/$id', body);
      return ApiResponse.success(
        BusinessHourModel.fromJson(data['data'] as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error('Failed to update business hours: $e');
    }
  }

  Future<ApiResponse<bool>> deleteBusinessHour({required dynamic id}) async {
    try {
      await _deleteRequest('/business-hours/$id');
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to delete business hours: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  HOBBIES & INTERESTS
  // ═══════════════════════════════════════════════

  /// Get all interests (key-value map: interest_type -> interest_details)
  Future<ApiResponse<Map<String, dynamic>>> getInterests({String? userId}) async {
    try {
      final userParam = userId != null ? '?user_id=$userId' : '';
      // Legacy interests are at /interests-legacy on v5 (CRUD interests took /interests)
      // On v4, use /interests-v5 suffix to avoid collision with old v4 controller
      final response = await _tryRequest((baseUrl) {
        final isV4 = baseUrl.contains('/v4');
        final path = isV4 ? '/interests-v5$userParam' : '/interests-legacy$userParam';
        return http.get(Uri.parse('$baseUrl$path'), headers: _headers());
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ApiResponse.success(Map<String, dynamic>.from(data['data'] ?? {}));
        }
      }
      return ApiResponse.error('Failed to load interests');
    } catch (e) {
      return ApiResponse.error('Failed to load interests: $e');
    }
  }

  /// Save all interests at once (7 predefined types)
  Future<ApiResponse<Map<String, dynamic>>> saveInterests({
    String? hobbies,
    String? favtTvShows,
    String? favtMovies,
    String? favtGames,
    String? favtMusicBands,
    String? favtBooks,
    String? favtWriters,
    String? privacy,
  }) async {
    try {
      final body = {
        'hobbies': hobbies ?? '',
        'favt_tv_shows': favtTvShows ?? '',
        'favt_movies': favtMovies ?? '',
        'favt_games': favtGames ?? '',
        'favt_music_bands': favtMusicBands ?? '',
        'favt_books': favtBooks ?? '',
        'favt_writers': favtWriters ?? '',
        if (privacy != null) 'privacy': privacy,
      };
      // Legacy interests at /interests-legacy on v5 (CRUD interests took /interests)
      final response = await _tryRequest((baseUrl) {
        final isV4 = baseUrl.contains('/v4');
        final path = isV4 ? '/interests-v5' : '/interests-legacy';
        return http.post(Uri.parse('$baseUrl$path'), headers: _headers(), body: body);
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return ApiResponse.success(Map<String, dynamic>.from(data['data'] ?? {}));
        }
        return ApiResponse.error(data['message']?.toString() ?? 'Failed to save interests');
      }
      return ApiResponse.error('Failed to save interests: ${response.statusCode}');
    } catch (e) {
      return ApiResponse.error('Failed to save interests: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  HOBBIES — Card-Based CRUD (user_hobbies table)
  // ═══════════════════════════════════════════════

  /// Get all hobbies for a user
  Future<ApiResponse<List<Map<String, dynamic>>>> getHobbies({String? userId}) async {
    try {
      final param = userId != null ? '?user_id=$userId' : '';
      final data = await _getRequest('/hobbies$param');
      if (data['success'] == true) {
        final list = (data['data'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        return ApiResponse.success(list);
      }
      return ApiResponse.error('Failed to load hobbies');
    } catch (e) {
      return ApiResponse.error('Failed to load hobbies: $e');
    }
  }

  /// Create a new hobby
  Future<ApiResponse<Map<String, dynamic>>> storeHobby({
    required String name,
    String? description,
    String? privacy,
  }) async {
    try {
      final data = await _postRequest('/hobbies', {
        'name': name,
        if (description != null) 'description': description,
        'privacy': privacy ?? 'public',
      });
      if (data['success'] == true) {
        return ApiResponse.success(Map<String, dynamic>.from(data['data'] ?? {}));
      }
      return ApiResponse.error(data['message']?.toString() ?? 'Failed to add hobby');
    } catch (e) {
      return ApiResponse.error('Failed to add hobby: $e');
    }
  }

  /// Update an existing hobby
  Future<ApiResponse<Map<String, dynamic>>> updateHobby({
    required dynamic id,
    required String name,
    String? description,
    String? privacy,
  }) async {
    try {
      final data = await _putRequest('/hobbies/$id', {
        'name': name,
        'description': description ?? '',
        'privacy': privacy ?? 'public',
      });
      if (data['success'] == true) {
        return ApiResponse.success(Map<String, dynamic>.from(data['data'] ?? {}));
      }
      return ApiResponse.error(data['message']?.toString() ?? 'Failed to update hobby');
    } catch (e) {
      return ApiResponse.error('Failed to update hobby: $e');
    }
  }

  /// Delete a hobby
  Future<ApiResponse<bool>> deleteHobby({required dynamic id}) async {
    try {
      final data = await _deleteRequest('/hobbies/$id');
      if (data['success'] == true) {
        return ApiResponse.success(true);
      }
      return ApiResponse.error(data['message']?.toString() ?? 'Failed to delete hobby');
    } catch (e) {
      return ApiResponse.error('Failed to delete hobby: $e');
    }
  }

  // ═══════════════════════════════════════════════
  //  INTERESTS — Card-Based CRUD (user_interests table)
  // ═══════════════════════════════════════════════

  /// Get all interests for a user
  Future<ApiResponse<List<Map<String, dynamic>>>> getUserInterests({String? userId}) async {
    try {
      final param = userId != null ? '?user_id=$userId' : '';
      final data = await _getRequest('/interests$param');
      if (data['success'] == true) {
        final list = (data['data'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        return ApiResponse.success(list);
      }
      return ApiResponse.error('Failed to load interests');
    } catch (e) {
      return ApiResponse.error('Failed to load interests: $e');
    }
  }

  /// Create a new interest
  Future<ApiResponse<Map<String, dynamic>>> storeInterest({
    required String name,
    String? description,
    String? privacy,
  }) async {
    try {
      final data = await _postRequest('/interests', {
        'name': name,
        if (description != null) 'description': description,
        'privacy': privacy ?? 'public',
      });
      if (data['success'] == true) {
        return ApiResponse.success(Map<String, dynamic>.from(data['data'] ?? {}));
      }
      return ApiResponse.error(data['message']?.toString() ?? 'Failed to add interest');
    } catch (e) {
      return ApiResponse.error('Failed to add interest: $e');
    }
  }

  /// Update an existing interest
  Future<ApiResponse<Map<String, dynamic>>> updateInterest({
    required dynamic id,
    required String name,
    String? description,
    String? privacy,
  }) async {
    try {
      final data = await _putRequest('/interests/$id', {
        'name': name,
        'description': description ?? '',
        'privacy': privacy ?? 'public',
      });
      if (data['success'] == true) {
        return ApiResponse.success(Map<String, dynamic>.from(data['data'] ?? {}));
      }
      return ApiResponse.error(data['message']?.toString() ?? 'Failed to update interest');
    } catch (e) {
      return ApiResponse.error('Failed to update interest: $e');
    }
  }

  /// Delete an interest
  Future<ApiResponse<bool>> deleteInterest({required dynamic id}) async {
    try {
      final data = await _deleteRequest('/interests/$id');
      if (data['success'] == true) {
        return ApiResponse.success(true);
      }
      return ApiResponse.error(data['message']?.toString() ?? 'Failed to delete interest');
    } catch (e) {
      return ApiResponse.error('Failed to delete interest: $e');
    }
  }
}
