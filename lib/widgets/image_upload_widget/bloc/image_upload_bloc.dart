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
      print('BLoC: Removing image ${event.pickedfiles.path}');
      imagefiles.remove(event.pickedfiles);
      print('BLoC: Now have ${imagefiles.length} images after removal');
      emit(FileLoadedState());
    } else {
      print('BLoC: Adding image ${event.pickedfiles.path}');
      imagefiles.add(event.pickedfiles);
      print('BLoC: Now have ${imagefiles.length} images after addition');
      print('BLoC: Emitting FileLoadedState');
      emit(FileLoadedState());
    }
  }
}