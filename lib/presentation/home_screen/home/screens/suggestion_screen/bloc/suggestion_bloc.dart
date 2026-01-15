import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/suggestion_screen/bloc/suggestion_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'suggestion_state.dart';

class SuggestionBloc extends Bloc<SuggestionEvent, SuggestionState> {
  final ApiServiceManager apiManager = ApiServiceManager();

  SuggestionBloc() : super(PaginationInitialState()) {
    on<SaveSuggestion>(_onSaveSuggestionData);
  }

  Future<void> _onSaveSuggestionData(SaveSuggestion event, Emitter<SuggestionState> emit) async {
    emit(PaginationLoadingState());
    // try {
    ProgressDialogUtils.showProgressDialog();

    var response = await apiManager.saveSuggestion('Bearer ${AppData.userToken}', event.name, event.phone, event.email, event.message);
    ProgressDialogUtils.hideProgressDialog();
    // List<NewsModel> newsList1 = response1.map((item) => NewsModel.fromJson(item)).toList();
    // List<NewsModel> newsList2 = response2.map((item) => NewsModel.fromJson(item)).toList();
    // print("dddd$newsList1");
    globalMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Your message has been sent, thank you!')));
    emit(PaginationLoadedState('Your message has been sent, thank you!'));
    // emit(DataLoaded(bbcNews));
    // } catch (e) {
    // ProgressDialogUtils.hideProgressDialog();
    // print(e);

    // emit(DataError('No Data Found'));
    // }
  }
}
