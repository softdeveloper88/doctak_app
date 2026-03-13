abstract class CmeCertificateShareState {}

class CmeCertificateShareInitialState extends CmeCertificateShareState {}

class CmeCertificateShareLoadingState extends CmeCertificateShareState {}

class CmeCertificateShareLoadedState extends CmeCertificateShareState {}

class CmeCertificateShareSharedState extends CmeCertificateShareState {}

class CmeCertificateShareVerifiedState extends CmeCertificateShareState {}

class CmeCertificateShareErrorState extends CmeCertificateShareState {
  final String message;
  CmeCertificateShareErrorState(this.message);
}
