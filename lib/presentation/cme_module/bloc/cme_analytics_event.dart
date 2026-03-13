import 'package:equatable/equatable.dart';

abstract class CmeAnalyticsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CmeLoadAnalyticsDashboardEvent extends CmeAnalyticsEvent {}

class CmeLoadCreditAnalyticsEvent extends CmeAnalyticsEvent {}

class CmeLoadComplianceAnalyticsEvent extends CmeAnalyticsEvent {}

class CmeLoadPerformanceAnalyticsEvent extends CmeAnalyticsEvent {}

class CmeLoadTrendsEvent extends CmeAnalyticsEvent {}

class CmeExportAnalyticsEvent extends CmeAnalyticsEvent {}
