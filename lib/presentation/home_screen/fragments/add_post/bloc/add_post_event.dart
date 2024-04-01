import 'package:doctak_app/data/models/search_user_tag_model/search_user_tag_model.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
abstract class AddPostEvent extends Equatable{}

class LoadDataValues extends AddPostEvent {
  @override
  List<Object?> get props => [];
}

class GetPost extends AddPostEvent {
  final String page;
  final String name;

  GetPost({required this.page,required this.name});
  @override
  List<Object> get props => [page,name];
}

class LoadPageEvent extends AddPostEvent {
  int? page;
  final String? name;

  LoadPageEvent({this.page,this.name});
  @override
  List<Object?> get props => [page,name];
}
class PlaceAddEvent extends AddPostEvent {
  int? page;
  final String? name;
  final String? latitude;
  final String? longitude;
  PlaceAddEvent({this.page,this.name,this.latitude,this.longitude});
  @override
  List<Object?> get props => [page,name,latitude,longitude];
}

class SelectFriendEvent extends AddPostEvent {

  final UserData? userData;
  bool? isAdd;
  SelectFriendEvent({this.userData,this.isAdd});
  @override
  List<Object?> get props => [userData,isAdd];
}
class SelectedLocation extends AddPostEvent {
  final String? name;
  final String? latitude;
  final String? longitude;
  SelectedLocation({this.name,this.latitude,this.longitude});
  @override
  List<Object?> get props => [name,latitude,longitude];
}
class SelectedFiles extends AddPostEvent {
  XFile pickedfiles;
  bool isRemove;
  SelectedFiles({required this.pickedfiles,required this.isRemove});
  @override
  List<Object?> get props => [pickedfiles,isRemove];

}
class AddPostDataEvent extends AddPostEvent {

  @override
  List<Object?> get props => [];
}

class SearchFieldData extends AddPostEvent {
  String searchValue;
  SearchFieldData(this.searchValue);
  @override
  List<Object?> get props => [searchValue];
}
class TextFieldEvent extends AddPostEvent {
  String text;
  TextFieldEvent(this.text);
  @override
  List<Object?> get props => [text];
}

class CheckIfNeedMoreDataEvent extends AddPostEvent {
  final int index;
  CheckIfNeedMoreDataEvent({required this.index});
  @override
  List<Object?> get props => [index];
}