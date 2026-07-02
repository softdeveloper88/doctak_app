class GetMeetingModel {
  final List<FetchingMeetingModel> getMeetingModelList;
  final bool success;
  final int total;

  GetMeetingModel({required this.getMeetingModelList, this.success = true, this.total = 0});

  /// Accepts doctak-node shape: {success, meetings: [...], total}
  /// and old Laravel shape: List<{date, sessions: [...]}>
  factory GetMeetingModel.fromJson(dynamic json) {
    if (json is List) {
      // Old Laravel shape: list of {date, sessions}
      return GetMeetingModel(
        getMeetingModelList: json.map((e) => FetchingMeetingModel.fromJson(e)).toList(),
        success: true,
        total: json.length,
      );
    }
    // doctak-node shape: {success, meetings: [...], total}
    final meetings = (json['meetings'] as List?) ?? [];
    return GetMeetingModel(
      getMeetingModelList: [FetchingMeetingModel.fromScheduledList(meetings)],
      success: json['success'] == true,
      total: json['total'] ?? meetings.length,
    );
  }
}

class FetchingMeetingModel {
  final String date;
  final List<Session> sessions;

  FetchingMeetingModel({required this.date, required this.sessions});

  factory FetchingMeetingModel.fromJson(Map<String, dynamic> json) {
    return FetchingMeetingModel(
      date: json['date'] ?? '',
      sessions: (json['sessions'] as List?)?.map((session) => Session.fromJson(session)).toList() ?? [],
    );
  }

  /// Convert a flat list of scheduled meetings (doctak-node) into a single FetchingMeetingModel
  /// grouped under a single date entry (all sessions). Callers render by session.
  factory FetchingMeetingModel.fromScheduledList(List<dynamic> meetings) {
    return FetchingMeetingModel(
      date: meetings.isNotEmpty ? (meetings.first['date']?.toString() ?? '') : '',
      sessions: meetings.map((m) => Session.fromScheduled(m)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'sessions': sessions.map((session) => session.toJson()).toList()};
  }
}

class Session {
  final String time;
  final String title;
  final int id;
  final String channel;
  final String image;
  // Extra fields from doctak-node scheduled meetings
  final String? date;
  final String? description;
  final bool? isCmeMeeting;

  Session({required this.time, required this.title, required this.id, required this.channel, required this.image, this.date, this.description, this.isCmeMeeting});

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      time: json['time'] ?? '',
      title: json['title'] ?? json['name'] ?? 'Untitled',
      id: json['id'] ?? 0,
      channel: json['channel'] ?? '',
      image: json['image'] ?? '',
    );
  }

  /// Parse a doctak-node scheduled meeting object.
  factory Session.fromScheduled(Map<String, dynamic> json) {
    return Session(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] ?? json['name'] ?? 'Untitled',
      time: json['time']?.toString() ?? '',
      date: json['date']?.toString(),
      channel: json['channel']?.toString() ?? '',
      image: '',
      description: json['description']?.toString(),
      isCmeMeeting: json['isCmeMeeting'] == true || json['isCmeMeeting'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {'time': time, 'title': title, 'id': id, 'channel': channel, 'image': image};
  }
}
