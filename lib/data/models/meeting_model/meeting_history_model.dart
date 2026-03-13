class MeetingHistoryResponse {
  final bool success;
  final List<MeetingHistoryItem> data;
  final MeetingHistoryPagination pagination;

  MeetingHistoryResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory MeetingHistoryResponse.fromJson(Map<String, dynamic> json) {
    return MeetingHistoryResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => MeetingHistoryItem.fromJson(e))
              .toList() ??
          [],
      pagination: MeetingHistoryPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class MeetingHistoryItem {
  final String id;
  final String title;
  final String meetingChannel;
  final String date;
  final String time;
  final int durationMinutes;
  final int participantsCount;
  final MeetingHistoryHost? host;
  final bool isHost;
  final String? createdAt;

  MeetingHistoryItem({
    required this.id,
    required this.title,
    required this.meetingChannel,
    required this.date,
    required this.time,
    required this.durationMinutes,
    required this.participantsCount,
    this.host,
    required this.isHost,
    this.createdAt,
  });

  factory MeetingHistoryItem.fromJson(Map<String, dynamic> json) {
    return MeetingHistoryItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Meeting',
      meetingChannel: json['meeting_channel'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      durationMinutes: (json['duration_minutes'] is int)
          ? json['duration_minutes']
          : int.tryParse(json['duration_minutes']?.toString() ?? '') ?? 0,
      participantsCount: (json['participants_count'] is int)
          ? json['participants_count']
          : int.tryParse(json['participants_count']?.toString() ?? '') ?? 0,
      host: json['host'] != null
          ? MeetingHistoryHost.fromJson(json['host'])
          : null,
      isHost: json['is_host'] ?? false,
      createdAt: json['created_at'],
    );
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h 0m';
    return '${minutes}m';
  }
}

class MeetingHistoryHost {
  final String id;
  final String name;
  final String? profilePic;

  MeetingHistoryHost({
    required this.id,
    required this.name,
    this.profilePic,
  });

  factory MeetingHistoryHost.fromJson(Map<String, dynamic> json) {
    return MeetingHistoryHost(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      profilePic: json['profile_pic'],
    );
  }
}

class MeetingHistoryPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  MeetingHistoryPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory MeetingHistoryPagination.fromJson(Map<String, dynamic> json) {
    return MeetingHistoryPagination(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
    );
  }
}
