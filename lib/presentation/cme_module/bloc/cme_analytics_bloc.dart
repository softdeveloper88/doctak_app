import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_analytics_model.dart';
import 'cme_analytics_event.dart';
import 'cme_analytics_state.dart';

class CmeAnalyticsBloc extends Bloc<CmeAnalyticsEvent, CmeAnalyticsState> {
  CmeCreditAnalytics? creditAnalytics;
  CmeComplianceAnalytics? complianceAnalytics;
  CmePerformanceAnalytics? performanceAnalytics;
  List<CmeTrendPoint> trends = [];

  CmeAnalyticsBloc() : super(CmeAnalyticsInitialState()) {
    on<CmeLoadAnalyticsDashboardEvent>(_onLoadDashboard);
    on<CmeLoadCreditAnalyticsEvent>(_onLoadCredits);
    on<CmeLoadComplianceAnalyticsEvent>(_onLoadCompliance);
    on<CmeLoadPerformanceAnalyticsEvent>(_onLoadPerformance);
    on<CmeLoadTrendsEvent>(_onLoadTrends);
    on<CmeExportAnalyticsEvent>(_onExport);
  }

  Future<void> _onLoadDashboard(
      CmeLoadAnalyticsDashboardEvent event, Emitter<CmeAnalyticsState> emit) async {
    emit(CmeAnalyticsLoadingState());
    try {
      // Load all four analytics sections in parallel
      final results = await Future.wait([
        CmeApiService.getCreditAnalytics(),
        CmeApiService.getComplianceAnalytics(),
        CmeApiService.getPerformanceAnalytics(),
        CmeApiService.getTrends(),
      ]);

      creditAnalytics = CmeCreditAnalytics.fromJson(results[0]);
      complianceAnalytics = CmeComplianceAnalytics.fromJson(results[1]);
      performanceAnalytics = CmePerformanceAnalytics.fromJson(results[2]);

      final trendsData = results[3];
      if (trendsData['trends'] != null) {
        trends = (trendsData['trends'] as List)
            .map((t) => CmeTrendPoint.fromJson(t))
            .toList();
      }
      emit(CmeAnalyticsLoadedState());
    } catch (e) {
      emit(CmeAnalyticsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadCredits(
      CmeLoadCreditAnalyticsEvent event, Emitter<CmeAnalyticsState> emit) async {
    emit(CmeAnalyticsLoadingState());
    try {
      final data = await CmeApiService.getCreditAnalytics();
      creditAnalytics = CmeCreditAnalytics.fromJson(data);
      emit(CmeAnalyticsLoadedState());
    } catch (e) {
      emit(CmeAnalyticsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadCompliance(
      CmeLoadComplianceAnalyticsEvent event, Emitter<CmeAnalyticsState> emit) async {
    emit(CmeAnalyticsLoadingState());
    try {
      final data = await CmeApiService.getComplianceAnalytics();
      complianceAnalytics = CmeComplianceAnalytics.fromJson(data);
      emit(CmeAnalyticsLoadedState());
    } catch (e) {
      emit(CmeAnalyticsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadPerformance(
      CmeLoadPerformanceAnalyticsEvent event, Emitter<CmeAnalyticsState> emit) async {
    emit(CmeAnalyticsLoadingState());
    try {
      final data = await CmeApiService.getPerformanceAnalytics();
      performanceAnalytics = CmePerformanceAnalytics.fromJson(data);
      emit(CmeAnalyticsLoadedState());
    } catch (e) {
      emit(CmeAnalyticsErrorState(e.toString()));
    }
  }

  Future<void> _onLoadTrends(
      CmeLoadTrendsEvent event, Emitter<CmeAnalyticsState> emit) async {
    try {
      final data = await CmeApiService.getTrends();
      if (data['trends'] != null) {
        trends = (data['trends'] as List)
            .map((t) => CmeTrendPoint.fromJson(t))
            .toList();
      }
      emit(CmeAnalyticsLoadedState());
    } catch (e) {
      emit(CmeAnalyticsErrorState(e.toString()));
    }
  }

  Future<void> _onExport(
      CmeExportAnalyticsEvent event, Emitter<CmeAnalyticsState> emit) async {
    try {
      final url = await CmeApiService.exportAnalytics();
      emit(CmeAnalyticsExportedState(url));
    } catch (e) {
      emit(CmeAnalyticsErrorState(e.toString()));
    }
  }
}
