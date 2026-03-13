import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/apiClient/cme/cme_api_service.dart';
import '../../../data/models/cme/cme_gamification_model.dart';
import 'cme_certificate_share_event.dart';
import 'cme_certificate_share_state.dart';

class CmeCertificateShareBloc
    extends Bloc<CmeCertificateShareEvent, CmeCertificateShareState> {
  CmeShareableCertificate? certificate;
  CmeShareableCertificate? verifiedCertificate;

  CmeCertificateShareBloc() : super(CmeCertificateShareInitialState()) {
    on<CmeLoadCertificateDetailEvent>(_onLoadDetail);
    on<CmeShareCertificateEvent>(_onShare);
    on<CmeVerifyCertificateEvent>(_onVerify);
  }

  Future<void> _onLoadDetail(
    CmeLoadCertificateDetailEvent event,
    Emitter<CmeCertificateShareState> emit,
  ) async {
    emit(CmeCertificateShareLoadingState());
    try {
      final certData =
          await CmeApiService.getCertificateDetail(event.certificateId);
      // Map CmeCertificateData to CmeShareableCertificate
      certificate = CmeShareableCertificate(
        certificateNumber: certData.certificateNumber,
        eventTitle: certData.eventTitle,
        holderName: null,
        creditType: certData.creditType,
        creditAmount: certData.creditAmount,
        downloadUrl: null,
        shareUrl: null,
        verificationUrl: certData.verificationUrl,
        qrCodeUrl: null,
        isValid: certData.isValid,
        accreditationBody: certData.accreditationBody,
      );
      emit(CmeCertificateShareLoadedState());
    } catch (e) {
      emit(CmeCertificateShareErrorState(e.toString()));
    }
  }

  Future<void> _onShare(
    CmeShareCertificateEvent event,
    Emitter<CmeCertificateShareState> emit,
  ) async {
    emit(CmeCertificateShareLoadingState());
    try {
      final response =
          await CmeApiService.shareCertificate(event.certificateId);
      if (response['data'] != null) {
        certificate =
            CmeShareableCertificate.fromJson(response['data']);
      } else if (response['share_url'] != null && certificate != null) {
        certificate = CmeShareableCertificate(
          certificateNumber: certificate!.certificateNumber,
          eventTitle: certificate!.eventTitle,
          holderName: certificate!.holderName,
          creditType: certificate!.creditType,
          creditAmount: certificate!.creditAmount,
          downloadUrl: certificate!.downloadUrl,
          shareUrl: response['share_url'],
          verificationUrl: certificate!.verificationUrl,
          qrCodeUrl: certificate!.qrCodeUrl,
          isValid: certificate!.isValid,
          accreditationBody: certificate!.accreditationBody,
        );
      }
      emit(CmeCertificateShareSharedState());
    } catch (e) {
      emit(CmeCertificateShareErrorState(e.toString()));
    }
  }

  Future<void> _onVerify(
    CmeVerifyCertificateEvent event,
    Emitter<CmeCertificateShareState> emit,
  ) async {
    emit(CmeCertificateShareLoadingState());
    try {
      final response =
          await CmeApiService.verifyCertificate(event.certificateNumber);
      if (response['data'] != null) {
        verifiedCertificate =
            CmeShareableCertificate.fromJson(response['data']);
      }
      emit(CmeCertificateShareVerifiedState());
    } catch (e) {
      emit(CmeCertificateShareErrorState(e.toString()));
    }
  }
}
