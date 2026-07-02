abstract class CmeCertificatesState {}

class CmeCertificatesInitialState extends CmeCertificatesState {}

class CmeCertificatesLoadingState extends CmeCertificatesState {}

class CmeCertificatesLoadedState extends CmeCertificatesState {}

class CmeCertificatesErrorState extends CmeCertificatesState {
  final String errorMessage;
  CmeCertificatesErrorState(this.errorMessage);
}

class CmeCertificateDownloadState extends CmeCertificatesState {
  final String localFilePath;
  CmeCertificateDownloadState(this.localFilePath);
}

class CmeCertificateDownloadingState extends CmeCertificatesState {}
