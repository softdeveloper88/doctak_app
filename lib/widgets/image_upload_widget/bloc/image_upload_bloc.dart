import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'image_upload_event.dart';
import 'image_upload_state.dart';

class ImageUploadBloc
    extends Bloc<ImageUploadEvent, ImageUploadState> {

  List<XFile> imagefiles = [];

  ImageUploadBloc() : super(FileInitialState()) {

    on<SelectedFiles>(_SelectedFile);
  }

  _SelectedFile(SelectedFiles event, Emitter<ImageUploadState> emit) async {
    if (event.isRemove) {
      imagefiles.remove(event.pickedfiles);
      emit(FileLoadedState());
    } else {
      imagefiles.add(event.pickedfiles);
      // print(imagefiles);
      emit(FileLoadedState());
    }
    // emit(DataLoaded(searchPeopleData));
  }
}