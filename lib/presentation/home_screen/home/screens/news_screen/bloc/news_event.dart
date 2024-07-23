import 'package:equatable/equatable.dart';

abstract class NewsEvent extends Equatable {}

class LoadDataValues extends NewsEvent {
  @override
  List<Object?> get props => [];
}

class GetPost extends NewsEvent {
  final String newsChannel;

  GetPost({required this.newsChannel});
  @override
  List<Object> get props => [newsChannel];
}
