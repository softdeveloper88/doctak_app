/// Model for Medical Licenses (maps to medical_licenses table)
class MedicalLicenseModel {
  int? id;
  String? userId;
  String? licenseType;
  String? licenseNumber;
  String? issuingAuthority;
  String? issueDate;
  String? expiryDate;
  String? privacy;
  String? createdAt;
  String? updatedAt;

  MedicalLicenseModel({
    this.id,
    this.userId,
    this.licenseType,
    this.licenseNumber,
    this.issuingAuthority,
    this.issueDate,
    this.expiryDate,
    this.privacy,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicalLicenseModel.fromJson(Map<String, dynamic> json) {
    return MedicalLicenseModel(
      id: json['id'] as int?,
      userId: json['user_id']?.toString(),
      licenseType: json['license_type'] as String?,
      licenseNumber: json['license_number'] as String?,
      issuingAuthority: json['issuing_authority'] as String?,
      issueDate: json['issue_date'] as String?,
      expiryDate: json['expiry_date'] as String?,
      privacy: json['privacy'] as String? ?? 'public',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'license_type': licenseType,
      'license_number': licenseNumber,
      'issuing_authority': issuingAuthority,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'privacy': privacy,
    };
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    try {
      return DateTime.parse(expiryDate!).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}
