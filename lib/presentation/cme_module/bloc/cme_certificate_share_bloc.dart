import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app/AppData.dart';
import '../../../data/apiClient/cme/cme_api_service.dart';
import '../../../data/apiClient/cme/cme_node_api_service.dart';
import '../../../data/models/cme/cme_certificate_model.dart';
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
      try {
        final nodeCert =
            await CmeNodeApiService.getCertificateDetail(event.certificateId);
        certificate = CmeShareableCertificate.fromCertificateData(nodeCert);
      } catch (_) {
        final certData =
            await CmeApiService.getCertificateDetail(event.certificateId);
        certificate = CmeShareableCertificate(
          certificateNumber: certData.certificateNumber,
          eventTitle: certData.eventTitle,
          holderName: AppData.name.trim().isNotEmpty ? AppData.name.trim() : null,
          holderSpecialty: certData.recipientSpecialty,
          creditType: certData.creditType,
          creditAmount: certData.creditAmount is num
              ? (certData.creditAmount as num).toDouble()
              : double.tryParse('${certData.creditAmount}'),
          downloadUrl: certData.downloadUrl,
          shareUrl: null,
          verificationUrl: certData.verificationUrl,
          qrCodeUrl: null,
          isValid: certData.isValid,
          accreditationBody: certData.accreditationBody,
          providerName: certData.providerName,
        );
      }
      emit(CmeCertificateShareLoadedState());
    } catch (e) {
      emit(CmeCertificateShareErrorState(e.toString()));
    }
  }

  Future<void> _onShare(
    CmeShareCertificateEvent event,
    Emitter<CmeCertificateShareState> emit,
  ) async {
    if (certificate == null) {
      emit(CmeCertificateShareErrorState('Certificate not loaded'));
      return;
    }
    try {
      String? shareUrl;
      String? verificationUrl;
      try {
        final response = await CmeNodeApiService.shareCertificate(event.certificateId);
        final data = response['data'] as Map<String, dynamic>?;
        shareUrl = response['share_url'] as String? ??
            data?['share_url'] as String?;
        verificationUrl = response['verification_url'] as String? ??
            data?['verification_url'] as String?;
      } catch (_) {
        shareUrl = CmeCertificateData.webViewUrl(event.certificateId);
        verificationUrl = shareUrl;
      }

      final current = certificate!;
      certificate = CmeShareableCertificate(
        id: current.id,
        certificateNumber: current.certificateNumber,
        eventTitle: current.eventTitle,
        holderName: current.holderName,
        holderSpecialty: current.holderSpecialty,
        creditType: current.creditType,
        creditAmount: current.creditAmount,
        issueDate: current.issueDate,
        expiryDate: current.expiryDate,
        downloadUrl: current.downloadUrl,
        shareUrl: shareUrl ?? current.shareUrl,
        verificationUrl: verificationUrl ?? current.verificationUrl,
        qrCodeUrl: current.qrCodeUrl,
        isValid: current.isValid,
        accreditationBody: current.accreditationBody,
        providerName: current.providerName,
      );
      emit(CmeCertificateShareSharedState());
      emit(CmeCertificateShareLoadedState());
    } catch (e) {
      emit(CmeCertificateShareErrorState('$e'));
      emit(CmeCertificateShareLoadedState());
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
