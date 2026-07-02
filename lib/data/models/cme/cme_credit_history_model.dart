class CmeCreditHistoryItem {
  CmeCreditHistoryItem({
    required this.id,
    this.eventId,
    required this.eventTitle,
    required this.credits,
    this.creditType,
    this.accreditationBody,
    this.earnedAt,
    this.certificateId,
  });

  factory CmeCreditHistoryItem.fromJson(Map<String, dynamic> json) {
    return CmeCreditHistoryItem(
      id: '${json['id'] ?? ''}',
      eventId: json['eventId']?.toString(),
      eventTitle: '${json['eventTitle'] ?? 'CME Credit'}',
      credits: _asDouble(json['credits']),
      creditType: json['creditType'] as String?,
      accreditationBody: json['accreditationBody'] as String?,
      earnedAt: json['earnedAt'] as String?,
      certificateId: json['certificateId']?.toString(),
    );
  }

  final String id;
  final String? eventId;
  final String eventTitle;
  final double credits;
  final String? creditType;
  final String? accreditationBody;
  final String? earnedAt;
  final String? certificateId;

  static double _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}
