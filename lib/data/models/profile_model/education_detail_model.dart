/// Model for Education (maps to education table with university relationship)
class EducationDetailModel {
  int? id;
  String? userId;
  String? degree;
  String? institution;
  String? fieldOfStudy;
  int? startYear;
  int? endYear;
  String? startDate;
  String? endDate;
  String? gpa;
  String? grade;
  String? honors;
  String? thesisTitle;
  String? description;
  String? location;
  String? specialization;
  String? activities;
  String? privacy;
  UniversityModel? university;
  String? createdAt;
  String? updatedAt;

  EducationDetailModel({
    this.id,
    this.userId,
    this.degree,
    this.institution,
    this.fieldOfStudy,
    this.startYear,
    this.endYear,
    this.startDate,
    this.endDate,
    this.gpa,
    this.grade,
    this.honors,
    this.thesisTitle,
    this.description,
    this.location,
    this.specialization,
    this.activities,
    this.privacy,
    this.university,
    this.createdAt,
    this.updatedAt,
  });

  factory EducationDetailModel.fromJson(Map<String, dynamic> json) {
    return EducationDetailModel(
      id: json['id'] as int?,
      userId: json['user_id']?.toString(),
      degree: json['degree'] as String?,
      institution: json['institution'] as String?,
      fieldOfStudy: json['field_of_study'] as String?,
      startYear: json['start_year'] is int
          ? json['start_year']
          : int.tryParse(json['start_year']?.toString() ?? ''),
      endYear: json['end_year'] is int
          ? json['end_year']
          : int.tryParse(json['end_year']?.toString() ?? ''),
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      gpa: json['gpa'] as String?,
      grade: json['grade'] as String?,
      honors: json['honors'] as String?,
      thesisTitle: json['thesis_title'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      specialization: json['specialization'] as String?,
      activities: json['activities'] as String?,
      privacy: json['privacy'] as String? ?? 'public',
      university: json['university'] != null
          ? UniversityModel.fromJson(json['university'])
          : null,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'degree': degree,
      'institution': institution,
      'field_of_study': fieldOfStudy,
      'start_year': startYear,
      'end_year': endYear,
      'current_study': isCurrentlyStudying,
      'gpa': gpa,
      'honors': honors,
      'thesis_title': thesisTitle,
      'description': description,
      'location': location,
      'specialization': specialization,
      'activities': activities,
      'privacy': privacy,
    };
  }

  bool get isCurrentlyStudying => endDate == 'Present' || endYear == null;

  String get displayYearRange {
    final start = startYear?.toString() ?? '';
    final end = isCurrentlyStudying ? 'Present' : (endYear?.toString() ?? '');
    if (start.isEmpty && end.isEmpty) return '';
    return '$start - $end';
  }

  String get displayInstitution =>
      university?.name ?? institution ?? '';
}

class UniversityModel {
  int? id;
  String? name;
  String? country;
  String? city;

  UniversityModel({this.id, this.name, this.country, this.city});

  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    return UniversityModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'city': city,
    };
  }
}
