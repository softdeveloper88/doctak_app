import 'dart:convert';
AdsTypeModel adsTypeModelFromJson(String str) => AdsTypeModel.fromJson(json.decode(str));
String adsTypeModelToJson(AdsTypeModel data) => json.encode(data.toJson());
class AdsTypeModel {
  AdsTypeModel({
      this.id, 
      this.type, 
      this.applicationId, 
      this.provider, 
      this.createdAt, 
      this.updatedAt, 
      this.advertisementId,
      this.androidId,
      this.iosId,
  });

  AdsTypeModel.fromJson(dynamic json) {
    id = json['id'];
    type = json['type'];
    applicationId = json['application_id'];
    provider = json['provider'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    advertisementId = json['advertisement_id'];
    androidId = json['android_id'];
    iosId = json['ios_id'];
  }
  String? id;
  String? type;
  String? applicationId;
  String? provider;
  String? createdAt;
  String? updatedAt;
  String? advertisementId;
  String? androidId;
  String? iosId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['type'] = type;
    map['application_id'] = applicationId;
    map['provider'] = provider;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['advertisement_id'] = advertisementId;
    map['android_id'] = androidId;
    map['ios_id'] = iosId;
    return map;
  }

}