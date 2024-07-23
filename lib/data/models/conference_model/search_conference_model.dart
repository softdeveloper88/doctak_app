import 'dart:convert';

SearchConferenceModel searchConferenceModelFromJson(String str) =>
    SearchConferenceModel.fromJson(json.decode(str));
String searchConferenceModelToJson(SearchConferenceModel data) =>
    json.encode(data.toJson());

class SearchConferenceModel {
  SearchConferenceModel({
    this.conferences,
  });

  SearchConferenceModel.fromJson(dynamic json) {
    conferences = json['conferences'] != null
        ? Conferences.fromJson(json['conferences'])
        : null;
  }
  Conferences? conferences;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (conferences != null) {
      map['conferences'] = conferences?.toJson();
    }
    return map;
  }
}

Conferences conferencesFromJson(String str) =>
    Conferences.fromJson(json.decode(str));
String conferencesToJson(Conferences data) => json.encode(data.toJson());

class Conferences {
  Conferences({
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
    this.total,
  });

  Conferences.fromJson(dynamic json) {
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
    this.active,
  });

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
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.city,
    this.state,
    this.country,
    this.venue,
    this.organizer,
    this.cmeCredits,
    this.mocCredits,
    this.specialtiesTargeted,
    this.registrationLink,
    this.conferenceAgendaLink,
    this.earlyBirdPrice,
    this.regularPrice,
    this.latePrice,
    this.accommodationDetails,
    this.speakers,
    this.sponsors,
    this.email,
    this.phoneNo,
    this.keywords,
    this.thumbnail,
    this.conferenceStatus,
    this.additianalNotes,
    this.createdAt,
    this.updatedAt,
  });

  Data.fromJson(dynamic json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    city = json['city'];
    state = json['state'];
    country = json['country'];
    venue = json['venue'];
    organizer = json['organizer'];
    cmeCredits = json['cme_credits'];
    mocCredits = json['moc_credits'];
    specialtiesTargeted = json['specialties_targeted'];
    registrationLink = json['registration_link'];
    conferenceAgendaLink = json['conference_agenda_link'];
    earlyBirdPrice = json['early_bird_price'];
    regularPrice = json['regular_price'];
    latePrice = json['late_price'];
    accommodationDetails = json['accommodationDetails'];
    speakers = json['speakers'];
    sponsors = json['sponsors'];
    email = json['email'];
    phoneNo = json['phone_no'];
    keywords = json['keywords'];
    thumbnail = json['thumbnail'];
    conferenceStatus = json['conference_status'];
    additianalNotes = json['additianal_notes'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  String? id;
  String? title;
  String? description;
  String? startDate;
  String? endDate;
  String? city;
  String? state;
  String? country;
  String? venue;
  String? organizer;
  String? cmeCredits;
  String? mocCredits;
  String? specialtiesTargeted;
  String? registrationLink;
  String? conferenceAgendaLink;
  String? earlyBirdPrice;
  String? regularPrice;
  String? latePrice;
  String? accommodationDetails;
  String? speakers;
  String? sponsors;
  String? email;
  String? phoneNo;
  String? keywords;
  String? thumbnail;
  String? conferenceStatus;
  String? additianalNotes;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['title'] = title;
    map['description'] = description;
    map['start_date'] = startDate;
    map['end_date'] = endDate;
    map['city'] = city;
    map['state'] = state;
    map['country'] = country;
    map['venue'] = venue;
    map['organizer'] = organizer;
    map['cme_credits'] = cmeCredits;
    map['moc_credits'] = mocCredits;
    map['specialties_targeted'] = specialtiesTargeted;
    map['registration_link'] = registrationLink;
    map['conference_agenda_link'] = conferenceAgendaLink;
    map['early_bird_price'] = earlyBirdPrice;
    map['regular_price'] = regularPrice;
    map['late_price'] = latePrice;
    map['accommodationDetails'] = accommodationDetails;
    map['speakers'] = speakers;
    map['sponsors'] = sponsors;
    map['email'] = email;
    map['phone_no'] = phoneNo;
    map['keywords'] = keywords;
    map['thumbnail'] = thumbnail;
    map['conference_status'] = conferenceStatus;
    map['additianal_notes'] = additianalNotes;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}
