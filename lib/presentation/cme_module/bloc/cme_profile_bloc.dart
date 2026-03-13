import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_profile_model.dart';
import 'cme_profile_event.dart';
import 'cme_profile_state.dart';

class CmeProfileBloc extends Bloc<CmeProfileEvent, CmeProfileState> {
  CmeProfileData? profile;
  CmeTranscriptData? transcript;
  List<CmeAchievementData> achievements = [];

  CmeProfileBloc() : super(CmeProfileInitialState()) {
    on<CmeLoadProfileEvent>(_onLoadProfile);
    on<CmeLoadTranscriptEvent>(_onLoadTranscript);
    on<CmeLoadAchievementsEvent>(_onLoadAchievements);
  }

  Future<void> _onLoadProfile(
      CmeLoadProfileEvent event, Emitter<CmeProfileState> emit) async {
    emit(CmeProfileLoadingState());
    try {
      final data = await CmeApiService.getUserCredits();
      profile = CmeProfileData.fromJson(data);
      emit(CmeProfileLoadedState());
    } catch (e) {
      emit(CmeProfileErrorState(e.toString()));
    }
  }

  Future<void> _onLoadTranscript(
      CmeLoadTranscriptEvent event, Emitter<CmeProfileState> emit) async {
    emit(CmeProfileLoadingState());
    try {
      final data = await CmeApiService.getTranscript();
      transcript = CmeTranscriptData.fromJson(data);
      emit(CmeTranscriptLoadedState());
    } catch (e) {
      emit(CmeProfileErrorState(e.toString()));
    }
  }

  Future<void> _onLoadAchievements(
      CmeLoadAchievementsEvent event, Emitter<CmeProfileState> emit) async {
    emit(CmeProfileLoadingState());
    try {
      final data = await CmeApiService.getAchievements();
      if (data['achievements'] != null) {
        achievements = (data['achievements'] as List)
            .map((a) => CmeAchievementData.fromJson(a))
            .toList();
      }
      emit(CmeAchievementsLoadedState());
    } catch (e) {
      emit(CmeProfileErrorState(e.toString()));
    }
  }
}
