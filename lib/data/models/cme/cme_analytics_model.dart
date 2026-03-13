class CmeAnalyticsData {
  final CmeCreditAnalytics? credits;
  final CmeComplianceAnalytics? compliance;
  final CmePerformanceAnalytics? performance;
  final List<CmeTrendPoint>? trends;

  CmeAnalyticsData({
    this.credits,
    this.compliance,
    this.performance,
    this.trends,
  });

  factory CmeAnalyticsData.fromJson(Map<String, dynamic> json) {
    return CmeAnalyticsData(
      credits: json['credits'] != null
          ? CmeCreditAnalytics.fromJson(json['credits'])
          : null,
      compliance: json['compliance'] != null
          ? CmeComplianceAnalytics.fromJson(json['compliance'])
          : null,
      performance: json['performance'] != null
          ? CmePerformanceAnalytics.fromJson(json['performance'])
          : null,
      trends: json['trends'] != null
          ? (json['trends'] as List)
              .map((t) => CmeTrendPoint.fromJson(t))
              .toList()
          : null,
    );
  }
}

class CmeCreditAnalytics {
  final int? totalCredits;
  final int? creditsThisYear;
  final int? creditsThisMonth;
  final int? requiredCredits;
  final int? remainingCredits;
  final double? completionPercentage;
  final List<CmeCreditByType>? byType;
  final List<CmeCreditByMonth>? byMonth;

  CmeCreditAnalytics({
    this.totalCredits,
    this.creditsThisYear,
    this.creditsThisMonth,
    this.requiredCredits,
    this.remainingCredits,
    this.completionPercentage,
    this.byType,
    this.byMonth,
  });

  factory CmeCreditAnalytics.fromJson(Map<String, dynamic> json) {
    return CmeCreditAnalytics(
      totalCredits: json['total_credits'],
      creditsThisYear: json['credits_this_year'],
      creditsThisMonth: json['credits_this_month'],
      requiredCredits: json['required_credits'],
      remainingCredits: json['remaining_credits'],
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble(),
      byType: json['by_type'] != null
          ? (json['by_type'] as List)
              .map((t) => CmeCreditByType.fromJson(t))
              .toList()
          : null,
      byMonth: json['by_month'] != null
          ? (json['by_month'] as List)
              .map((m) => CmeCreditByMonth.fromJson(m))
              .toList()
          : null,
    );
  }
}

class CmeCreditByType {
  final String? type;
  final int? credits;
  final double? percentage;

  CmeCreditByType({this.type, this.credits, this.percentage});

  factory CmeCreditByType.fromJson(Map<String, dynamic> json) {
    return CmeCreditByType(
      type: json['type'],
      credits: json['credits'],
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }
}

class CmeCreditByMonth {
  final String? month;
  final int? credits;

  CmeCreditByMonth({this.month, this.credits});

  factory CmeCreditByMonth.fromJson(Map<String, dynamic> json) {
    return CmeCreditByMonth(
      month: json['month'],
      credits: json['credits'],
    );
  }
}

class CmeComplianceAnalytics {
  final String? status; // compliant, at_risk, non_compliant
  final int? daysUntilDeadline;
  final String? nextDeadline;
  final double? complianceRate;
  final List<CmeComplianceRequirement>? requirements;

  CmeComplianceAnalytics({
    this.status,
    this.daysUntilDeadline,
    this.nextDeadline,
    this.complianceRate,
    this.requirements,
  });

  factory CmeComplianceAnalytics.fromJson(Map<String, dynamic> json) {
    return CmeComplianceAnalytics(
      status: json['status'],
      daysUntilDeadline: json['days_until_deadline'],
      nextDeadline: json['next_deadline'],
      complianceRate: (json['compliance_rate'] as num?)?.toDouble(),
      requirements: json['requirements'] != null
          ? (json['requirements'] as List)
              .map((r) => CmeComplianceRequirement.fromJson(r))
              .toList()
          : null,
    );
  }

  bool get isCompliant => status == 'compliant';
  bool get isAtRisk => status == 'at_risk';
}

class CmeComplianceRequirement {
  final String? name;
  final int? required;
  final int? earned;
  final double? percentage;
  final String? deadline;

  CmeComplianceRequirement({
    this.name,
    this.required,
    this.earned,
    this.percentage,
    this.deadline,
  });

  factory CmeComplianceRequirement.fromJson(Map<String, dynamic> json) {
    return CmeComplianceRequirement(
      name: json['name'],
      required: json['required'],
      earned: json['earned'],
      percentage: (json['percentage'] as num?)?.toDouble(),
      deadline: json['deadline'],
    );
  }
}

class CmePerformanceAnalytics {
  final double? averageQuizScore;
  final int? totalQuizzesTaken;
  final int? quizzesPassed;
  final double? attendanceRate;
  final double? completionRate;
  final int? eventsAttended;
  final int? eventsRegistered;

  CmePerformanceAnalytics({
    this.averageQuizScore,
    this.totalQuizzesTaken,
    this.quizzesPassed,
    this.attendanceRate,
    this.completionRate,
    this.eventsAttended,
    this.eventsRegistered,
  });

  factory CmePerformanceAnalytics.fromJson(Map<String, dynamic> json) {
    return CmePerformanceAnalytics(
      averageQuizScore: (json['average_quiz_score'] as num?)?.toDouble(),
      totalQuizzesTaken: json['total_quizzes_taken'],
      quizzesPassed: json['quizzes_passed'],
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble(),
      completionRate: (json['completion_rate'] as num?)?.toDouble(),
      eventsAttended: json['events_attended'],
      eventsRegistered: json['events_registered'],
    );
  }
}

class CmeTrendPoint {
  final String? period;
  final int? credits;
  final int? events;

  CmeTrendPoint({this.period, this.credits, this.events});

  factory CmeTrendPoint.fromJson(Map<String, dynamic> json) {
    return CmeTrendPoint(
      period: json['period'] ?? json['month'],
      credits: json['credits'],
      events: json['events'],
    );
  }
}
