import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:http/http.dart' as http;

class VerificationApiService {
  static final VerificationApiService _instance =
      VerificationApiService._internal();
  factory VerificationApiService() => _instance;
  VerificationApiService._internal();

  static String get _baseUrl => AppData.remoteUrlV6;

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${AppData.userToken}',
    'Accept': 'application/json',
  };

  /// GET /api/v6/verification/status
  Future<VerificationStatusResponse> getStatus() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/verification/status'),
      headers: _headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return VerificationStatusResponse.fromJson(body);
    }
    throw Exception(
      'Failed to get verification status: ${response.statusCode}',
    );
  }

  /// POST /api/v6/verification/submit
  Future<VerificationSubmitResponse> submit({
    required String fullName,
    String? professionalTitle,
    String? specialty,
    String? licenseNumber,
    String? institution,
    String? country,
    String? reason,
    File? documentId,
    File? documentLicense,
    File? documentAdditional,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/verification/submit'),
    );

    request.headers.addAll(_headers);
    request.fields['full_name'] = fullName;
    if (professionalTitle != null) {
      request.fields['professional_title'] = professionalTitle;
    }
    if (specialty != null) request.fields['specialty'] = specialty;
    if (licenseNumber != null) {
      request.fields['license_number'] = licenseNumber;
    }
    if (institution != null) request.fields['institution'] = institution;
    if (country != null) request.fields['country'] = country;
    if (reason != null) request.fields['reason'] = reason;

    if (documentId != null) {
      request.files.add(
        await http.MultipartFile.fromPath('document_id', documentId.path),
      );
    }
    if (documentLicense != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'document_license',
          documentLicense.path,
        ),
      );
    }
    if (documentAdditional != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'document_additional',
          documentAdditional.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return VerificationSubmitResponse.fromJson(body, response.statusCode);
  }
}

class VerificationStatusResponse {
  final bool isVerified;
  final bool hasPending;
  final VerificationRequestInfo? latestRequest;

  const VerificationStatusResponse({
    required this.isVerified,
    required this.hasPending,
    this.latestRequest,
  });

  factory VerificationStatusResponse.fromJson(Map<String, dynamic> json) {
    return VerificationStatusResponse(
      isVerified: json['is_verified'] == true,
      hasPending: json['has_pending'] == true,
      latestRequest: json['latest_request'] != null
          ? VerificationRequestInfo.fromJson(json['latest_request'])
          : null,
    );
  }
}

class VerificationRequestInfo {
  final int id;
  final String status;
  final String? fullName;
  final String? professionalTitle;
  final String? specialty;
  final String? licenseNumber;
  final String? institution;
  final String? country;
  final String? reason;
  final String? adminNotes;
  final String? createdAt;
  final String? reviewedAt;

  const VerificationRequestInfo({
    required this.id,
    required this.status,
    this.fullName,
    this.professionalTitle,
    this.specialty,
    this.licenseNumber,
    this.institution,
    this.country,
    this.reason,
    this.adminNotes,
    this.createdAt,
    this.reviewedAt,
  });

  factory VerificationRequestInfo.fromJson(Map<String, dynamic> json) {
    return VerificationRequestInfo(
      id: json['id'] as int,
      status: json['status'] as String,
      fullName: json['full_name'] as String?,
      professionalTitle: json['professional_title'] as String?,
      specialty: json['specialty'] as String?,
      licenseNumber: json['license_number'] as String?,
      institution: json['institution'] as String?,
      country: json['country'] as String?,
      reason: json['reason'] as String?,
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
    );
  }
}

class VerificationSubmitResponse {
  final bool success;
  final String message;
  final int statusCode;

  const VerificationSubmitResponse({
    required this.success,
    required this.message,
    required this.statusCode,
  });

  factory VerificationSubmitResponse.fromJson(
    Map<String, dynamic> json,
    int statusCode,
  ) {
    return VerificationSubmitResponse(
      success: json['success'] == true,
      message: json['message'] as String? ?? '',
      statusCode: statusCode,
    );
  }
}
