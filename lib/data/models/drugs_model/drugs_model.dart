import 'dart:convert';
DrugsModel drugsModelFromJson(String str) => DrugsModel.fromJson(json.decode(str));
String drugsModelToJson(DrugsModel data) => json.encode(data.toJson());
class DrugsModel {
  DrugsModel({
      this.data,});

  DrugsModel.fromJson(dynamic json) {
    data = json['data'] != null ? DrugsData.fromJson(json['data']) : null;
  }
  DrugsData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}


class DrugsData {
  DrugsData({
      this.currentPage, 
      this.data, 
      this.firstPageUrl, 
      this.from, 
      this.lastPage, 
      this.lastPageUrl, 
      this.links, 
      this.nextPageUrl, 
      this.path, 
      this.perPage, 
      this.prevPageUrl, 
      this.to, 
      this.total,});

  DrugsData.fromJson(dynamic json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Data.fromJson(v));
      });
    }
    firstPageUrl = json['first_page_url'];
    from = json['from'];
    lastPage = json['last_page'];
    lastPageUrl = json['last_page_url'];
    if (json['links'] != null) {
      links = [];
      json['links'].forEach((v) {
        links?.add(Links.fromJson(v));
      });
    }
    nextPageUrl = json['next_page_url'];
    path = json['path'];
    perPage = json['per_page'];
    prevPageUrl = json['prev_page_url'];
    to = json['to'];
    total = json['total'];
  }
  int? currentPage;
  List<Data>? data;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  String? lastPageUrl;
  List<Links>? links;
  String? nextPageUrl;
  String? path;
  int? perPage;
  dynamic prevPageUrl;
  int? to;
  int? total;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['current_page'] = currentPage;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    map['first_page_url'] = firstPageUrl;
    map['from'] = from;
    map['last_page'] = lastPage;
    map['last_page_url'] = lastPageUrl;
    if (links != null) {
      map['links'] = links?.map((v) => v.toJson()).toList();
    }
    map['next_page_url'] = nextPageUrl;
    map['path'] = path;
    map['per_page'] = perPage;
    map['prev_page_url'] = prevPageUrl;
    map['to'] = to;
    map['total'] = total;
    return map;
  }

}

Links linksFromJson(String str) => Links.fromJson(json.decode(str));
String linksToJson(Links data) => json.encode(data.toJson());
class Links {
  Links({
      this.url, 
      this.label, 
      this.active,});

  Links.fromJson(dynamic json) {
    url = json['url'];
    label = json['label'];
    active = json['active'];
  }
  dynamic url;
  String? label;
  bool? active;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['url'] = url;
    map['label'] = label;
    map['active'] = active;
    return map;
  }

}

class Data {
  Data({
      this.id, 
      this.druglistId, 
      this.tradeName, 
      this.genericName, 
      this.strength, 
      this.packageSize, 
      this.mrp, 
      this.manufacturerName, 
      this.createdAt, 
      this.updatedAt,});

  Data.fromJson(dynamic json) {
    id = json['id'];
    druglistId = json['druglist_id'];
    tradeName = json['trade_name'];
    genericName = json['generic_name'];
    strength = json['strength'];
    packageSize = json['package_size'];
    mrp = json['mrp'];
    manufacturerName = json['manufacturer_name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  String? id;
  String? druglistId;
  String? tradeName;
  String? genericName;
  String? strength;
  String? packageSize;
  String? mrp;
  String? manufacturerName;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['druglist_id'] = druglistId;
    map['trade_name'] = tradeName;
    map['generic_name'] = genericName;
    map['strength'] = strength;
    map['package_size'] = packageSize;
    map['mrp'] = mrp;
    map['manufacturer_name'] = manufacturerName;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }

}