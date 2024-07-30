import 'dart:convert';
CaseDiscussModel caseDiscussModelFromJson(String str) => CaseDiscussModel.fromJson(json.decode(str));
String caseDiscussModelToJson(CaseDiscussModel data) => json.encode(data.toJson());
class CaseDiscussModel {
  CaseDiscussModel({
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

  CaseDiscussModel.fromJson(dynamic json) {
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
  dynamic nextPageUrl;
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

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());
class Data {
  Data({
      this.caseId,
      this.title, 
      this.tags, 
      this.likes, 
      this.views, 
      this.createdAt, 
      this.name, 
      this.profilePic, 
      this.comments,});

  Data.fromJson(dynamic json) {
    caseId = json['case_id'];
    title = json['title'];
    tags = json['tags'];
    likes = json['likes'];
    views = json['views'];
    createdAt = json['created_at'];
    name = json['name'];
    profilePic = json['profile_pic'];
    comments = json['comments'];
  }
  int? caseId;
  String? title;
  dynamic tags;
  int? likes;
  int? views;
  String? createdAt;
  String? name;
  String? profilePic;
  int? comments;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['case_id'] = caseId;
    map['title'] = title;
    map['tags'] = tags;
    map['likes'] = likes;
    map['views'] = views;
    map['created_at'] = createdAt;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    map['comments'] = comments;
    return map;
  }

}