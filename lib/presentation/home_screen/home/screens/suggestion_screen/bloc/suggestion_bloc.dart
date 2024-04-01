import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/bloc/suggestion_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'suggestion_state.dart';

class SuggestionBloc extends Bloc<SuggestionEvent, SuggestionState> {
  final ApiService postService = ApiService(Dio());

  SuggestionBloc() : super(PaginationInitialState()) {
    on<SaveSuggestion>(_onSaveSuggestionData);
  }

  _onSaveSuggestionData(
      SaveSuggestion event, Emitter<SuggestionState> emit) async {
    emit(PaginationLoadingState());
    // try {
    ProgressDialogUtils.showProgressDialog();

    var response = await postService.saveSuggestion(
        'Bearer ${AppData.userToken}',
        event.name,
        event.phone,
        event.email,
        event.message);
    ProgressDialogUtils.hideProgressDialog();
    print(response.response);
    // List<NewsModel> newsList1 = response1.map((item) => NewsModel.fromJson(item)).toList();
    // List<NewsModel> newsList2 = response2.map((item) => NewsModel.fromJson(item)).toList();
    // print("dddd$newsList1");
    emit(PaginationLoadedState(response.response.data));
    // emit(DataLoaded(bbcNews));
    // } catch (e) {
    // ProgressDialogUtils.hideProgressDialog();
    // print(e);

    // emit(DataError('No Data Found'));
    // }
  }
}
