abstract class CmeCertificatesState {}

class CmeCertificatesInitialState extends CmeCertificatesState {}

class CmeCertificatesLoadingState extends CmeCertificatesState {}

class CmeCertificatesLoadedState extends CmeCertificatesState {}

class CmeCertificatesErrorState extends CmeCertificatesState {
  final String errorMessage;
  CmeCertificatesErrorState(this.errorMessage);
}

class CmeCertificateDownloadState extends CmeCertificatesState {
  final String downloadUrl;
  CmeCertificateDownloadState(this.downloadUrl);
}
