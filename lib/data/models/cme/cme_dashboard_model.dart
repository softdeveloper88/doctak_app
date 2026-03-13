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
    totalCredits = json['total_credits'];
    creditsThisYear = json['credits_this_year'];
    eventsAttended = json['events_attended'];
    eventsRegistered = json['events_registered'];
    upcomingEvents = json['upcoming_events'];
    certificatesEarned = json['certificates_earned'];
    complianceStatus = json['compliance_status'];
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
