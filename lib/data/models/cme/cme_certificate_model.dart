import 'dart:convert';

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

  bool get isValid =>
      status == 'valid' &&
      (expiryDate == null ||
          DateTime.tryParse(expiryDate!)?.isAfter(DateTime.now()) == true);

  String get displayCredits {
    if (creditAmount == null) return '';
    return '${creditAmount} ${creditType ?? 'CME'}';
  }
}
