import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

abstract class CaseDiscussionEvent extends Equatable {}

class LoadDataValues extends CaseDiscussionEvent {
  @override
  List<Object?> get props => [];
}

class GetCaseDiscussion extends CaseDiscussionEvent {
  final String page;
  final String countryId;
  final String searchTerm;

  GetCaseDiscussion({required this.page, required this.countryId, required this.searchTerm});
  @override
  List<Object> get props => [page, countryId, searchTerm];
}
class AddCaseDataEvent extends CaseDiscussionEvent {
  final String title;
  final String description;
  final String keyword;

  AddCaseDataEvent({required this.title, required this.description, required this.keyword});
  @override
  List<Object> get props => [title, description, keyword];
}

class SelectedFiles extends CaseDiscussionEvent {
  XFile pickedfiles;
  bool isRemove;
  SelectedFiles({required this.pickedfiles, required this.isRemove});
  @override
  List<Object?> get props => [pickedfiles, isRemove];
}
class CaseDiscussionLoadPageEvent extends CaseDiscussionEvent {
  int? page;
  final String? countryId;
  final String? searchTerm;

  CaseDiscussionLoadPageEvent(
      {this.page, this.countryId,  this.searchTerm});
  @override
  List<Object?> get props => [page, countryId, searchTerm];
}

class CaseDiscussionDetailPageEvent extends CaseDiscussionEvent {
  String? caseId;
  CaseDiscussionDetailPageEvent({this.caseId});
  @override
  List<Object?> get props => [caseId];
}
class CaseCommentPageEvent extends CaseDiscussionEvent {
  String? caseId;
  CaseCommentPageEvent({this.caseId});
  @override
  List<Object?> get props => [caseId];
}
class AddCaseCommentEvent extends CaseDiscussionEvent {
  String? caseId;
  String? comment;
  AddCaseCommentEvent({this.caseId,this.comment});
  @override
  List<Object?> get props => [caseId,comment];
}
class CaseDiscussEvent extends CaseDiscussionEvent {
  String? caseId;
  String? type;
  String? actionType;
  CaseDiscussEvent({this.caseId,this.type,this.actionType});
  @override
  List<Object?> get props => [caseId,type,actionType];
}

class CaseDiscussionCheckIfNeedMoreDataEvent extends CaseDiscussionEvent {
  final int index;
  CaseDiscussionCheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}
