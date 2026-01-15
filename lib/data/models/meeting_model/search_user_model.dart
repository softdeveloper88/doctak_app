import 'dart:convert';

SearchUserModel searchUserModelFromJson(String str) => SearchUserModel.fromJson(json.decode(str));
String searchUserModelToJson(SearchUserModel data) => json.encode(data.toJson());

class SearchUserModel {
  SearchUserModel({this.success, this.data, this.pagination});

  SearchUserModel.fromJson(dynamic json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(SearchData.fromJson(v));
      });
    }
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
  }
  bool? success;
  List<SearchData>? data;
  Pagination? pagination;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    return map;
  }
}

Pagination paginationFromJson(String str) => Pagination.fromJson(json.decode(str));
String paginationToJson(Pagination data) => json.encode(data.toJson());

class Pagination {
  Pagination({this.currentPage, this.perPage, this.total, this.lastPage, this.nextPageUrl, this.prevPageUrl});

  Pagination.fromJson(dynamic json) {
    currentPage = json['current_page'];
    perPage = json['per_page'];
    total = json['total'];
    lastPage = json['last_page'];
    nextPageUrl = json['next_page_url'];
    prevPageUrl = json['prev_page_url'];
  }
  int? currentPage;
  int? perPage;
  int? total;
  int? lastPage;
  String? nextPageUrl;
  dynamic prevPageUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['current_page'] = currentPage;
    map['per_page'] = perPage;
    map['total'] = total;
    map['last_page'] = lastPage;
    map['next_page_url'] = nextPageUrl;
    map['prev_page_url'] = prevPageUrl;
    return map;
  }
}

SearchData dataFromJson(String str) => SearchData.fromJson(json.decode(str));
String dataToJson(SearchData data) => json.encode(data.toJson());

class SearchData {
  SearchData({this.id, this.firstName, this.lastName, this.specialty, this.profilePic});

  SearchData.fromJson(dynamic json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    specialty = json['specialty'];
    profilePic = json['profile_pic'];
  }
  String? id;
  String? firstName;
  String? lastName;
  String? specialty;
  String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['specialty'] = specialty;
    map['profile_pic'] = profilePic;
    return map;
  }
}
