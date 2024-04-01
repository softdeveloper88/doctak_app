import 'dart:convert';
PlaceLiveModel placeLiveModelFromJson(String str) => PlaceLiveModel.fromJson(json.decode(str));
String placeLiveModelToJson(PlaceLiveModel data) => json.encode(data.toJson());
class PlaceLiveModel {
  PlaceLiveModel({
      this.id, 
      this.userId, 
      this.place, 
      this.description, 
      this.createdAt, 
      this.updatedAt,});

  PlaceLiveModel.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    place = json['place'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  int? id;
  String? userId;
  String? place;
  String? description;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['place'] = place;
    map['description'] = description;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }

}