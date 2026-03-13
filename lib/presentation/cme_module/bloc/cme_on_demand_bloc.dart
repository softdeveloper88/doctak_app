import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/apiClient/cme/cme_api_service.dart';
import '../../../data/models/cme/cme_gamification_model.dart';
import 'cme_on_demand_event.dart';
import 'cme_on_demand_state.dart';

class CmeOnDemandBloc extends Bloc<CmeOnDemandEvent, CmeOnDemandState> {
  List<CmeOnDemandModule> modules = [];
  CmeOnDemandModule? currentModule;

  CmeOnDemandBloc() : super(CmeOnDemandInitialState()) {
    on<CmeLoadOnDemandModulesEvent>(_onLoadModules);
    on<CmeLoadOnDemandModuleDetailEvent>(_onLoadDetail);
    on<CmeCompleteSectionEvent>(_onCompleteSection);
    on<CmeBackToModulesEvent>(_onBackToModules);
  }

  Future<void> _onLoadModules(
    CmeLoadOnDemandModulesEvent event,
    Emitter<CmeOnDemandState> emit,
  ) async {
    emit(CmeOnDemandLoadingState());
    try {
      final eventData =
          await CmeApiService.getEventDetail(event.eventId);
      if (eventData.modules != null) {
        modules = eventData.modules!
            .map((m) => CmeOnDemandModule(
                  id: m.id,
                  title: m.title,
                  type: m.type,
                  durationMinutes: m.duration,
                ))
            .toList();
      }
      emit(CmeOnDemandLoadedState());
    } catch (e) {
      emit(CmeOnDemandErrorState(e.toString()));
    }
  }

  Future<void> _onLoadDetail(
    CmeLoadOnDemandModuleDetailEvent event,
    Emitter<CmeOnDemandState> emit,
  ) async {
    emit(CmeOnDemandLoadingState());
    try {
      final response =
          await CmeApiService.getModuleDetail(event.moduleId);
      if (response['data'] != null) {
        currentModule = CmeOnDemandModule.fromJson(response['data']);
      }
      emit(CmeOnDemandDetailLoadedState());
    } catch (e) {
      emit(CmeOnDemandErrorState(e.toString()));
    }
  }

  Future<void> _onCompleteSection(
    CmeCompleteSectionEvent event,
    Emitter<CmeOnDemandState> emit,
  ) async {
    emit(CmeOnDemandLoadingState());
    try {
      await CmeApiService.completeModule(event.moduleId);
      // Reload the module detail to get updated progress
      final response =
          await CmeApiService.getModuleDetail(event.moduleId);
      if (response['data'] != null) {
        currentModule = CmeOnDemandModule.fromJson(response['data']);
      }
      emit(CmeOnDemandSectionCompletedState());
    } catch (e) {
      emit(CmeOnDemandErrorState(e.toString()));
    }
  }

  void _onBackToModules(
    CmeBackToModulesEvent event,
    Emitter<CmeOnDemandState> emit,
  ) {
    currentModule = null;
    emit(CmeOnDemandLoadedState());
  }
}
