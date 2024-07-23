import 'dart:convert';

CheckInSearchModel checkInSearchModelFromJson(String str) =>
    CheckInSearchModel.fromJson(json.decode(str));
String checkInSearchModelToJson(CheckInSearchModel data) =>
    json.encode(data.toJson());

class CheckInSearchModel {
  CheckInSearchModel({
    this.success,
    this.data,
  });

  CheckInSearchModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(PlaceData.fromJson(v));
      });
    }
  }
  bool? success;
  List<PlaceData>? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

PlaceData dataFromJson(String str) => PlaceData.fromJson(json.decode(str));
String dataToJson(PlaceData data) => json.encode(data.toJson());

class PlaceData {
  PlaceData({
    this.id,
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.website,
    this.contactPerson,
    this.category,
    this.specialty,
    this.openTime,
    this.closeTime,
    this.daysOfOperation,
    this.accessibiltyInformation,
    this.facilitiesAvailable,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  PlaceData.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    address = json['address'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    phone = json['phone'];
    email = json['email'];
    website = json['website'];
    contactPerson = json['contact_person'];
    category = json['category'];
    specialty = json['specialty'];
    openTime = json['open_time'];
    closeTime = json['close_time'];
    daysOfOperation = json['days_of_operation'];
    accessibiltyInformation = json['accessibilty_information'];
    facilitiesAvailable = json['facilities_available'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  int? id;
  String? name;
  dynamic address;
  dynamic latitude;
  dynamic longitude;
  dynamic phone;
  dynamic email;
  dynamic website;
  dynamic contactPerson;
  dynamic category;
  dynamic specialty;
  dynamic openTime;
  dynamic closeTime;
  dynamic daysOfOperation;
  dynamic accessibiltyInformation;
  dynamic facilitiesAvailable;
  dynamic description;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['address'] = address;
    map['latitude'] = latitude;
    map['longitude'] = longitude;
    map['phone'] = phone;
    map['email'] = email;
    map['website'] = website;
    map['contact_person'] = contactPerson;
    map['category'] = category;
    map['specialty'] = specialty;
    map['open_time'] = openTime;
    map['close_time'] = closeTime;
    map['days_of_operation'] = daysOfOperation;
    map['accessibilty_information'] = accessibiltyInformation;
    map['facilities_available'] = facilitiesAvailable;
    map['description'] = description;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}
