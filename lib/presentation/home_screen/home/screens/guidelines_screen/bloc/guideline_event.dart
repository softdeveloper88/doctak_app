import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class GuidelineEvent extends Equatable{}

class LoadDataValues extends GuidelineEvent {
  @override
  List<Object?> get props => [];
}

class GetPost extends GuidelineEvent {
  final String page;
  final String countryId;
  final String searchTerm;

  GetPost({required this.page,required this.countryId,required this.searchTerm});
  @override
  List<Object> get props => [page,countryId,searchTerm];
}

class LoadPageEvent extends GuidelineEvent {
int? page;
final String? searchTerm;

LoadPageEvent({this.page,this.searchTerm});
@override
List<Object?> get props => [page,searchTerm];
}
class CheckIfNeedMoreDataEvent extends GuidelineEvent {
  final int index;
  CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}