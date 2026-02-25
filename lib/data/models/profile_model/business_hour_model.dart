/// Model for Business Hours (maps to doctor_business_hours table)
/// Note: Backend uses UUID primary keys for this table
class BusinessHourModel {
  String? id;
  String? userId;
  String? locationName;
  String? locationAddress;
  String? dayOfWeek;
  String? startTime;
  String? endTime;
  bool? isAvailable;
  String? notes;
  String? createdAt;
  String? updatedAt;

  BusinessHourModel({
    this.id,
    this.userId,
    this.locationName,
    this.locationAddress,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.isAvailable,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessHourModel.fromJson(Map<String, dynamic> json) {
    return BusinessHourModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      locationName: json['location_name'] as String?,
      locationAddress: json['location_address'] as String?,
      dayOfWeek: json['day_of_week'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      isAvailable: json['is_available'] is bool
          ? json['is_available']
          : (json['is_available'] == 1 || json['is_available'] == '1'),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_name': locationName,
      'location_address': locationAddress,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable == true ? 1 : 0,
      'notes': notes,
    };
  }

  String get displayDay {
    if (dayOfWeek == null) return '';
    return dayOfWeek![0].toUpperCase() + dayOfWeek!.substring(1);
  }

  String get displayTimeRange {
    if (startTime == null || endTime == null) return '';
    return '$startTime - $endTime';
  }

  static const List<String> weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
}

/// Grouped business hours by location (matches API response)
class BusinessLocationGroup {
  String? locationName;
  String? locationAddress;
  List<BusinessHourModel> hours;

  BusinessLocationGroup({
    this.locationName,
    this.locationAddress,
    this.hours = const [],
  });

  factory BusinessLocationGroup.fromJson(Map<String, dynamic> json) {
    return BusinessLocationGroup(
      locationName: json['location_name'] as String?,
      locationAddress: json['location_address'] as String?,
      hours: (json['hours'] as List<dynamic>?)
              ?.map((e) => BusinessHourModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
