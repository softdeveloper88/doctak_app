class GetMeetingModel {
  final List<FetchingMeetingModel> getMeetingModelList;

  GetMeetingModel({required this.getMeetingModelList});

  factory GetMeetingModel.fromJson(List<dynamic> json) {
    return GetMeetingModel(
      getMeetingModelList: json.map((e) => FetchingMeetingModel.fromJson(e)).toList(),
    );
  }
}
class FetchingMeetingModel {
  final String date;
  final List<Session> sessions;

  FetchingMeetingModel({required this.date, required this.sessions});

  factory FetchingMeetingModel.fromJson(Map<String, dynamic> json) {
    return FetchingMeetingModel(
      date: json['date'],
      sessions: (json['sessions'] as List)
          .map((session) => Session.fromJson(session))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'sessions': sessions.map((session) => session.toJson()).toList(),
    };
  }
}

class Session {
  final String time;
  final String title;
  final int id;
  final String channel;
  final String image;

  Session({
    required this.time,
    required this.title,
    required this.id,
    required this.channel,
    required this.image,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      time: json['time'],
      title: json['title'],
      id: json['id'],
      channel: json['channel'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'title': title,
      'id': id,
      'channel': channel,
      'image': image,
    };
  }
}
