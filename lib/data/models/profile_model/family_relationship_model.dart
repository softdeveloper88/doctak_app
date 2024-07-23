import 'dart:convert';

FamilyRelationshipModel familyRelationshipModelFromJson(String str) =>
    FamilyRelationshipModel.fromJson(json.decode(str));
String familyRelationshipModelToJson(FamilyRelationshipModel data) =>
    json.encode(data.toJson());

class FamilyRelationshipModel {
  FamilyRelationshipModel({
    this.id,
    this.userId,
    this.familyMemberId,
    this.relationshipId,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  FamilyRelationshipModel.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    familyMemberId = json['family_member_id'];
    relationshipId = json['relationship_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  int? id;
  String? userId;
  String? familyMemberId;
  String? relationshipId;
  String? status;
  dynamic createdAt;
  dynamic updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['family_member_id'] = familyMemberId;
    map['relationship_id'] = relationshipId;
    map['status'] = status;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}
