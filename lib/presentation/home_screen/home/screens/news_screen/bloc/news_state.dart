
import 'package:doctak_app/data/models/news_model/news_model.dart';

abstract class NewsState {}
class NewsDataInitial extends NewsState {}

class DataError extends NewsState {
  final String errorMessage;
  DataError(this.errorMessage);
}
class PaginationInitialState extends NewsState {
  PaginationInitialState();
}
class PaginationLoadedState extends NewsState {
  List<NewsModel> bbcNews;
  List<NewsModel> cnnNews;
  PaginationLoadedState(this.bbcNews,this.cnnNews);
}
class PaginationLoadingState extends NewsState {}

class PaginationErrorState extends NewsState {}

