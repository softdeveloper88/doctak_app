import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_gamification_model.dart';
import 'cme_gamification_event.dart';
import 'cme_gamification_state.dart';

class CmeGamificationBloc
    extends Bloc<CmeGamificationEvent, CmeGamificationState> {
  CmeGamificationData? gamificationData;
  List<CmeBadgeData> badges = [];
  List<CmeLeaderboardEntry> leaderboard = [];

  CmeGamificationBloc() : super(CmeGamificationInitialState()) {
    on<CmeLoadGamificationEvent>(_onLoadGamification);
    on<CmeLoadBadgesEvent>(_onLoadBadges);
    on<CmeLoadLeaderboardEvent>(_onLoadLeaderboard);
  }

  Future<void> _onLoadGamification(
      CmeLoadGamificationEvent event, Emitter<CmeGamificationState> emit) async {
    emit(CmeGamificationLoadingState());
    try {
      final response = await CmeApiService.getAchievements();
      gamificationData = CmeGamificationData.fromJson(response['data'] ?? response);

      if (gamificationData?.badges != null) {
        badges = gamificationData!.badges!;
      }
      if (gamificationData?.leaderboard != null) {
        leaderboard = gamificationData!.leaderboard!;
      }

      emit(CmeGamificationLoadedState());
    } catch (e) {
      emit(CmeGamificationErrorState(e.toString()));
    }
  }

  Future<void> _onLoadBadges(
      CmeLoadBadgesEvent event, Emitter<CmeGamificationState> emit) async {
    try {
      final response = await CmeApiService.getAchievements();
      final data = response['data'] ?? response;
      if (data['badges'] != null) {
        badges = (data['badges'] as List)
            .map((b) => CmeBadgeData.fromJson(b))
            .toList();
      }
      emit(CmeGamificationLoadedState());
    } catch (e) {
      emit(CmeGamificationErrorState(e.toString()));
    }
  }

  Future<void> _onLoadLeaderboard(
      CmeLoadLeaderboardEvent event, Emitter<CmeGamificationState> emit) async {
    try {
      final response = await CmeApiService.getAchievements();
      final data = response['data'] ?? response;
      if (data['leaderboard'] != null) {
        leaderboard = (data['leaderboard'] as List)
            .map((l) => CmeLeaderboardEntry.fromJson(l))
            .toList();
      }
      emit(CmeGamificationLoadedState());
    } catch (e) {
      emit(CmeGamificationErrorState(e.toString()));
    }
  }
}
