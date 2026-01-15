import 'dart:convert';

InterestModel interestModelFromJson(String str) => InterestModel.fromJson(json.decode(str));
String interestModelToJson(InterestModel data) => json.encode(data.toJson());

class InterestModel {
  InterestModel({this.id, this.userId, this.interestType, this.interestDetails, this.createdAt, this.updatedAt});

  InterestModel.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    interestType = json['interest_type'];
    interestDetails = json['interest_details'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  int? id;
  String? userId;
  String? interestType;
  String? interestDetails;
  dynamic createdAt;
  dynamic updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['interest_type'] = interestType;
    map['interest_details'] = interestDetails;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}
