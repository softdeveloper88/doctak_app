import 'dart:convert';

AdsSettingModel adsSettingModelFromJson(String str) => AdsSettingModel.fromJson(json.decode(str));
String adsSettingModelToJson(AdsSettingModel data) => json.encode(data.toJson());

class AdsSettingModel {
  AdsSettingModel({this.success, this.data});

  AdsSettingModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Data.fromJson(v));
      });
    }
  }
  bool? success;
  List<Data>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());

class Data {
  Data({this.id, this.userId, this.advertisementType, this.deviceType, this.isPaid, this.provider, this.isAdvertisementOn});

  Data.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    advertisementType = json['advertisement_type'];
    deviceType = json['device_type'];
    isPaid = json['is_paid'];
    provider = json['provider'];
    isAdvertisementOn = json['is_advertisement_on'];
  }
  int? id;
  String? userId;
  String? advertisementType;
  dynamic deviceType;
  dynamic isPaid;
  String? provider;
  dynamic isAdvertisementOn;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['advertisement_type'] = advertisementType;
    map['device_type'] = deviceType;
    map['is_paid'] = isPaid;
    map['provider'] = provider;
    map['is_advertisement_on'] = isAdvertisementOn;
    return map;
  }
}
