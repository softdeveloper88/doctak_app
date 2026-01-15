import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class ImageUploadEvent extends Equatable {}

class FileDataValues extends ImageUploadEvent {
  @override
  List<Object?> get props => [];
}

class SelectedFiles extends ImageUploadEvent {
  XFile pickedfiles;
  bool isRemove;
  SelectedFiles({required this.pickedfiles, required this.isRemove});
  @override
  List<Object?> get props => [pickedfiles, isRemove];
}
