import 'dart:convert';

CmeDashboardResponse cmeDashboardResponseFromJson(String str) =>
    CmeDashboardResponse.fromJson(json.decode(str));

class CmeDashboardResponse {
  CmeDashboardResponse({
    this.totalCredits,
    this.creditsThisYear,
    this.eventsAttended,
    this.eventsRegistered,
    this.upcomingEvents,
    this.certificatesEarned,
    this.complianceStatus,
    this.creditBreakdown,
    this.recentActivity,
  });

  CmeDashboardResponse.fromJson(dynamic json) {
    totalCredits = json['total_credits'] ?? json['totalCredits'];
    creditsThisYear = json['credits_this_year'] ?? json['creditsThisYear'];
    eventsAttended = json['events_attended'] ?? json['eventsAttended'];
    eventsRegistered = json['events_registered'] ?? json['eventsRegistered'];
    upcomingEvents = json['upcoming_events'] ?? json['upcomingEvents'];
    certificatesEarned = json['certificates_earned'] ?? json['certificatesEarned'];
    complianceStatus = json['compliance_status'] ?? json['complianceStatus'];
    if (json['nav_counts'] != null || json['navCounts'] != null) {
      navCounts = CmeNavCounts.fromJson(json['nav_counts'] ?? json['navCounts']);
    }
    if (json['provider_counts'] != null || json['providerCounts'] != null) {
      providerCounts =
          CmeProviderCounts.fromJson(json['provider_counts'] ?? json['providerCounts']);
    }
    if (json['credit_breakdown'] != null) {
      creditBreakdown = [];
      json['credit_breakdown'].forEach((v) {
        creditBreakdown?.add(CmeCreditBreakdown.fromJson(v));
      });
    }
    if (json['recent_activity'] != null) {
      recentActivity = [];
      json['recent_activity'].forEach((v) {
        recentActivity?.add(CmeRecentActivity.fromJson(v));
      });
    }
  }

  dynamic totalCredits;
  dynamic creditsThisYear;
  int? eventsAttended;
  int? eventsRegistered;
  int? upcomingEvents;
  int? certificatesEarned;
  String? complianceStatus;
  List<CmeCreditBreakdown>? creditBreakdown;
  List<CmeRecentActivity>? recentActivity;
  CmeNavCounts? navCounts;
  CmeProviderCounts? providerCounts;
}

class CmeNavCounts {
  CmeNavCounts({
    this.registrations = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.certificates = 0,
    this.speaking = 0,
    this.invitations = 0,
  });

  factory CmeNavCounts.fromJson(dynamic json) {
    return CmeNavCounts(
      registrations: _int(json['registrations']),
      inProgress: _int(json['in_progress'] ?? json['inProgress']),
      completed: _int(json['completed']),
      certificates: _int(json['certificates']),
      speaking: _int(json['speaking']),
      invitations: _int(json['invitations']),
    );
  }

  final int registrations;
  final int inProgress;
  final int completed;
  final int certificates;
  final int speaking;
  final int invitations;

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

class CmeProviderCounts {
  CmeProviderCounts({this.all = 0, this.open = 0, this.closed = 0});

  factory CmeProviderCounts.fromJson(dynamic json) {
    return CmeProviderCounts(
      all: CmeNavCounts._int(json['all']),
      open: CmeNavCounts._int(json['open']),
      closed: CmeNavCounts._int(json['closed']),
    );
  }

  final int all;
  final int open;
  final int closed;
}

class CmeCreditBreakdown {
  CmeCreditBreakdown({this.type, this.amount, this.percentage});

  CmeCreditBreakdown.fromJson(dynamic json) {
    type = json['type'];
    amount = json['amount'];
    percentage = json['percentage'];
  }

  String? type;
  dynamic amount;
  dynamic percentage;
}

class CmeRecentActivity {
  CmeRecentActivity({
    this.id,
    this.type,
    this.title,
    this.description,
    this.date,
    this.credits,
  });

  CmeRecentActivity.fromJson(dynamic json) {
    id = json['id'];
    type = json['type'];
    title = json['title'];
    description = json['description'];
    date = json['date'];
    credits = json['credits'];
  }

  String? id;
  String? type;
  String? title;
  String? description;
  String? date;
  dynamic credits;
}
