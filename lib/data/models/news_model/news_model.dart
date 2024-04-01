import 'dart:convert';
NewsModel newsModelFromJson(String str) => NewsModel.fromJson(json.decode(str));
String newsModelToJson(NewsModel data) => json.encode(data.toJson());
class NewsModel {
  NewsModel({
      this.title, 
      this.link, 
      this.description, 
      this.pubDate,});

  NewsModel.fromJson(dynamic json) {
    title = json['title'];
    link = json['link'];
    description = json['description'];
    pubDate = json['pubDate'];
  }
  String? title;
  String? link;
  String? description;
  String? pubDate;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['link'] = link;
    map['description'] = description;
    map['pubDate'] = pubDate;
    return map;
  }

}