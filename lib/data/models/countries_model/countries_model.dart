import 'dart:convert';
CountriesModel countriesModelFromJson(String str) => CountriesModel.fromJson(json.decode(str));
String countriesModelToJson(CountriesModel data) => json.encode(data.toJson());
class CountriesModel {
  CountriesModel({
      this.countries,});

  CountriesModel.fromJson(dynamic json) {
    if (json['countries'] != null) {
      countries = [];
      json['countries'].forEach((v) {
        countries?.add(Countries.fromJson(v));
      });
    }
  }
  List<Countries>? countries;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (countries != null) {
      map['countries'] = countries?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Countries countriesFromJson(String str) => Countries.fromJson(json.decode(str));
String countriesToJson(Countries data) => json.encode(data.toJson());
class Countries {
  Countries({
      this.id, 
      this.countryName, 
      this.createdAt, 
      this.updatedAt, 
      this.isRegistered, 
      this.countryCode, 
      this.countryMask, 
      this.currency,
      this.flag,
  });

  Countries.fromJson(dynamic json) {
    id = json['id'];
    countryName = json['countryName'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isRegistered = json['isRegistered'];
    countryCode = json['countryCode'];
    countryMask = json['countryMask'];
    currency = json['currency'];
    flag = json['flag'];
  }
  int? id;
  String? countryName;
  String? createdAt;
  String? updatedAt;
  String? isRegistered;
  String? countryCode;
  String? countryMask;
  String? currency;
  String? flag;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['countryName'] = countryName;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['isRegistered'] = isRegistered;
    map['countryCode'] = countryCode;
    map['countryMask'] = countryMask;
    map['currency'] = currency;
    map['flag'] = flag;
    return map;
  }
}