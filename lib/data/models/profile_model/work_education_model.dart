class WorkEducationModel {
  int? id;
  String? userId;
  String? workType;
  String? name;
  String? position;
  String? address;
  String? startDate;
  String? endDate;
  String? currentStatus;
  String? degree;
  String? courses;
  String? description;
  String? createdAt;
  String? updatedAt;
  String? privacy;

  WorkEducationModel({
    this.id,
    this.userId,
    this.workType,
    this.name,
    this.position,
    this.address,
    this.startDate,
    this.endDate,
    this.currentStatus,
    this.degree,
    this.courses,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.privacy,
  });

  factory WorkEducationModel.fromJson(Map<String, dynamic> json) {
    return WorkEducationModel(
      id: json['id'] as int?,
      userId: json['user_id'] as String?,
      workType: json['work_type'] as String?,
      name: json['name'] as String?,
      position: json['position'] as String?,
      address: json['address'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      currentStatus: json['current_status'] as String?,
      degree: json['degree'] as String?,
      courses: json['courses'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      privacy: json['privacy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'work_type': workType,
      'name': name,
      'position': position,
      'address': address,
      'start_date': startDate,
      'end_date': endDate,
      'current_status': currentStatus,
      'degree': degree,
      'courses': courses,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'privacy': privacy,
    };
  }
}
