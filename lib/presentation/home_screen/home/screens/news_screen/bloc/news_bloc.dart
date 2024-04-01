import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/news_model/news_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/news_screen/bloc/news_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final ApiService postService = ApiService(Dio());
  int pageNumber = 1;
  int numberOfPage = 1;
  // List<NewsModel> bbcNews = [];
  // List<NewsModel> cnnNews = [];
  final int nextPageTrigger = 1;

  NewsBloc() : super(PaginationInitialState()) {
    on<GetPost>(_onGetNewsData);
  }


  _onGetNewsData(GetPost event, Emitter<NewsState> emit) async {
    emit(PaginationLoadingState());
    // try {
      var response1 = await postService.newsChannel(
          'Bearer ${AppData.userToken}',
          'bbc-news',

      );
      var response2 = await postService.newsChannel(
          'Bearer ${AppData.userToken}',
          'cnn-news',

      );

      // List<NewsModel> newsList1 = response1.map((item) => NewsModel.fromJson(item)).toList();
      // List<NewsModel> newsList2 = response2.map((item) => NewsModel.fromJson(item)).toList();
     // print("dddd$newsList1");
      emit(PaginationLoadedState(response1,response2));
      // emit(DataLoaded(bbcNews));
    // } catch (e) {
      // ProgressDialogUtils.hideProgressDialog();
      // print(e);

      // emit(DataError('No Data Found'));
    // }
  }
}