import 'dart:convert';
JobsModel jobsModelFromJson(String str) => JobsModel.fromJson(json.decode(str));
String jobsModelToJson(JobsModel data) => json.encode(data.toJson());
class JobsModel {
  JobsModel({
      this.jobs,});

  JobsModel.fromJson(dynamic json) {
    jobs = json['jobs'] != null ? Jobs.fromJson(json['jobs']) : null;
  }
  Jobs? jobs;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (jobs != null) {
      map['jobs'] = jobs?.toJson();
    }
    return map;
  }

}

Jobs jobsFromJson(String str) => Jobs.fromJson(json.decode(str));
String jobsToJson(Jobs data) => json.encode(data.toJson());
class Jobs {
  Jobs({
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

  Jobs.fromJson(dynamic json) {
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
      this.id, 
      this.jobTitle, 
      this.companyName, 
      this.experience, 
      this.location, 
      this.description, 
      this.link, 
      this.createdAt, 
      this.updatedAt, 
      this.userId, 
      this.jobImage, 
      this.countryId, 
      this.lastDate, 
      this.applicants, 
      this.user, 
      this.specialties,});

  Data.fromJson(dynamic json) {
    id = json['id'];
    jobTitle = json['job_title'];
    companyName = json['company_name'];
    experience = json['experience'];
    location = json['location'];
    description = json['description'];
    link = json['link'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    userId = json['user_id'];
    jobImage = json['job_image'];
    countryId = json['country_id'];
    lastDate = json['last_date'];
    if (json['applicants'] != null) {
      applicants = [];
      json['applicants'].forEach((v) {
        applicants?.add(Application.fromJson(v));
      });
    }
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    if (json['specialties'] != null) {
      specialties = [];
      json['specialties'].forEach((v) {
        specialties?.add(Application.fromJson(v));
      });
    }
  }
  int? id;
  String? jobTitle;
  String? companyName;
  String? experience;
  String? location;
  String? description;
  String? link;
  String? createdAt;
  String? updatedAt;
  String? userId;
  String? jobImage;
  String? countryId;
  String? lastDate;
  List<dynamic>? applicants;
  User? user;
  List<dynamic>? specialties;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['job_title'] = jobTitle;
    map['company_name'] = companyName;
    map['experience'] = experience;
    map['location'] = location;
    map['description'] = description;
    map['link'] = link;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['user_id'] = userId;
    map['job_image'] = jobImage;
    map['country_id'] = countryId;
    map['last_date'] = lastDate;
    if (applicants != null) {
      map['applicants'] = applicants?.map((v) => v.toJson()).toList();
    }
    if (user != null) {
      map['user'] = user?.toJson();
    }
    if (specialties != null) {
      map['specialties'] = specialties?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Application applicationFromJson(String str) => Application.fromJson(json.decode(str));
String applicationToJson(Application data) => json.encode(data.toJson());
class Application {
  Application({
    this.id,});

  Application.fromJson(dynamic json) {
    id = json['id'];
    // name = json['name'];
    // profilePic = json['profile_pic'];
  }

  dynamic id;

  // String? name;
  // String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    // map['name'] = name;
    // map['profile_pic'] = profilePic;
    return map;
  }
}
User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());
class User {
  User({
      this.id, 
      this.name, 
      this.profilePic,});

  User.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    profilePic = json['profile_pic'];
  }
  String? id;
  String? name;
  String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    return map;
  }

}