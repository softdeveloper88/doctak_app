import 'dart:convert';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_environment.dart';

CmeCertificatesResponse cmeCertificatesResponseFromJson(String str) =>
    CmeCertificatesResponse.fromJson(json.decode(str));

class CmeCertificatesResponse {
  CmeCertificatesResponse({this.certificates});

  CmeCertificatesResponse.fromJson(dynamic json) {
    if (json['certificates'] != null) {
      certificates = [];
      if (json['certificates'] is List) {
        json['certificates'].forEach((v) {
          certificates?.add(CmeCertificateData.fromJson(v));
        });
      } else if (json['certificates']['data'] != null) {
        json['certificates']['data'].forEach((v) {
          certificates?.add(CmeCertificateData.fromJson(v));
        });
      }
    }
  }

  List<CmeCertificateData>? certificates;
}

class CmeCertificateData {
  CmeCertificateData({
    this.id,
    this.uuid,
    this.eventId,
    this.eventTitle,
    this.creditType,
    this.creditAmount,
    this.accreditationBody,
    this.certificateNumber,
    this.issuedDate,
    this.expiryDate,
    this.downloadUrl,
    this.verificationUrl,
    this.status,
    this.eventDate,
    this.eventType,
    this.thumbnail,
    this.recipientName,
    this.recipientSpecialty,
    this.providerName,
  });

  CmeCertificateData.fromJson(dynamic json) {
    id = json['id'];
    uuid = json['uuid'];
    eventId = json['event_id'];
    eventTitle = json['event_title'];
    creditType = json['credit_type'];
    creditAmount = json['credit_amount'];
    accreditationBody = json['accreditation_body'];
    certificateNumber = json['certificate_number'];
    issuedDate = json['issued_date'];
    expiryDate = json['expiry_date'];
    downloadUrl = json['download_url'];
    verificationUrl = json['verification_url'];
    status = json['status'];
    eventDate = json['event_date'];
    eventType = json['event_type'];
    thumbnail = json['thumbnail'];
  }

  String? id;
  String? uuid;
  String? eventId;
  String? eventTitle;
  String? creditType;
  dynamic creditAmount;
  String? accreditationBody;
  String? certificateNumber;
  String? issuedDate;
  String? expiryDate;
  String? downloadUrl;
  String? verificationUrl;
  String? status;
  String? eventDate;
  String? eventType;
  String? thumbnail;
  String? recipientName;
  String? recipientSpecialty;
  String? providerName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['uuid'] = uuid;
    map['event_id'] = eventId;
    map['event_title'] = eventTitle;
    map['credit_type'] = creditType;
    map['credit_amount'] = creditAmount;
    map['accreditation_body'] = accreditationBody;
    map['certificate_number'] = certificateNumber;
    map['issued_date'] = issuedDate;
    map['expiry_date'] = expiryDate;
    map['download_url'] = downloadUrl;
    map['verification_url'] = verificationUrl;
    map['status'] = status;
    map['event_date'] = eventDate;
    map['event_type'] = eventType;
    map['thumbnail'] = thumbnail;
    return map;
  }

  bool get isValid {
    if (status == 'expired' || status == 'invalid') return false;
    if (expiryDate != null) {
      final exp = DateTime.tryParse(expiryDate!);
      if (exp != null && exp.isBefore(DateTime.now())) return false;
    }
    // Node certificates omit status — treat as valid unless expired above.
    return status == null || status == 'valid' || status == 'active';
  }

  String get displayCredits {
    if (creditAmount == null) return '';
    return '${creditAmount} ${creditType ?? 'CME'}';
  }

  factory CmeCertificateData.fromNodeJson(Map<String, dynamic> json) {
    return CmeCertificateData(
      id: json['id']?.toString(),
      eventId: json['eventId']?.toString(),
      eventTitle: json['eventTitle'] as String?,
      eventType: json['eventType'] as String?,
      creditAmount: json['credits'],
      creditType: json['creditType'] as String?,
      issuedDate: json['issuedAt'] as String?,
      downloadUrl: _resolveAssetUrl(json['fileUrl'] as String?),
      verificationUrl: _resolveAssetUrl(json['viewUrl'] as String?),
      certificateNumber: json['certificateNumber'] as String?,
      status: 'valid',
    );
  }

  factory CmeCertificateData.fromNodeDetailJson(Map<String, dynamic> json) {
    return CmeCertificateData(
      id: json['id']?.toString(),
      eventId: json['eventId']?.toString(),
      eventTitle: json['eventTitle'] as String?,
      eventType: json['eventType'] as String?,
      creditAmount: json['credits'],
      creditType: json['creditType'] as String?,
      accreditationBody: json['accreditationBody'] as String?,
      issuedDate: json['issuedAt'] as String?,
      certificateNumber: json['certificateNumber'] as String?,
      recipientName: json['recipientName'] as String?,
      recipientSpecialty: json['recipientSpecialty'] as String?,
      providerName: json['providerName'] as String?,
      status: 'valid',
    );
  }

  static String? webViewUrl(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    return '${AppEnvironment.publicWebUrl}/cme/certificates/${id.trim()}';
  }

  static String? _resolveAssetUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final resolved = AppData.fullImageUrl(raw);
      return resolved.isEmpty ? raw : resolved;
    }
    if (raw.startsWith('/cme/') || raw.startsWith('/api/')) {
      final base = AppData.nodeApiUrl.endsWith('/')
          ? AppData.nodeApiUrl.substring(0, AppData.nodeApiUrl.length - 1)
          : AppData.nodeApiUrl;
      return '$base$raw';
    }
    final media = AppData.fullImageUrl(raw);
    return media.isEmpty ? raw : media;
  }
}

class CmeShareableCertificate {
  CmeShareableCertificate({
    this.id,
    this.certificateNumber,
    this.eventTitle,
    this.holderName,
    this.holderSpecialty,
    this.creditType,
    this.creditAmount,
    this.issueDate,
    this.expiryDate,
    this.downloadUrl,
    this.shareUrl,
    this.verificationUrl,
    this.qrCodeUrl,
    this.isValid,
    this.accreditationBody,
    this.providerName,
  });

  factory CmeShareableCertificate.fromJson(Map<String, dynamic> json) {
    return CmeShareableCertificate(
      id: json['id']?.toString(),
      certificateNumber: json['certificate_number'] as String? ?? json['certificateNumber'] as String?,
      eventTitle: json['event_title'] as String? ?? json['eventTitle'] as String? ?? json['event']?['title'] as String?,
      holderName: json['holder_name'] as String? ??
          json['recipientName'] as String? ??
          json['user']?['name'] as String?,
      holderSpecialty: json['holder_specialty'] as String? ??
          json['recipientSpecialty'] as String?,
      creditType: json['credit_type'] as String? ?? json['creditType'] as String?,
      creditAmount: (json['credit_amount'] as num?)?.toDouble() ??
          (json['credits'] as num?)?.toDouble(),
      issueDate: json['issue_date'] as String? ??
          json['issued_at'] as String? ??
          json['issuedAt'] as String?,
      expiryDate: json['expiry_date'] as String? ?? json['expires_at'] as String?,
      downloadUrl: json['download_url'] as String?,
      shareUrl: json['share_url'] as String?,
      verificationUrl: json['verification_url'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      isValid: json['is_valid'] as bool?,
      accreditationBody: json['accreditation_body'] as String? ?? json['accreditationBody'] as String?,
      providerName: json['provider_name'] as String? ?? json['providerName'] as String?,
    );
  }

  factory CmeShareableCertificate.fromCertificateData(CmeCertificateData cert) {
    final viewUrl = CmeCertificateData.webViewUrl(cert.id);
    return CmeShareableCertificate(
      id: cert.id,
      certificateNumber: cert.certificateNumber,
      eventTitle: cert.eventTitle,
      holderName: cert.recipientName,
      holderSpecialty: cert.recipientSpecialty,
      creditType: cert.creditType,
      creditAmount: cert.creditAmount is num
          ? (cert.creditAmount as num).toDouble()
          : double.tryParse('${cert.creditAmount}'),
      issueDate: cert.issuedDate,
      expiryDate: cert.expiryDate,
      downloadUrl: cert.downloadUrl,
      shareUrl: viewUrl,
      verificationUrl: viewUrl,
      isValid: cert.isValid,
      accreditationBody: cert.accreditationBody,
      providerName: cert.providerName,
    );
  }

  final String? id;
  final String? certificateNumber;
  final String? eventTitle;
  final String? holderName;
  final String? holderSpecialty;
  final String? creditType;
  final double? creditAmount;
  final String? issueDate;
  final String? expiryDate;
  final String? downloadUrl;
  final String? shareUrl;
  final String? verificationUrl;
  final String? qrCodeUrl;
  final bool? isValid;
  final String? accreditationBody;
  final String? providerName;
}
