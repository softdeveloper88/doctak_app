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

class JobLoadPageEvent extends JobsEvent {
int? page;
final String? countryId;
String? isExpired='New';
final String? searchTerm;

JobLoadPageEvent({this.page,this.countryId,this.isExpired,this.searchTerm});
@override
List<Object?> get props => [page,countryId,isExpired,searchTerm];
}
class JobCheckIfNeedMoreDataEvent extends JobsEvent {
  final int index;
  JobCheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}