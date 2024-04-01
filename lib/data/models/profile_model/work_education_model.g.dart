// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_education_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkEducationModel _$WorkEducationModelFromJson(Map<String, dynamic> json) =>
    WorkEducationModel(
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
    );

Map<String, dynamic> _$WorkEducationModelToJson(WorkEducationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'work_type': instance.workType,
      'name': instance.name,
      'position': instance.position,
      'address': instance.address,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'current_status': instance.currentStatus,
      'degree': instance.degree,
      'courses': instance.courses,
      'description': instance.description,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
