import 'package:json_annotation/json_annotation.dart';

part 'work_education_model.g.dart';

@JsonSerializable()
class WorkEducationModel {
  int? id;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'work_type')
  String? workType;
  String? name;
  String? position;
  String? address;
  @JsonKey(name: 'start_date')
  String? startDate;
  @JsonKey(name: 'end_date')
  String? endDate;
  @JsonKey(name: 'current_status')
  String? currentStatus;
  String? degree;
  String? courses;
  String? description;
  @JsonKey(name: 'created_at')
  String? createdAt;
  @JsonKey(name: 'updated_at')
  String? updatedAt;
  @JsonKey(name: 'privacy')
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

  factory WorkEducationModel.fromJson(Map<String, dynamic> json) =>
      _$WorkEducationModelFromJson(json);

  Map<String, dynamic> toJson() => _$WorkEducationModelToJson(this);
}
