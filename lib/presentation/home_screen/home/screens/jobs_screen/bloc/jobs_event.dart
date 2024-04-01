import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class JobsEvent extends Equatable{}

class LoadDataValues extends JobsEvent {
  @override
  List<Object?> get props => [];
}

class GetPost extends JobsEvent {
  final String page;
  final String countryId;
  final String searchTerm;

  GetPost({required this.page,required this.countryId,required this.searchTerm});
  @override
  List<Object> get props => [page,countryId,searchTerm];
}

class LoadPageEvent extends JobsEvent {
int? page;
final String? countryId;
String? isExpired='New';
final String? searchTerm;

LoadPageEvent({this.page,this.countryId,this.isExpired,this.searchTerm});
@override
List<Object?> get props => [page,countryId,isExpired,searchTerm];
}
class CheckIfNeedMoreDataEvent extends JobsEvent {
  final int index;
  CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}