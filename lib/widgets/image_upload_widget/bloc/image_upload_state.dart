abstract class ImageUploadState {}

class FileDataInitial extends ImageUploadState {}

class FileDataError extends ImageUploadState {
  final String errorMessage;
  FileDataError(this.errorMessage);
}

class FileInitialState extends ImageUploadState {
  FileInitialState();
}

class FileLoadedState extends ImageUploadState {}

class FileLoadingState extends ImageUploadState {}

class FileErrorState extends ImageUploadState {}
